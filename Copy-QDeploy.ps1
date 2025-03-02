#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs QDeploy framework to your system with a graphical interface.

.DESCRIPTION
    Downloads and extracts the QDeploy framework to a specified location.
    Provides a WPF-based UI for selecting the installation directory.
    Default location is C:\QDeploy if no custom path is selected.

.EXAMPLE
    irm https://raw.githubusercontent.com/AutomateSilent/QDeploy/main/Copy-QDeploy.ps1 | iex
    Downloads and runs the installer with the graphical interface.

.NOTES
    Author: AutomateSilent
    Version: 1.0
    Project URL: https://github.com/AutomateSilent/QDeploy
#>

[CmdletBinding()]
param()

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Create a temporary directory to download and extract the zip file
$tempDir = Join-Path $env:TEMP "QDeploy_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download the latest release of QDeploy
$releaseUrl = "https://github.com/AutomateSilent/QDeploy/releases/latest/download/QDeploy.zip"
$zipFile = Join-Path $tempDir "QDeploy.zip"

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

    $reader = New-Object System.Xml.XmlNodeReader $splashXaml
    $splashWindow = [Windows.Markup.XamlReader]::Load($reader)
    $splashWindow.Show()

    # Download the release
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($releaseUrl, $zipFile)
    
    # Close splash screen
    $splashWindow.Close()

    # Create and show the main installer window
    [xml]$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="QDeploy Installer" 
    Height="300" 
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
            
            <TextBlock Text="QDeploy will be installed to the specified location. The framework provides a standardized way to create deployable scripts with logging and structure." 
                   Foreground="LightGray" 
                   TextWrapping="Wrap"/>
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

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Get the controls
    $pathTextBox = $window.FindName("PathTextBox")
    $browseButton = $window.FindName("BrowseButton")
    $installButton = $window.FindName("InstallButton")
    $cancelButton = $window.FindName("CancelButton")
    $projectLink = $window.FindName("ProjectLink")

    # Event: Project link clicked
    $projectLink.Add_RequestNavigate({
        Start-Process $_.Uri.AbsoluteUri
    })

    # Event: Browse button clicked
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select installation directory"
        $folderBrowser.SelectedPath = $pathTextBox.Text
        
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $pathTextBox.Text = $folderBrowser.SelectedPath
        }
    })

    # Event: Cancel button clicked
    $cancelButton.Add_Click({
        $window.Close()
    })

    # Event: Install button clicked
    $installButton.Add_Click({
        $installPath = $pathTextBox.Text
        
        # Validate the path
        if ([string]::IsNullOrWhiteSpace($installPath)) {
            [System.Windows.MessageBox]::Show("Please specify an installation directory.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        # Create the directory if it doesn't exist
        try {
            if (-not (Test-Path -Path $installPath)) {
                New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            }
            
            # Extract the zip file
            Expand-Archive -Path $zipFile -DestinationPath $installPath -Force
            
            # Show success message
            [System.Windows.MessageBox]::Show("QDeploy has been successfully installed to '$installPath'.", "Installation Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            
            # Close the window
            $window.Close()
        }
        catch {
            [System.Windows.MessageBox]::Show("Failed to install QDeploy: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    # Show the window
    [void]$window.ShowDialog()
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Clean up temporary files
    if (Test-Path -Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
