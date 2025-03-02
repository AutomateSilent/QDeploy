function Get-LockWallpaper {
<#
.SYNOPSIS
    Retrieves the Windows lock screen wallpaper configuration.

.DESCRIPTION
    Gets the current lock screen configuration (Picture, Slideshow, or Windows Spotlight) 
    and returns the wallpaper path when applicable.

.EXAMPLE
    Get-LockWallpaper

.OUTPUTS
    PSCustomObject with properties:
    - BackgroundType: "Picture", "Slideshow", "Windows Spotlight", or "Unknown"
    - WallpaperPath: File path (only for "Picture" type)
    - LastError: Error information if any

.NOTES
    Author: QDeploy
    Version: 1.0
    Date: February 24, 2025

    Run this function in user context, not as administrator or system account.
    For deployment, run as the target user to get their specific settings.
#>    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    begin {
        # Initialize return object with default values
        $lockWallpaperInfo = [PSCustomObject]@{
            BackgroundType = "Unknown"
            WallpaperPath = $null
            LastError = $null
        }

        Write-Verbose "Initializing lock screen background query..."
    }

    process {
        try {
            Write-Verbose "Querying lock screen background settings..."
            
            # Define registry paths for lock screen settings
            $lockScreenPaths = @{
                Main = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen"
                ContentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            }
            
            # Query registry for lock screen and content delivery settings
            $lockSettings = Get-ItemProperty -Path $lockScreenPaths.Main -ErrorAction Stop
            $contentSettings = Get-ItemProperty -Path $lockScreenPaths.ContentDelivery -ErrorAction Stop
            
            Write-Verbose "Settings retrieved. Analyzing configuration..."
            Write-Verbose "Spotlight Status: $($contentSettings.RotatingLockScreenEnabled)"
            Write-Verbose "Slideshow Status: $($lockSettings.SlideshowEnabled)"

            # Determine background type using a hierarchical check
            $lockWallpaperInfo.BackgroundType = switch ($true) {
                # Check Windows Spotlight first - requires checking ContentDeliveryManager
                { $contentSettings.RotatingLockScreenEnabled -eq 1 } {
                    Write-Verbose "Windows Spotlight is enabled via Content Delivery Manager"
                    "Windows Spotlight"
                    break
                }
                # Then check Slideshow
                { $lockSettings.SlideshowEnabled -eq 1 } {
                    Write-Verbose "Slideshow is enabled"
                    "Slideshow"
                    break
                }
                # Default to Picture if neither Spotlight nor Slideshow is enabled
                default {
                    Write-Verbose "Static picture is configured"
                    "Picture"
                }
            }

            # Get wallpaper path for Picture type
            if ($lockWallpaperInfo.BackgroundType -eq "Picture") {
                $lockWallpaperInfo.WallpaperPath = $lockSettings.WallPaper
                Write-Verbose "Wallpaper path: $($lockWallpaperInfo.WallpaperPath)"
            }
        }
        catch {
            $errorMessage = "Failed to query lock screen background settings: $_"
            Write-Error $errorMessage
            $lockWallpaperInfo.LastError = $errorMessage
        }
    }

    end {
        Write-Verbose "Lock screen background query completed"
        return $lockWallpaperInfo
    }
}

