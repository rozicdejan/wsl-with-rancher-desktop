# Windows WSL + Ubuntu + Rancher Desktop Setup Script

A **PowerShell automation script** that prepares your Windows PC for containerized development by setting up WSL2, Ubuntu, and Rancher Desktop in one seamless operation.

## 🎯 What This Does

This script transforms a fresh Windows machine into a ready-to-go development environment with:
- **WSL2** (Windows Subsystem for Linux) with Ubuntu distribution
- **Rancher Desktop** for container management (Docker-compatible)
- Proper virtualization detection and configuration
- Automatic recovery from required system reboots

Perfect for developers who want to quickly set up a Linux containerization environment on Windows without manual configuration steps.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔍 **Smart Detection** | Automatically detects CPU virtualization support and BIOS settings |
| 🔧 **Windows Features** | Enables WSL and VirtualMachinePlatform features automatically |
| 🐧 **Ubuntu Installation** | Installs Ubuntu via `wsl --install` or offline `.appx` package |
| 🐳 **Rancher Desktop** | Installs from local MSI/EXE with silent or interactive mode |
| ⚙️ **Auto-Configuration** | Optionally configures Rancher to use dockerd (moby) and disable Kubernetes |
| 🔄 **Reboot Recovery** | Automatically resumes setup after required system restarts |
| 📝 **Detailed Logging** | Generates comprehensive logs and summary reports |

## 📋 Prerequisites

### System Requirements
- **OS**: Windows 10 (build 19041+) or Windows 11
- **CPU**: Intel VT-x or AMD-V virtualization support
- **BIOS**: Virtualization enabled (VT-x/AMD-V/SVM)
- **Privileges**: Administrator access required

### Files Needed
- This repository's `setup-wsl.ps1` script
- Rancher Desktop installer (`.msi` or `.exe`) - [Download here](https://github.com/rancher-sandbox/rancher-desktop/releases)

> 📁 Place the Rancher Desktop installer in the same folder as the script

## 🚀 Quick Start

### Basic Setup
```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to the script directory
# 3. Run the setup
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup-wsl.ps1 -ConfigureRancher
```

### Alternative Installation Methods

#### With Offline Ubuntu Package
```powershell
.\setup-wsl.ps1 -ConfigureRancher -OfflineAppx .\Ubuntu_22.04.appx
```

#### Interactive Installation (No Silent Install)
```powershell
.\setup-wsl.ps1 -ConfigureRancher -InteractiveInstall
```

#### Minimal Setup (WSL Only)
```powershell
.\setup-wsl.ps1 -SkipAppInstall
```

## ⚙️ Configuration Options

### Command Line Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-ConfigureRancher` | Auto-configures Rancher Desktop with dockerd and disables Kubernetes | Default recommended |
| `-OfflineAppx <path>` | Install Ubuntu from local `.appx` file instead of online | `-OfflineAppx .\Ubuntu_22.04.appx` |
| `-InteractiveInstall` | Force interactive installers (no silent install) | For troubleshooting |
| `-SkipAppInstall` | Skip additional app installations, WSL only | Minimal setup |
| `-ForceReboot` | Immediately reboot when Windows features change | Skip reboot prompt |

### What `-ConfigureRancher` Does
- Sets container runtime to **dockerd (moby)** for Docker compatibility
- Disables **Kubernetes** to reduce resource usage
- Configures Rancher Desktop for typical development workflows

## 🔧 Troubleshooting

### Common Issues

#### Virtualization Not Enabled
```
❌ Error: CPU virtualization is not enabled in BIOS
```
**Solution**: Enter BIOS/UEFI settings and enable:
- Intel: VT-x (Virtualization Technology)
- AMD: AMD-V or SVM (Secure Virtual Machine)

#### Windows Version Too Old
```
❌ Error: Windows build 19041+ required
```
**Solution**: Update Windows 10 to version 2004+ or upgrade to Windows 11

#### Script Execution Blocked
```
❌ Error: Execution of scripts is disabled
```
**Solution**: Run as Administrator and use:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

#### Rancher Desktop Won't Start
1. Wait 1-2 minutes after installation (VM initialization takes time)
2. Check Windows Event Viewer for Hyper-V errors
3. Ensure no other VM software conflicts (VirtualBox, VMware)

## 📁 File Structure

```
your-project-folder/
├── setup-wsl.ps1              # Main setup script
├── Rancher.Desktop-1.x.x.msi  # Rancher Desktop installer
├── Ubuntu_22.04.appx          # (Optional) Offline Ubuntu package
└── setup-log.txt              # Generated log file
```

## 🔄 What Happens During Setup

1. **Pre-flight Check**: Validates Windows version, CPU virtualization, and BIOS settings
2. **Feature Installation**: Enables WSL and VirtualMachinePlatform Windows features
3. **Reboot Handling**: Automatically restarts if needed and resumes setup
4. **WSL2 Setup**: Installs or updates WSL2 kernel and sets as default
5. **Ubuntu Installation**: Downloads and installs Ubuntu distribution
6. **Rancher Desktop**: Installs container management platform
7. **Configuration**: Applies optimal settings for development use
8. **Verification**: Confirms all components are working

## 💡 Post-Installation

### Verify Installation
```powershell
# Check WSL distributions
wsl --list --verbose

# Verify Rancher Desktop (after first launch)
docker --version
```

### Next Steps
1. Launch **Rancher Desktop** from Start Menu (first run takes ~2 minutes)
2. Open **Ubuntu** terminal from Start Menu
3. Test Docker functionality:
   ```bash
   docker run hello-world
   ```

## 🛠️ Advanced Configuration

### Custom WSL Configuration
Create `%USERPROFILE%\.wslconfig` for resource limits:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

### Rancher Desktop Settings
Access via: Rancher Desktop → Preferences
- **Container Runtime**: dockerd (moby) ✅
- **Kubernetes**: Disabled for better performance
- **WSL Integration**: Enable for your distributions

## 🤝 Contributing

Suggestions for additional features:
- [ ] Automatic `.wslconfig` generation with sensible defaults
- [ ] Post-installation Docker smoke test (`docker run hello-world`)
- [ ] Integration with popular development tools (Git, Node.js, etc.)
- [ ] Support for additional Linux distributions

## 📝 License

This project is open source. Use and modify as needed for your development setup.

---

**Need Help?** Open an issue with your setup details and error logs for assistance.
