Windows WSL + Ubuntu + Rancher Desktop Setup Script
===================================================

This repository contains a PowerShell automation script (setup-wsl.ps1) to prepare a Windows PC for WSL2, install Ubuntu, and then install Rancher Desktop from a local installer.
It is designed for one-click setup: detects prerequisites, enables Windows features, auto-resumes after reboot, and installs everything with clear status messages.

---------------------------------------------------
Features
---------------------------------------------------
- Detects if CPU & BIOS virtualization (VT-x / AMD-V) are enabled
- Enables required Windows features: WSL and VirtualMachinePlatform
- Installs or updates WSL2 kernel
- Installs Ubuntu (via "wsl --install" or offline .appx if provided)
- Installs Rancher Desktop (MSI/EXE in same folder)
- Supports silent install (falls back to interactive if not supported)
- Optional auto-config for Rancher Desktop: sets dockerd (moby) and disables Kubernetes
- Auto-resumes after reboot if system features required restart
- Generates a log file and end-of-run summary popup

---------------------------------------------------
Requirements
---------------------------------------------------
- Windows 10 2004+ (build 19041) or Windows 11
- CPU with Intel VT-x or AMD-V virtualization support
- Virtualization enabled in BIOS/UEFI
- Administrator privileges to run the script
- Rancher Desktop installer (.msi or .exe) in the same folder as the script

---------------------------------------------------
Usage
---------------------------------------------------
1. Clone or download this repo.
2. Place your Rancher Desktop installer (Rancher.Desktop-x.y.z.msi or .exe) in the same folder as setup-wsl.ps1.
3. Open PowerShell as Administrator.
4. Run:

   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\setup-wsl.ps1 -ConfigureRancher

5. If Windows features are enabled during setup, the script will:
   - Ask for a reboot (or force reboot if -ForceReboot is used).
   - Resume automatically after reboot to continue installation.

---------------------------------------------------
Options
---------------------------------------------------
-Distro Ubuntu      Distro name to install (default = Ubuntu).
-OfflineAppx PATH   Install Ubuntu from an offline .appx or .msixbundle instead of Store.
-SkipAppInstall     Skip installation of any additional EXE/MSI in folder (only Rancher runs).
-ForceReboot        Immediately reboot after enabling Windows features.
-InteractiveInstall Prefer interactive installs (skip silent mode, user clicks Next).
-ConfigureRancher   After Rancher Desktop install, attempt to set dockerd + disable Kubernetes.

---------------------------------------------------
Example Commands
---------------------------------------------------
Standard run (Ubuntu + Rancher, silent if possible):
  .\setup-wsl.ps1 -ConfigureRancher

Install Ubuntu from an offline package:
  .\setup-wsl.ps1 -OfflineAppx .\Ubuntu_22.04.appx -ConfigureRancher

Force reboot automatically after enabling Windows features:
  .\setup-wsl.ps1 -ForceReboot -ConfigureRancher

Prefer interactive installers (manual clicking):
  .\setup-wsl.ps1 -InteractiveInstall -ConfigureRancher

---------------------------------------------------
After Installation
---------------------------------------------------
Check Docker works (via Rancher Desktop moby runtime):
  docker run hello-world

Check WSL status:
  wsl --status
  wsl -l -v

Open Rancher Desktop from Start Menu -> Preferences:
  Container Runtime: moby (dockerd)
  Kubernetes: Off (if not needed)

---------------------------------------------------
Logs & Troubleshooting
---------------------------------------------------
- All actions are logged to: setup-wsl.log
- If virtualization is disabled in BIOS, the script will stop and explain how to enable it.
- If "wsl --install" fails, install Ubuntu manually from the Microsoft Store.
- Rancher Desktop first startup may take a few minutes to initialize.

---------------------------------------------------
License
---------------------------------------------------
MIT License – free to use, modify, and share.

---------------------------------------------------
Credits
---------------------------------------------------
This script was designed to make Windows → WSL2 → Rancher Desktop setup as automated and foolproof as possible.
