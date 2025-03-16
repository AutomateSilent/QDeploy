# 🚀 QDeploy - PowerShell Deployment Framework

[![GitHub license](https://img.shields.io/github/license/AutomateSilent/QDeploy)](https://github.com/AutomateSilent/QDeploy/blob/main/LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/AutomateSilent/QDeploy)](https://github.com/AutomateSilent/QDeploy/releases)

## 💡 What is QDeploy?

QDeploy is a flexible PowerShell framework that provides a structured foundation for **any type of deployment, configuration, or automation task** in Windows environments. With its organized template structure, robust logging, and error handling, QDeploy helps you create professional and reliable deployments for a wide range of everyday IT operations.

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
irm https://raw.githubusercontent.com/AutomateSilent/QDeploy/main/Copy-QDeploy.ps1 | iex -Verbose
```

![QDeploy Installer](https://github.com/user-attachments/assets/46111784-1688-4e5f-8c8f-cbed7a928be8)

*QDeploy will be installed to the specified location. If an Application Name is provided, the folder will be named 'QDeploy - [AppName]' and the $AppName variable in QDeploy.ps1 will be set to this value.*

This will:
1. Download the latest QDeploy release
2. Launch a UI to select your installation directory (default: C:\QDeploy)
3. Extract all necessary files

## 🚀 Quick Start

1. Implement your deployment logic in the Install-Script and Uninstall-Script functions
2. Open powershell as admin and Run the script:
   ```powershell
   # For installation
   .\QDeploy.ps1 -Verbose
   
   # For uninstallation
   .\QDeploy.ps1 -Uninstall -Verbose
   ```
   
## 📂 Project Structure

```
QDeploy/
├── QDeploy.ps1               # Main script
├── *.exe, *.msi              # Executable/installer files (recommended for organization)
├── Helpers/                  # Helper functions directory
│   ├── Initialize-Deployment.ps1    # Core initialization
│   ├── Write-DeploymentLog.ps1      # Logging function
│   └── [Your custom helpers]        # Add your own (Useful examples are provided)
└── Support/                  # Resources directory
    └── [Your deployment files]      # Config files, resources, etc.
```

## 📝 Core Functions
### Script Structure & Initialization
![Main Script Structure](https://github.com/user-attachments/assets/effc8b2c-4e5d-4636-a92e-8c2d0f63fb0e)

*The framework automatically imports helpers and initializes the environment, giving you a clean foundation to build upon while handling the tedious setup work for you.*

### Implementation Examples
![Installation Function](https://github.com/user-attachments/assets/3917a37d-6735-4215-b833-f7472a6ad96c)

*The Install-Script function demonstrates QDeploy's organized approach to deployment tasks with proper error handling and logging. Create your implementation within this structure for consistent, reliable scripts.*

![Uninstallation Function](https://github.com/user-attachments/assets/0c06a763-6bbd-4504-8745-5b52d01cb13b)

*The Uninstall-Script function shows how QDeploy handles removal operations with the same level of organization and error handling, making your scripts professional and complete.*

### Execution Logic
![Execution Flow](https://github.com/user-attachments/assets/d5483e68-16da-450a-ada4-0f7fde5f0200)

*QDeploy's main execution block handles parameter selection and provides proper exit codes, ensuring your script integrates well with other systems and deployment tools.*

## Key Features

- **Modular Design** - Organize your code with auto-imported helper functions
- **Robust Logging** - Color-coded console output and detailed log files
- **Error Handling** - Comprehensive try/catch blocks with appropriate exit codes
- **Dual-Mode Support** - Install and uninstall operations in a single script
- **Support Directory** - Organized storage for deployment resources


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
