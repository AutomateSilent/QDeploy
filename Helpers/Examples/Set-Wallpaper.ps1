function Set-Wallpaper {
<#
.SYNOPSIS
    Sets the Windows desktop wallpaper and/or lock screen background image.

.DESCRIPTION
    Sets the desktop wallpaper, lock screen image, or both using a specified image file.
    Supports JPG, JPEG, PNG, BMP, and TIFF formats (TIFF is automatically converted).

.PARAMETER Path
    Path to the wallpaper image file.

.PARAMETER LockScreen
    Switch to set the image as lock screen background only.

.PARAMETER All
    Switch to set the image as both desktop wallpaper and lock screen background.

.EXAMPLE
    Set-Wallpaper -Path "C:\Pictures\wallpaper.jpg"
    Sets the specified image as the desktop wallpaper.

.EXAMPLE
    Set-Wallpaper -Path "C:\Pictures\background.png" -LockScreen
    Sets the specified image as the lock screen background.

.EXAMPLE
    Set-Wallpaper -Path "C:\Pictures\image.jpg" -All
    Sets the specified image as both desktop wallpaper and lock screen background.

.NOTES
    Author: QDeploy
    Version: 1.0
    Date: February 24, 2025

    Requires Windows 10 or later for lock screen functionality.
    Uses Windows API for desktop wallpaper and WinRT API for lock screen.
#>    
    [CmdletBinding(DefaultParameterSetName = 'Desktop')]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = "Path to the wallpaper image file",
            ParameterSetName = 'Desktop')]
        [Parameter(ParameterSetName = 'LockScreen')]
        [Parameter(ParameterSetName = 'Both')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-Not (Test-Path $_)) {
                throw "File not found: $_"
            }
            $validExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif')
            if (-Not ($validExtensions -contains [System.IO.Path]::GetExtension($_).ToLower())) {
                throw "Invalid file format. Supported formats: $($validExtensions -join ', ')"
            }
            return $true
        })]
        [string]$Path,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'LockScreen')]
        [switch]$LockScreen,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Both')]
        [switch]$All
    )

    begin {
        $ErrorActionPreference = 'Stop'
        
        # Load required Windows APIs
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Wallpaper {
                [DllImport("user32.dll", CharSet = CharSet.Auto)]
                public static extern int SystemParametersInfo(
                    int uAction,
                    int uParam,
                    string lpvParam,
                    int fuWinIni);
            }
"@

        # Load Windows.System.UserProfile namespace for lock screen
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

        # Function to handle WinRT async operations
        Function Await($WinRtTask, $ResultType) {
            $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
            $netTask = $asTask.Invoke($null, @($WinRtTask))
            $netTask.Wait(-1) | Out-Null
            $netTask.Result
        }

        # Load required WinRT assemblies
        [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime] | Out-Null
        [Windows.Storage.Streams.RandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime] | Out-Null
        [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType=WindowsRuntime] | Out-Null
    }

    process {
        try {
            $Path = Resolve-Path $Path
            Write-Verbose "Processing image: $Path"

            # Check if image is TIFF and convert if necessary
            $extension = [System.IO.Path]::GetExtension($Path).ToLower()
            $tempPath = $null

            if ($extension -in @('.tiff', '.tif')) {
                Write-Verbose "Converting TIFF image to PNG format"
                $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName() + '.png')
                
                try {
                    $image = [System.Drawing.Image]::FromFile($Path)
                    $image.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
                    $image.Dispose()
                    $Path = $tempPath
                    Write-Verbose "TIFF conversion successful: $tempPath"
                }
                catch {
                    throw "Failed to convert TIFF image: $_"
                }
            }

            # Function to set desktop wallpaper
            function Set-DesktopWallpaper {
                param([string]$WallpaperPath)
                
                $SPI_SETDESKWALLPAPER = 0x0014
                $SPIF_UPDATEINIFILE = 0x01
                $SPIF_SENDCHANGE = 0x02

                $result = [Wallpaper]::SystemParametersInfo(
                    $SPI_SETDESKWALLPAPER,
                    0,
                    $WallpaperPath,
                    $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE
                )

                if ($result -eq 0) {
                    throw "Failed to set desktop wallpaper"
                }
                
                Write-Verbose "Desktop wallpaper set successfully"
            }

            # Function to set lock screen wallpaper using WinRT API
            function Set-LockScreenWallpaper {
                param([string]$WallpaperPath)
    
                try {
                    $file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($WallpaperPath)) ([Windows.Storage.StorageFile])
                    $stream = Await ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        
                    $ErrorActionPreference = 'SilentlyContinue'
                    $setImageTask = [Windows.System.UserProfile.LockScreen]::SetImageStreamAsync($stream)
                    Await ($setImageTask) ([void]) 2>$null
                    $ErrorActionPreference = 'Stop'
        
                    $stream.Dispose()
                    Write-Verbose "Lock screen wallpaper set successfully"
                }
                catch {
                    # Suppress only the specific void type argument error
                    if ($_.Exception.Message -notlike "*type 'System.Void' may not be used as a type argument*") {
                        throw "Failed to set lock screen wallpaper: $_"
                    }
                    Write-Verbose "Lock screen wallpaper operation completed with expected void type message"
                }
            }

            # Determine which operations to perform based on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                'Both' {
                    Write-Verbose "Setting wallpaper for both desktop and lock screen"
                    Set-DesktopWallpaper -WallpaperPath $Path
                    Set-LockScreenWallpaper -WallpaperPath $Path
                }
                'LockScreen' {
                    Write-Verbose "Setting lock screen wallpaper only"
                    Set-LockScreenWallpaper -WallpaperPath $Path
                }
                'Desktop' {
                    Write-Verbose "Setting desktop wallpaper only"
                    Set-DesktopWallpaper -WallpaperPath $Path
                }
            }
        }
        catch {
            Write-Error "Failed to set wallpaper: $_"
            return
        }
        finally {
            # Cleanup temporary files if they exist
            if ($tempPath -and (Test-Path $tempPath)) {
                Remove-Item -Path $tempPath -Force
                Write-Verbose "Cleaned up temporary conversion file"
            }
        }
    }

    end {
        Write-Verbose "Wallpaper operation completed"
    }
}