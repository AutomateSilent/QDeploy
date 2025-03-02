# Import Windows API functionality for wallpaper querying
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WallpaperApi {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(
        int uAction,
        int uParam,
        StringBuilder lpvParam,
        int fuWinIni
    );

    public const int SPI_GETDESKWALLPAPER = 0x0073;
    public const int MAX_PATH = 260;
}
"@

function Get-Wallpaper {
<#
.SYNOPSIS
    Retrieves the Windows desktop wallpaper configuration.

.DESCRIPTION
    Gets the current desktop wallpaper configuration (Picture, Slideshow, Windows Spotlight, or Solid Color)
    and returns the wallpaper path when applicable.

.EXAMPLE
    Get-Wallpaper

.OUTPUTS
    PSCustomObject with properties:
    - BackgroundType: "Picture", "Slideshow", "Windows Spotlight", "Solid Color", or "Unknown"
    - WallpaperPath: File path of the current wallpaper image (if applicable)
    - LastError: Error information if any

.NOTES
    Author: QDeploy
    Version: 1.0
    Date: February 24, 2025
    
    Requires user context to access personalization settings.
    Uses both registry queries and Windows API calls to determine wallpaper configuration.
#>    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    begin {
        # Initialize return object with default values
        $wallpaperInfo = [PSCustomObject]@{
            BackgroundType = "Unknown"
            WallpaperPath = $null
            LastError = $null
        }

        Write-Verbose "Initializing wallpaper settings query..."
    }

    process {
        try {
            Write-Verbose "Querying wallpaper settings..."
            
            # Define registry paths for different wallpaper-related settings
            $registryPaths = @{
                Wallpaper = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
                Desktop = "HKCU:\Control Panel\Desktop"
                ThemeSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes"
            }
            
            # Query registry for wallpaper and desktop settings
            $wallpaperSettings = Get-ItemProperty -Path $registryPaths.Wallpaper -ErrorAction Stop
            $desktopSettings = Get-ItemProperty -Path $registryPaths.Desktop -ErrorAction Stop
            
            Write-Verbose "Settings retrieved. Analyzing configuration..."
            Write-Verbose "Background Type Value: $($wallpaperSettings.BackgroundType)"
            Write-Verbose "Wallpaper Style: $($desktopSettings.WallpaperStyle)"
            Write-Verbose "Windows Style: $($desktopSettings.WallPaper)"

            # Get current wallpaper path
            $wallpaperPath = New-Object System.Text.StringBuilder([WallpaperApi]::MAX_PATH)
            $result = [WallpaperApi]::SystemParametersInfo(
                [WallpaperApi]::SPI_GETDESKWALLPAPER,
                [WallpaperApi]::MAX_PATH,
                $wallpaperPath,
                0
            )

            if ($result -ne 0) {
                $wallpaperInfo.WallpaperPath = $wallpaperPath.ToString().Trim()
            }

            # Enhanced background type detection with proper Picture detection
            $wallpaperInfo.BackgroundType = switch ($true) {
                # Solid Color - No wallpaper path and BackgroundType is 1
                { $wallpaperSettings.BackgroundType -eq 1 -or 
                  [string]::IsNullOrEmpty($wallpaperInfo.WallpaperPath) } {
                    Write-Verbose "Solid color background detected"
                    "Solid Color"
                    break
                }
                # Slideshow - BackgroundType is 2
                { $wallpaperSettings.BackgroundType -eq 2 } {
                    Write-Verbose "Slideshow is enabled"
                    "Slideshow"
                    break
                }
                # Windows Spotlight - BackgroundType is 3
                { $wallpaperSettings.BackgroundType -eq 3 } {
                    Write-Verbose "Windows Spotlight detected"
                    "Windows Spotlight"
                    break
                }
                # Picture - BackgroundType is 0 or path exists without other conditions
                { $wallpaperSettings.BackgroundType -eq 0 -or 
                  (-not [string]::IsNullOrEmpty($wallpaperInfo.WallpaperPath) -and 
                   $wallpaperSettings.BackgroundType -notin @(1,2,3)) } {
                    Write-Verbose "Static picture is configured"
                    "Picture"
                    break
                }
                default {
                    Write-Verbose "Unable to determine background type"
                    "Unknown"
                }
            }
        }
        catch {
            $errorMessage = "Failed to query wallpaper settings: $_"
            Write-Error $errorMessage
            $wallpaperInfo.LastError = $errorMessage
        }
    }

    end {
        Write-Verbose "Wallpaper settings query completed"
        return $wallpaperInfo
    }
}