<#
.SYNOPSIS
    Uninstalls MSI products using product GUID.

.DESCRIPTION
    Provides streamlined MSI product removal using msiexec. Handles GUID formatting
    and common installation states through appropriate exit code interpretation.

.PARAMETER ProductGuid
    The GUID of the MSI product to uninstall.

.PARAMETER Arguments
    Optional MSI uninstall arguments. Defaults to "/qn /norestart".

.EXAMPLE
    Remove-Msi -ProductGuid "{A35B56B0-B80C-40C3-ADB1-6658C594B7F8}"
    Uninstalls the specified MSI product silently.
#>
function Remove-Msi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true,
                   HelpMessage = "MSI Product GUID to uninstall")]
        [string]$ProductGuid,

        [Parameter(HelpMessage = "Additional MSI uninstall arguments")]
        [string]$Arguments = "/qn /norestart"
    )
    
    process {
        # Ensure GUID format consistency
        $ProductGuid = $ProductGuid.Trim()
        if (-not $ProductGuid.StartsWith('{')) { $ProductGuid = "{$ProductGuid" }
        if (-not $ProductGuid.EndsWith('}')) { $ProductGuid = "$ProductGuid}" }

        Write-DeploymentLog "Uninstalling MSI: $ProductGuid"
        
        $process = Start-Process "msiexec.exe" -ArgumentList "/x $ProductGuid $Arguments" -Wait -PassThru -NoNewWindow
        
        # Handle common MSI exit codes appropriately
        switch ($process.ExitCode) {
            0 { 
                Write-DeploymentLog "MSI uninstall completed successfully" -Level Info
            }
            1605 {
                # Product not found - often means already uninstalled
                Write-DeploymentLog "Product already uninstalled or not found" -Level Info
            }
            1618 {
                Write-DeploymentLog "Another installation is in progress (Code: 1618)" -Level Error
            }
            default {
                Write-DeploymentLog "MSI uninstall completed with exit code: $($process.ExitCode)" -Level Error
            }
        }
    }
}