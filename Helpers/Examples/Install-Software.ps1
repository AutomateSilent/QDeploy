<#
.SYNOPSIS
    Installs software from an EXE or MSI file.

.COMPONENT
    QuickSoft

.DESCRIPTION
    This function installs software from a specified EXE or MSI file. It automatically detects the file type and handles installation accordingly. For MSI files, it defaults to silent installation (/qn) unless custom arguments are provided. Supports logging to a file if specified.

    The function properly handles UNC paths, local paths, and paths with spaces, ensuring proper quoting and formatting for the installer.

.PARAMETER FilePath
    The full path to the EXE or MSI file to install.

.PARAMETER Arguments
    Optional arguments to pass to the installer. For MSI files, custom arguments override the default silent installation (/qn).

.PARAMETER Log
    Optional path to a log file. If provided, installation logs will be written to this file in addition to the console.

.EXAMPLE
    Install-Software -FilePath "C:\installer.exe"
    Installs the software from the specified EXE file.

.EXAMPLE
    Install-Software -FilePath "C:\package.msi" -Arguments "/qn /norestart"
    Installs the MSI package silently without restarting the system.

.EXAMPLE
    Install-Software -FilePath "C:\package.msi" -Log "C:\install.log"
    Installs the MSI package silently and logs the process to the specified file.

.EXAMPLE
    Install-Software -FilePath "\\server\share\package.msi"
    Installs the MSI package from a UNC path.

.OUTPUTS
    None. Writes installation progress and results to the console and optionally to a log file.

.NOTES
    Name: Install-Software
    Author: AutomateSilent
    Version: 1.0.4
    Last Updated: 2025-03-05
    Requires: Write-DeploymentLog function to be imported prior to execution
