function Write-DeploymentLog {
    <#
    .SYNOPSIS
        Writes formatted log entries for deployment operations with timestamp and severity.

    .DESCRIPTION
        Provides standardized logging functionality for deployment scripts with consistent
        formatting, timestamp inclusion, and severity level indication. Supports both
        file logging and console output with appropriate color-coding based on message severity.

    .PARAMETER Message
        The message text to be logged.

    .PARAMETER Level
        The severity level of the log message. Valid values are:
        - Info: Standard informational messages (default)
        - Warning: Warning messages that require attention
        - Error: Error messages indicating failures

    .PARAMETER NoConsole
        If specified, suppresses output to the console. Messages will only be written to the log file.

    .EXAMPLE
        Write-DeploymentLog "Starting application installation"
        Logs an informational message with timestamp.

    .EXAMPLE
        Write-DeploymentLog "Configuration file not found" -Level Warning
        Logs a warning message with yellow console output.

    .EXAMPLE
        Write-DeploymentLog "Installation failed" -Level Error -NoConsole
        Logs an error message to file only, without console output.

    .NOTES
        Author: QDeploy
        Version: 1.0
        Created: 2025-02-14
        Requires the global $LogFile variable to be initialized through Initialize-Deployment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = "The message to be logged"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "The severity level of the message"
        )]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',
        
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Suppress console output"
        )]
        [switch]$NoConsole
    )
    
    begin {
        # Validate log file initialization
        if (-not $global:LogFile) {
            throw "Log file path not initialized. Ensure Initialize-Deployment has been called."
        }
        
        # Ensure log directory exists
        $logDir = Split-Path -Parent $global:LogFile
        if (-not (Test-Path $logDir)) {
            $null = New-Item -ItemType Directory -Path $logDir -Force
            Write-Verbose "Created log directory: $logDir"
        }
    }
    
    process {
        try {
            # Generate timestamp and format message
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] [$Level] $Message"
            
            # Write to log file
            Add-Content -Path $global:LogFile -Value $logMessage -ErrorAction Stop
            Write-Verbose "Successfully wrote to log file: $global:LogFile"
            
            # Write to console if not suppressed
            if (-not $NoConsole) {
                switch ($Level) {
                    'Error' {
                        Write-Host $logMessage -ForegroundColor Red
                        # Also write to error stream for proper error handling
                        $PSCmdlet.WriteError(
                            (New-Object System.Management.Automation.ErrorRecord(
                                $Message,
                                'DeploymentError',
                                [System.Management.Automation.ErrorCategory]::OperationStopped,
                                $null
                            ))
                        )
                    }
                    'Warning' {
                        Write-Host $logMessage -ForegroundColor Yellow
                        Write-Warning $Message
                    }
                    default {
                        Write-Host $logMessage
                    }
                }
            }
        }
        catch {
            $errorMessage = "Failed to write log message: $_"
            Write-Error $errorMessage
            throw $errorMessage
        }
    }
}