# 🚀 QDeploy - PowerShell Deployment Framework

[![GitHub license](https://img.shields.io/github/license/AutomateSilent/QDeploy)](https://github.com/AutomateSilent/QDeploy/blob/main/LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/AutomateSilent/QDeploy)](https://github.com/AutomateSilent/QDeploy/releases)

## 📋 Overview

QDeploy is a lightweight framework for creating structured, reliable PowerShell deployment scripts. It provides a consistent template structure with built-in logging, helper functions, and best practices for software deployment.

## ✨ Features

- 📊 Standardized logging system with levels and timestamps
- 🔄 Unified Install/Uninstall workflow
- 🧩 Modular architecture with helper functions
- 📁 Organized folder structure for deployment resources
- 💻 One-line installation command
- 🔌 Compatible with Intune, SCCM, and other deployment tools

## 🔧 Installation

Install QDeploy with a single PowerShell command (run as administrator):

```powershell
irm https://raw.githubusercontent.com/AutomateSilent/QDeploy/main/Copy-QDeploy.ps1 | iex
```

This will:
1. Download the latest QDeploy release
2. Launch a UI to select your installation directory (default: C:\QDeploy)
3. Extract all necessary files

## 📂 Project Structure

```
QDeploy/
├── QDeploy.ps1               # Main script
├── *.exe, *.msi              # Executable/installer files (recommended for organization)
├── Helpers/                  # Helper functions directory
│   ├── Initialize-Deployment.ps1    # Core initialization
│   ├── Write-DeploymentLog.ps1      # Logging function
│   └── [Your custom helpers]        # Add your own
└── Support/                  # Resources directory
    └── [Your deployment files]      # Config files, resources, etc.
```

## 🚀 Quick Start

1. After installation, navigate to the QDeploy directory
2. Customize the QDeploy.ps1 file with your deployment name:
   ```powershell
   $AppName = "YourApplication"
   ```
3. Implement your deployment logic in the Install-Script and Uninstall-Script functions
4. Run the script:
   ```powershell
   # For installation
   .\QDeploy.ps1
   
   # For uninstallation
   .\QDeploy.ps1 -Uninstall
   ```

## 📝 Core Functions

### Initialize-Deployment
Sets up the deployment environment:
```powershell
Initialize-Deployment [-AppName <string>] [-CustomLogPath <string>]
```

### Write-DeploymentLog
Handles standardized logging:
```powershell
Write-DeploymentLog [-Message] <string> [-Level {Info | Warning | Error}]
```

## 📋 Example Usage

### Basic Deployment Script
```powershell
# Inside QDeploy.ps1, after importing helpers:

function Install-Script {
    try {
        Write-DeploymentLog "Starting installation of $AppName"
        
        # Install an MSI package
        $msiPath = Join-Path $scriptPath "MyApplication.msi"
        Install-Software -FilePath $msiPath -Arguments "/quiet"
        
        # Copy a configuration file
        $configSource = Join-Path $SupportDir "config.xml"
        $configDest = "C:\Program Files\MyApplication\config.xml"
        Copy-Item -Path $configSource -Destination $configDest -Force
        
        Write-DeploymentLog "Installation completed successfully"
        return $true
    }
    catch {
        Write-DeploymentLog "Installation failed: $_" -Level Error
        return $false
    }
}
```

### Custom Helper Function
```powershell
# In Helpers/Install-ConfigFile.ps1
function Install-ConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigName
    )
    
    $source = Join-Path $SupportDir "$ConfigName.xml"
    $destination = "C:\Program Files\MyApplication\$ConfigName.xml"
    
    Write-DeploymentLog "Installing configuration: $ConfigName"
    Copy-Item -Path $source -Destination $destination -Force
}
```

## 🔄 Integration with Deployment Tools

### Intune
QDeploy scripts work perfectly with Intune deployments:
1. Package QDeploy with your application files
2. Create an Intune Win32 app using the Intune Content Prep Tool
3. Set the install command: `powershell.exe -ExecutionPolicy Bypass -File QDeploy.ps1`
4. Set the uninstall command: `powershell.exe -ExecutionPolicy Bypass -File QDeploy.ps1 -Uninstall`

### SCCM/MECM
Deploy QDeploy scripts through Configuration Manager:
1. Create an application in SCCM
2. Add a deployment type with:
   - Content location: Your QDeploy folder
   - Installation program: `powershell.exe -ExecutionPolicy Bypass -File QDeploy.ps1`
   - Uninstallation program: `powershell.exe -ExecutionPolicy Bypass -File QDeploy.ps1 -Uninstall`

## 📚 Documentation

For more advanced usage and examples, refer to the script comments and helper function documentation in the source code.

## 💼 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues or pull requests.

---

Built with ❤️ by [AutomateSilent](https://github.com/AutomateSilent)
