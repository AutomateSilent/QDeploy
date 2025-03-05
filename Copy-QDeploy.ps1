#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs QDeploy framework to your system with a graphical interface.

.DESCRIPTION
    Downloads and extracts the QDeploy framework to a specified location.
    Provides a WPF-based UI for selecting the installation directory.
    Default location is C:\QDeploy if no custom path is selected.
    Optional AppName parameter allows customizing the deployment folder name
    and application name in the extracted QDeploy.ps1 script.

.PARAMETER Verbose
    Provides detailed information about script execution progress.

.EXAMPLE
    irm https://raw.githubusercontent.com/AutomateSilent/QDeploy/main/Copy-QDeploy.ps1 | iex
    Downloads and runs the installer with the graphical interface.

.EXAMPLE
    irm https://raw.githubusercontent.com/AutomateSilent/QDeploy/main/Copy-QDeploy.ps1 | iex -Verbose
    Downloads and runs the installer with detailed verbose logging.

.NOTES
    Author: AutomateSilent
    Version: 1.2
    Project URL: https://github.com/AutomateSilent/QDeploy
#>

[CmdletBinding()]
param()

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Create a temporary directory to download and extract the zip file
$tempDir = Join-Path $env:TEMP "QDeploy_$(Get-Random)"
Write-Verbose "Creating temporary directory: $tempDir"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download the latest release of QDeploy
$releaseUrl = "https://github.com/AutomateSilent/QDeploy/releases/latest/download/QDeploy.zip"
$zipFile = Join-Path $tempDir "QDeploy.zip"
Write-Verbose "Will download QDeploy from: $releaseUrl"
Write-Verbose "Zip will be saved to: $zipFile"

