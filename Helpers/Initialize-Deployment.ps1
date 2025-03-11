function Initialize-Deployment {
 <#
    .SYNOPSIS
        Initializes the deployment environment with required paths and logging.

    .DESCRIPTION
        Sets up the deployment environment by establishing required paths,
        initializing logging, and validating the deployment structure.
        If no AppName is provided, generates a template name based on the script name.

    .PARAMETER AppName
        Optional. The name of the application being deployed.
        If not specified, generates a template name from the script.

    .PARAMETER CustomLogPath
        Optional. Specify a custom log directory path.
        Defaults to C:\Logs\Deployments.

    .EXAMPLE
        Initialize-Deployment
        Initializes deployment with auto-generated template name.

    .EXAMPLE
        Initialize-Deployment -AppName "MyCustomApp"
        Initializes deployment with specific application name.

    .EXAMPLE
        Initialize-Deployment -AppName "MyApp" -CustomLogPath "D:\Logs"
        Initializes deployment with custom log location.

    .OUTPUTS
        [bool] Returns $true if initialization succeeds, $false if it fails.

    .NOTES
        Author: QDeploy
        Version: 1.0
 #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$AppName,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomLogPath = "C:\Logs\QDeploy"
    )
    
    try {
        # Generate AppName if not provided
        if (-not $AppName) {
            $scriptName = [System.IO.Path]::GetFileNameWithoutExtension(
                (Get-Item (Join-Path $PSScriptRoot "..\QDeploy.ps1")).Name
            )
            $AppName = "QDeploy_$scriptName"
        }

        # Set global variables
        $global:SupportDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\Support"))
        $global:PublicDesktop = "$($Env:PUBLIC)\Desktop"
        $global:StartMenu = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
        
        # Set log file path
        $logName = $AppName
        if ($MyInvocation.ScriptName -and (Get-Variable -Name Uninstall -ErrorAction SilentlyContinue) -and $Uninstall) {
            $logName += "_Uninstall"
        }
        $global:LogFile = Join-Path $CustomLogPath "$($logName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        
        # Create directories
        $null = New-Item -ItemType Directory -Force -Path @(
            $global:SupportDir,
            (Split-Path -Parent $global:LogFile)
        )
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize deployment environment: $_"
        return $false
    }
}