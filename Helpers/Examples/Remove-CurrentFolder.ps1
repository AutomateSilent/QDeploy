function Remove-CurrentFolder {
    <#
    .SYNOPSIS
        Removes the current directory and all its contents using a temporary cleanup script.
    
    .DESCRIPTION
        Creates a temporary cleanup script in Windows\Temp to forcefully remove the current directory.
        Ensures reliable deletion even when the script is located in the target directory.
    
    .EXAMPLE
        Remove-CurrentFolder
        Removes the current working directory and all its contents.
    
    .NOTES
        Author: AutomateSilent
        Version: 1.0.0
        Requires: PowerShell 5.1 or later
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        # Verify running with administrative privileges
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            throw "This function requires administrative privileges. Please run PowerShell as Administrator."
        }
    }

    process {
        try {
            # Get current directory path and verify it exists
            $currentPath = (Get-Location).Path
            if (-not (Test-Path -Path $currentPath -PathType Container)) {
                throw "The current path does not exist or is not accessible: $currentPath"
            }

            # Safety check for system directories
            $protectedPaths = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:USERPROFILE)
            if ($protectedPaths -contains $currentPath) {
                throw "Cannot delete protected system directory: $currentPath"
            }

            # Generate unique script name
            $scriptGuid = [System.Guid]::NewGuid().ToString("N")
            $tempScriptPath = Join-Path $env:windir "Temp\Remove-Folder-$scriptGuid.ps1"

            # Create cleanup script with retry logic
            $cleanupScript = @"
`$maxAttempts = 5
`$attempt = 0
`$targetPath = '$currentPath'
`$sleepSeconds = 2

do {
    try {
        Start-Sleep -Seconds `$sleepSeconds
        if (Test-Path -Path `$targetPath) {
            Remove-Item -Path `$targetPath -Recurse -Force -ErrorAction Stop
            break
        }
    }
    catch {
        `$attempt++
        `$sleepSeconds *= 2
        if (`$attempt -eq `$maxAttempts) {
            Write-Error "Failed to remove directory after `$maxAttempts attempts: `$_"
            exit 1
        }
    }
} while (`$attempt -lt `$maxAttempts)

# Self-cleanup
Remove-Item -Path '$tempScriptPath' -Force -ErrorAction SilentlyContinue
"@

            # Write cleanup script to temp directory
            $cleanupScript | Out-File -FilePath $tempScriptPath -Force -Encoding UTF8

            # Start cleanup process and change directory to allow deletion
            if ($PSCmdlet.ShouldProcess($currentPath, "Remove directory and contents")) {
                Write-Verbose "Initiating directory removal: $currentPath"
                Write-Verbose "Using cleanup script: $tempScriptPath"
                
                # Change to parent directory to release handles
                Set-Location -Path (Split-Path -Parent $currentPath)

                # Start cleanup process
                Start-Process -FilePath "powershell.exe" `
                    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScriptPath`"" `
                    -WindowStyle Hidden
                
                Write-Warning "Directory removal initiated. Please wait for completion."
            }
        }
        catch {
            Write-Error "Failed to initiate directory removal: $_"
            
            # Cleanup on failure
            if ($tempScriptPath -and (Test-Path $tempScriptPath)) {
                Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
            }
            throw
        }
    }
}