#>
function Install-Software {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "The full path to the EXE or MSI file to install."
        )]
        [string]$FilePath,

        [Parameter(
            Position = 1,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Optional arguments to pass to the installer."
        )]
        [string]$Arguments,

        [Parameter(
            Position = 2,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Optional path to a log file."
        )]
        [string]$Log,
        
        [Parameter(
            Position = 3,
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "If specified, does not wait for the installation to complete before returning."
        )]
        [switch]$NoWait
    )

    begin {
        # Legacy logging function kept for backward compatibility
        function Write-InstallLog {
            param($Message, $Level = 'Info')
            
            # Log entry will be captured by Write-DeploymentLog
            # This wrapper ensures compatibility with existing code
            if ($Level -eq 'ERROR') {
                Write-DeploymentLog -Message $Message -Level 'Error'
            }
            elseif ($Level -eq 'WARNING') {
                Write-DeploymentLog -Message $Message -Level 'Warning'
            }
            else {
                Write-DeploymentLog -Message $Message -Level 'Info'
            }
            
            # Legacy log file handling
            if ($Log) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] $Message"
                Add-Content -Path $Log -Value $logMessage
            }
        }

        # Function to clean and format UNC paths
        function Format-UNCPath {
            param([string]$Path)

            Write-Verbose "Original path: $Path"
    
            # If the path doesn't contain directory separators, check in standard locations
            if (($Path -notmatch '[\\/]') -and ($Path -ne '')) {
                # This is just a filename with no path - look in script directory first
                $scriptDir = Split-Path -Parent (Join-Path $PSScriptRoot "..")
                $possibleLocations = @(
                    (Join-Path $scriptDir $Path),                # Script root directory
                    (Join-Path $global:SupportDir $Path),        # Support directory
                    (Join-Path $PSScriptRoot $Path),             # Current directory
                    (Join-Path (Get-Location).Path $Path)        # Working directory
                )
        
                Write-Verbose "Looking for file in standard locations..."
                foreach ($location in $possibleLocations) {
                    Write-Verbose "Checking $location"
                    if (Test-Path -LiteralPath $location -PathType Leaf) {
                        Write-Verbose "File found at: $location"
                        return $location
                    }
                }
        
                # If still not found, return the original path for standard error handling
                Write-Verbose "File not found in standard locations, returning original path"
                return $Path
            }

            # Remove PowerShell provider prefix if present
            if ($Path -match "^Microsoft\.PowerShell\.Core\\FileSystem::(.+)$") {
                $Path = $Matches[1]
                Write-Verbose "Removed provider prefix. Path now: $Path"
            }

            # Handle UNC paths correctly by ensuring consistent format
            if ($Path -match "^\\\\") {
                # Ensure proper UNC path format (replace multiple consecutive backslashes)
                $Path = $Path -replace "^\\{2,}", "\\" # Ensure exactly two backslashes at start for UNC
                $Path = $Path -replace "\\{2,}", "\" # Replace any double backslashes in the rest of the path
                Write-Verbose "Normalized UNC path: $Path"
            }

            # Handle relative path components (..\) by converting to absolute path
            # This resolves path navigation elements like ..\
            try {
                # Only use GetFullPath if the path includes relative components or is relative
                if (($Path -match '\.\.|\.\\') -or -not [System.IO.Path]::IsPathRooted($Path)) {
                    # Use the script directory as base for relative paths
                    $scriptDir = Split-Path -Parent (Join-Path $PSScriptRoot "..")
                    $fullPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($scriptDir, $Path))
            
                    # Log resolved path for troubleshooting
                    Write-Verbose "Resolved relative path from: $Path"
                    Write-Verbose "                       to: $fullPath"
                    $Path = $fullPath
                }
            }
            catch {
                Write-Verbose "Unable to resolve relative path components: $_"
                # Continue with original path if resolution fails
            }

            return $Path
        }
        try {
            # Clean and normalize the file path
            $cleanPath = Format-UNCPath -Path $FilePath
            Write-Verbose "Normalized path: $cleanPath"
            
            # Verify the file actually exists and is accessible
            if (-not (Test-Path -LiteralPath $cleanPath -PathType Leaf -ErrorAction SilentlyContinue)) {
                $errorMsg = "File not found or not accessible: $cleanPath"
                Write-Error $errorMsg
                Write-DeploymentLog -Message $errorMsg -Level Error
                return
            }
            
            # Store the cleaned path for use in the process block
            $script:installerPath = $cleanPath
            Write-Verbose "Installer path set to: $script:installerPath"
            
            Write-Verbose "Initializing installation process for $script:installerPath"
            Write-DeploymentLog -Message "Initializing installation process for $script:installerPath" -Level Info
            
            # Log asynchronous operation if NoWait is specified
            if ($NoWait) {
                Write-Verbose "NoWait parameter specified - installation will run asynchronously"
                Write-DeploymentLog -Message "Asynchronous installation mode enabled" -Level Info
            }
        }
        catch {
            Write-Error "Initialization failed: $_"
            Write-DeploymentLog -Message "Initialization failed: $_" -Level Error
            return
        }
    }

    process {
        try {
            # Get file extension
            $extension = [System.IO.Path]::GetExtension($script:installerPath).TrimStart('.').ToLower()
            
            # Validate file type
            if ($extension -notin 'exe', 'msi') {
                $errorMsg = "Unsupported file type '$extension'. Only EXE and MSI are supported."
                Write-Error $errorMsg
                Write-DeploymentLog -Message $errorMsg -Level Error
                return
            }

            Write-DeploymentLog -Message "Starting installation: $script:installerPath" -Level Info
            
            # Process based on file type
            if ($extension -eq 'exe') {
                # Handle EXE installations
                $params = @{
                    FilePath = $script:installerPath
                    Wait = (-not $NoWait)  # Only wait if NoWait is not specified
                    PassThru = $true
                    Verb = 'RunAs'  # Ensures elevated privileges
                }
                
                if ($Arguments) { 
                    $params.ArgumentList = $Arguments 
                    Write-DeploymentLog -Message "Using custom EXE arguments: $Arguments" -Level Info
                }
                
                Write-Verbose "Starting EXE process with params: $($params | ConvertTo-Json -Compress)"
                $process = Start-Process @params
            }
            else {
                # Handle MSI installations
                # The path must be properly quoted, especially for paths with spaces
                $quotedPath = "`"$script:installerPath`""
                Write-DeploymentLog -Message "Using installation path: $quotedPath" -Level Info
                
                # Build MSI command arguments
                if ($Arguments) {
                    $msiArgs = "/i $quotedPath $Arguments"
                    Write-DeploymentLog -Message "Using custom MSI arguments: $Arguments" -Level Info
                }
                else {
                    $msiArgs = "/i $quotedPath /qn"
                    Write-DeploymentLog -Message "Using default MSI arguments: /qn" -Level Info
                }
                
                # Log full command for troubleshooting
                $fullCommand = "msiexec.exe $msiArgs"
                Write-Verbose "Full installation command: $fullCommand"
                
                # Execute MSI installation process
                Write-Verbose "Starting MSI installation process"
                if ($NoWait) {
                    # Start without waiting
                    $process = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList $msiArgs -PassThru -Verb RunAs
                    Write-DeploymentLog -Message "MSI installation started asynchronously (PID: $($process.Id))" -Level Info
                } else {
                    # Start and wait for completion
                    $process = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -Verb RunAs
                }
            }

            # Process the exit code only if we waited for completion
            if (-not $NoWait) {
                if ($process.ExitCode -eq 0) {
                    Write-DeploymentLog -Message "Installation completed successfully with exit code: $($process.ExitCode)" -Level Info
                }
                elseif ($process.ExitCode -eq 3010) {
                    Write-DeploymentLog -Message "Installation completed with exit code: $($process.ExitCode). System restart required." -Level Warning
                }
                else {
                    Write-DeploymentLog -Message "Installation failed with exit code: $($process.ExitCode)" -Level Error
                    
                    # Provide more detailed error information for common MSI exit codes
                    switch ($process.ExitCode) {
                        1619 {
                            Write-DeploymentLog -Message "Error 1619: This installation package could not be opened. Verify that the package exists and that you can access it." -Level Error
                            Write-Verbose "Path used: $script:installerPath"
                            Write-Verbose "Check if the file exists: $(Test-Path -LiteralPath $script:installerPath -PathType Leaf)"
                        }
                        1603 {
                            Write-DeploymentLog -Message "Error 1603: A fatal error occurred during installation. Check the MSI log for more details." -Level Error
                        }
                        1612 {
                            Write-DeploymentLog -Message "Error 1612: The installation source for this product is not available. Verify the source exists and that you can access it." -Level Error
                        }
                        1638 {
                            Write-DeploymentLog -Message "Error 1638: Another version of this product is already installed. Installation cannot continue." -Level Error
                        }
                    }
                }
            } else {
                # For asynchronous operations, we can only report that it was started
                Write-DeploymentLog -Message "Installation process started with PID: $($process.Id)" -Level Info
                
                # Return the process object for potential monitoring
                return $process
            }
        }
        catch {
            Write-Error "Installation error: $($_.Exception.Message)"
            Write-DeploymentLog -Message "Installation error: $($_.Exception.Message)" -Level Error
        }
    }

    end {
        if ($NoWait) {
            Write-Verbose "Installation process initiated asynchronously for $script:installerPath"
            Write-DeploymentLog -Message "Installation process initiated asynchronously for $script:installerPath" -Level Info
        } else {
            Write-Verbose "Installation process completed for $script:installerPath"
            Write-DeploymentLog -Message "Installation process completed for $script:installerPath" -Level Info
        }
    }
}