<#
.SYNOPSIS
    Installs software from an EXE or MSI file.

.COMPONENT
    QuickSoft

.DESCRIPTION
    This function installs software from a specified EXE or MSI file. It automatically detects the file type and handles installation accordingly. For MSI files, it defaults to silent installation (/qn) unless custom arguments are provided. Supports logging to a file if specified.

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

.OUTPUTS
    None. Writes installation progress and results to the console and optionally to a log file.

.NOTES
    Name: Install-Software
    Author: AutomateSilent
    Version: 1.0.2
    Last Updated: 2025-03-04
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
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
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
        [string]$Log
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

        try {
            # Convert to absolute path to avoid any path-related issues
            $FilePath = (Resolve-Path $FilePath).Path
            Write-Verbose "Initializing installation process for $FilePath"
            Write-DeploymentLog -Message "Initializing installation process for $FilePath" -Level Info
        }
        catch {
            Write-Error "Initialization failed: $_"
            Write-DeploymentLog -Message "Initialization failed: $_" -Level Error
            return
        }
    }

    process {
        try {
            $extension = [System.IO.Path]::GetExtension($FilePath).TrimStart('.').ToLower()
            if ($extension -notin 'exe', 'msi') {
                Write-DeploymentLog -Message "Unsupported file type '$extension'. Only EXE and MSI are supported." -Level Error
                return
            }

            Write-DeploymentLog -Message "Starting installation: $FilePath" -Level Info

            if ($extension -eq 'exe') {
                $params = @{
                    FilePath = $FilePath
                    Wait = $true
                    PassThru = $true
                    Verb = 'RunAs'  # Ensures elevated privileges
                }
                if ($Arguments) { 
                    $params.ArgumentList = $Arguments 
                    Write-DeploymentLog -Message "Using custom EXE arguments: $Arguments" -Level Info
                }
                $process = Start-Process @params
            }
            else {
                # Default MSI arguments (silent install)
                $msiArgs = if ($Arguments) {
                    Write-DeploymentLog -Message "Using custom MSI arguments: $Arguments" -Level Info
                    "/i `"$FilePath`" $Arguments"
                }
                else {
                    Write-DeploymentLog -Message "Using default MSI arguments: /i `"$FilePath`" /qn" -Level Info
                    "/i `"$FilePath`" /qn"
                }
                
                # Use full path to msiexec and run with proper verb
                $process = Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -Verb RunAs
            }

            # Check exit code and log appropriate message
            if ($process.ExitCode -eq 0) {
                Write-DeploymentLog -Message "Installation completed successfully with exit code: $($process.ExitCode)" -Level Info
            }
            elseif ($process.ExitCode -eq 3010) {
                Write-DeploymentLog -Message "Installation completed with exit code: $($process.ExitCode). System restart required." -Level Warning
            }
            else {
                Write-DeploymentLog -Message "Installation failed with exit code: $($process.ExitCode)" -Level Error
            }
        }
        catch {
            Write-DeploymentLog -Message "Installation error: $($_.Exception.Message)" -Level Error
        }
    }

    end {
        Write-Verbose "Installation process completed for $FilePath"
        Write-DeploymentLog -Message "Installation process completed for $FilePath" -Level Info
    }
}