try {
    # Create and show a splash screen while downloading
    [xml]$splashXaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="QDeploy Installer" 
    Height="80" 
    Width="350"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    WindowStartupLocation="CenterScreen">
    
    <Border CornerRadius="10" Background="#FF1A1A1A" BorderBrush="#FF7B2FBE" BorderThickness="1">
        <Grid>
            <TextBlock Text="Downloading QDeploy, please wait..." 
                    Foreground="White" 
                    FontWeight="Bold"
                    FontSize="16"
                    HorizontalAlignment="Center" 
                    VerticalAlignment="Center" />
        </Grid>
    </Border>
</Window>
"@

    Write-Verbose "Creating splash screen for download progress"
    $reader = New-Object System.Xml.XmlNodeReader $splashXaml
    $splashWindow = [Windows.Markup.XamlReader]::Load($reader)
    $splashWindow.Show()

    # Download the release
    Write-Verbose "Beginning download of QDeploy package"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($releaseUrl, $zipFile)
    Write-Verbose "Download completed successfully"
    
    # Close splash screen
    $splashWindow.Close()
    Write-Verbose "Closed splash screen"

    # Create and show the main installer window
    [xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="QDeploy Installer" 
    Height="380" 
    Width="550"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen">
    
    <Window.Resources>
        <Style x:Key="ButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#FF7B2FBE"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4" BorderThickness="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FFa44BDE"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#FF5B1F8E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#FF1A1A1A" Offset="0"/>
                <GradientStop Color="#FF2A2A35" Offset="1"/>
            </LinearGradientBrush>
        </Grid.Background>
        
        <Grid.RowDefinitions>
            <RowDefinition Height="70"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Background="#FF1A1A1A" Grid.Row="0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="QDeploy" 
                       FontSize="28" 
                       Foreground="White" 
                       FontWeight="Bold" 
                       VerticalAlignment="Center"
                       Margin="20,0,0,0" Grid.Column="0">
                    <TextBlock.Effect>
                        <DropShadowEffect ShadowDepth="2" Color="#FF7B2FBE" Opacity="0.6" BlurRadius="15"/>
                    </TextBlock.Effect>
                </TextBlock>
                <TextBlock Grid.Column="1" Margin="0,0,20,0" VerticalAlignment="Center">
                    <Hyperlink NavigateUri="https://github.com/AutomateSilent/QDeploy" 
                              Name="ProjectLink" 
                              Foreground="#FF7B2FBE"
                              TextDecorations="None">
                        <TextBlock Text="Project" Foreground="#FF7B2FBE"/>
                    </Hyperlink>
                </TextBlock>
            </Grid>
        </Border>
        
        <!-- Content -->
        <StackPanel Grid.Row="1" Margin="20,20,20,0">
            <TextBlock Text="Select installation directory:" 
                   Foreground="White" 
                   Margin="0,0,0,10"/>
            
            <Grid Margin="0,0,0,20">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBox Name="PathTextBox" 
                     Text="C:\QDeploy" 
                     Padding="8"
                     Grid.Column="0"
                     Background="#FF2A2A2A"
                     Foreground="White"
                     BorderBrush="#FF7B2FBE"/>
                
                <Button Name="BrowseButton" 
                    Content="Browse" 
                    Grid.Column="1"
                    Margin="10,0,0,0"
                    Style="{StaticResource ButtonStyle}"/>
            </Grid>
            
            <TextBlock Text="Application Name (Optional):" 
                   Foreground="White" 
                   Margin="0,0,0,10"/>
                   
            <TextBox Name="AppNameTextBox" 
                 Padding="8"
                 Margin="0,0,0,20"
                 Background="#FF2A2A2A"
                 Foreground="White"
                 BorderBrush="#FF7B2FBE"/>
            
            <TextBlock Text="QDeploy will be installed to the specified location. If an Application Name is provided, the folder will be named 'QDeploy - [AppName]' and the $AppName variable in QDeploy.ps1 will be set to this value." 
                   Foreground="LightGray" 
                   TextWrapping="Wrap"/>
                   
            <CheckBox Name="VerboseLoggingCheckBox" 
                  Content="Enable verbose logging in QDeploy.ps1" 
                  Foreground="White" 
                  Margin="0,15,0,0"/>
        </StackPanel>
        
        <!-- Footer -->
        <Grid Grid.Row="2" Margin="20">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            
            <Button Name="InstallButton" 
                Content="Install" 
                Grid.Column="1"
                Margin="0,0,10,0"
                MinWidth="100"
                Style="{StaticResource ButtonStyle}"/>
            
            <Button Name="CancelButton" 
                Content="Cancel" 
                Grid.Column="2"
                MinWidth="100"
                Style="{StaticResource ButtonStyle}"/>
        </Grid>
    </Grid>
</Window>
"@

    Write-Verbose "Creating main installer window"
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Get the controls
    $pathTextBox = $window.FindName("PathTextBox")
    $appNameTextBox = $window.FindName("AppNameTextBox")
    $browseButton = $window.FindName("BrowseButton")
    $installButton = $window.FindName("InstallButton")
    $cancelButton = $window.FindName("CancelButton")
    $projectLink = $window.FindName("ProjectLink")
    $verboseLoggingCheckBox = $window.FindName("VerboseLoggingCheckBox")

    # Event: Project link clicked
    $projectLink.Add_RequestNavigate({
        Write-Verbose "Opening project URL: $($_.Uri.AbsoluteUri)"
        Start-Process $_.Uri.AbsoluteUri
    })

    # Event: Browse button clicked
    $browseButton.Add_Click({
        Write-Verbose "Browse button clicked"
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select installation directory"
        $folderBrowser.SelectedPath = $pathTextBox.Text
        
        if ($folderBrowser.ShowDialog() -eq "OK") {
            Write-Verbose "Selected directory: $($folderBrowser.SelectedPath)"
            $pathTextBox.Text = $folderBrowser.SelectedPath
        }
        else {
            Write-Verbose "Directory selection cancelled"
        }
    })

    # Event: Cancel button clicked
    $cancelButton.Add_Click({
        Write-Verbose "Cancel button clicked, closing installer"
        $window.Close()
    })

    # Event: Install button clicked
    $installButton.Add_Click({
        $installPath = $pathTextBox.Text
        $appName = $appNameTextBox.Text.Trim()
        $enableVerbose = $verboseLoggingCheckBox.IsChecked
        
        Write-Verbose "Install button clicked"
        Write-Verbose "Install path: $installPath"
        Write-Verbose "App name: $appName"
        Write-Verbose "Enable verbose logging: $enableVerbose"
        
        # Validate the path
        if ([string]::IsNullOrWhiteSpace($installPath)) {
            Write-Verbose "Error: Empty installation path"
            [System.Windows.MessageBox]::Show("Please specify an installation directory.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        # Create the target directory path based on AppName if provided
        if (-not [string]::IsNullOrWhiteSpace($appName)) {
            $targetDir = Join-Path $installPath "QDeploy - $appName"
        } else {
            $targetDir = Join-Path $installPath "QDeploy"
        }
        Write-Verbose "Target directory: $targetDir"
        
        # Create the directory if it doesn't exist
        try {
            if (-not (Test-Path -Path $targetDir)) {
                Write-Verbose "Creating target directory: $targetDir"
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            else {
                Write-Verbose "Target directory already exists"
            }
            
            # Create temp extraction directory
            $extractPath = Join-Path $tempDir "extracted"
            Write-Verbose "Creating temporary extraction directory: $extractPath"
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
            
            # Extract the zip file to the temp extraction directory
            Write-Verbose "Extracting zip file to: $extractPath"
            Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
            
            # Check if there's a QDeploy subdirectory in the extracted content
            $extractedItems = Get-ChildItem -Path $extractPath
            Write-Verbose "Extracted items at root: $($extractedItems.Name -join ', ')"
            
            # Define the source path for copying files
            $sourcePath = $extractPath
            if ($extractedItems.Count -eq 1 -and $extractedItems[0].PSIsContainer -and $extractedItems[0].Name -eq "QDeploy") {
                Write-Verbose "Found single QDeploy directory in extraction, using that as source"
                $sourcePath = Join-Path $extractPath "QDeploy"
            }
            
            # Find and modify the QDeploy.ps1 file if AppName is provided
            if (-not [string]::IsNullOrWhiteSpace($appName)) {
                $qdeployScripts = Get-ChildItem -Path $sourcePath -Filter "QDeploy.ps1" -Recurse
                Write-Verbose "Found $($qdeployScripts.Count) QDeploy.ps1 files"
                
                foreach ($qdeployScript in $qdeployScripts) {
                    Write-Verbose "Processing script: $($qdeployScript.FullName)"
                    
                    # Read the content of the QDeploy.ps1 file
                    $scriptContent = Get-Content -Path $qdeployScript.FullName -Raw
                    
                    # Replace the AppName variable with better pattern matching
                    Write-Verbose "Original script contains AppName definition: $($scriptContent -match '\$AppName\s*=\s*"MyApp"')"
                    
                    # More precise pattern for replacing the AppName
                    $originalContent = $scriptContent
                    $scriptContent = $scriptContent -replace '(\$AppName\s*=\s*)"MyApp"', ('$1"' + $appName + '"')
                    
                    # Verify replacement worked
                    if ($originalContent -eq $scriptContent) {
                        Write-Verbose "WARNING: AppName replacement did not change the content, trying alternate pattern"
                        # Try alternate pattern if the first one didn't match
                        $scriptContent = $originalContent -replace '(\$AppName\s*=\s*)["'']MyApp["'']', ('$1"' + $appName + '"')
                    }
                    
                    Write-Verbose "Modified script now contains: $($scriptContent -match [regex]::Escape('$AppName = "' + $appName + '"'))"
                    
                    # Add verbose logging if requested
                    if ($enableVerbose) {
                        Write-Verbose "Adding verbose logging to script"
                        
                        # Find the CmdletBinding attribute or param block
                        if ($scriptContent -match '\[CmdletBinding\(\)\]') {
                            Write-Verbose "Script already has CmdletBinding attribute"
                        }
                        else {
                            Write-Verbose "Adding CmdletBinding attribute to script"
                            
                            # Add CmdletBinding before param block if it exists
                            if ($scriptContent -match 'param\s*\(') {
                                $scriptContent = $scriptContent -replace 'param\s*\(', '[CmdletBinding()]' + "`nparam("
                            }
                            else {
                                # Add CmdletBinding and param block at the beginning of the script (after any comments)
                                $insertPoint = 0
                                
                                # Find a suitable insertion point after comments and empty lines
                                if ($scriptContent -match '(^|\n)(?!\s*#|\s*$)') {
                                    $insertPoint = $matches[0].LastIndexOf("`n") + 1
                                }
                                
                                $scriptContent = $scriptContent.Insert($insertPoint, 
                                    "[CmdletBinding()]`nparam()`n`n"
                                )
                            }
                        }
                        
                        # Add Write-Verbose statements to key points in the script
                        $verboseStatements = @(
                            '# Verbose logging',
                            'Write-Verbose "QDeploy starting with AppName: $AppName"',
                            'Write-Verbose "Current working directory: $(Get-Location)"',
                            'Write-Verbose "Script executing from: $PSScriptRoot"'
                        )
                        
                        # Find insertion point after variable declarations
                        if ($scriptContent -match '(\$AppName\s*=\s*".+?"[^\n]*\n)') {
                            $insertAfter = $matches[0]
                            $insertPoint = $scriptContent.IndexOf($insertAfter) + $insertAfter.Length
                            $scriptContent = $scriptContent.Insert($insertPoint, "`n" + ($verboseStatements -join "`n") + "`n")
                        }
                    }
                    
                    # Save the modified file
                    Write-Verbose "Saving modified script back to: $($qdeployScript.FullName)"
                    Set-Content -Path $qdeployScript.FullName -Value $scriptContent -Force
                }
            }
            
            # Copy files from source to target
            Write-Verbose "Copying files from $sourcePath to $targetDir"
            Get-ChildItem -Path $sourcePath -Recurse | ForEach-Object {
                # Calculate relative path from source
                $relativePath = $_.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
                $targetPath = Join-Path $targetDir $relativePath
                
                # Create directory if it's a directory
                if ($_.PSIsContainer) {
                    if (-not (Test-Path -Path $targetPath)) {
                        Write-Verbose "Creating directory: $targetPath"
                        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                    }
                }
                # Copy file if it's a file
                else {
                    $targetParent = Split-Path -Parent $targetPath
                    if (-not (Test-Path -Path $targetParent)) {
                        Write-Verbose "Creating parent directory: $targetParent"
                        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                    }
                    Write-Verbose "Copying file to: $targetPath"
                    Copy-Item -Path $_.FullName -Destination $targetPath -Force
                }
            }
            
            # Show success message
            $successMsg = if (-not [string]::IsNullOrWhiteSpace($appName)) {
                "QDeploy has been successfully installed to '$targetDir' with application name '$appName'."
            } else {
                "QDeploy has been successfully installed to '$targetDir'."
            }
            
            if ($enableVerbose) {
                $successMsg += "`n`nVerbose logging has been enabled in QDeploy.ps1."
            }
            
            Write-Verbose "Installation complete"
            [System.Windows.MessageBox]::Show($successMsg, "Installation Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            
            # Close the window
            $window.Close()
        }
        catch {
            Write-Verbose "ERROR: Installation failed with exception: $_"
            [System.Windows.MessageBox]::Show("Failed to install QDeploy: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    # Show the window
    Write-Verbose "Displaying installer window"
    [void]$window.ShowDialog()
}
catch {
    Write-Error "An error occurred: $_"
    Write-Verbose "ERROR: Critical failure in installer: $_"
}
finally {
    # Clean up temporary files
    if (Test-Path -Path $tempDir) {
        Write-Verbose "Cleaning up temporary directory: $tempDir"
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}