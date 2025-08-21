<# 
setup-wsl.ps1  (v3)
- Enables WSL2 features, installs Ubuntu, then installs Rancher Desktop (from a local MSI/EXE in this folder).
- Auto-resumes after reboot when features were enabled.
USAGE (Admin PS):
  Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup-wsl.ps1 [-Distro Ubuntu] [-OfflineAppx .\Ubuntu.appx] [-SkipAppInstall] [-ForceReboot] [-InteractiveInstall] [-ConfigureRancher]
#>

[CmdletBinding()]
param(
  [string]$Distro = "Ubuntu",
  [string]$OfflineAppx,               # optional path to Ubuntu .appx/.msixbundle for offline install
  [switch]$SkipAppInstall,            # don't run generic EXE/MSI (non-Rancher)
  [switch]$ForceReboot,               # force immediate reboot when features were enabled
  [switch]$InteractiveInstall,        # prefer interactive installers (skip silent args)
  [switch]$ConfigureRancher           # after install, try to set moby (dockerd) & disable Kubernetes
)

$ErrorActionPreference = 'Stop'
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$StateFile  = Join-Path $PSScriptRoot ".setup-wsl.state.json"
$LogFile    = Join-Path $PSScriptRoot "setup-wsl.log"

Start-Transcript -Path $LogFile -Append | Out-Null
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "[FAIL] $m" -ForegroundColor Red }

# --- Admin check ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Fail "Run this script as Administrator."
  Stop-Transcript | Out-Null; exit 100
}

# --- State helpers ---
function Save-State([hashtable]$h) { $h | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8 }
function Load-State { if(Test-Path $StateFile){ Get-Content $StateFile | ConvertFrom-Json } else { @{} } }

# --- OS / Build ---
$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$Build = [int]$os.CurrentBuildNumber
Info "Windows: $($os.DisplayVersion) (Build $Build)"

# --- CPU/BIOS virtualization ---
try {
  $hv = Get-ComputerInfo -Property "HyperVRequirement*"
  Info "DEP: $($hv.HyperVRequirementDataExecutionPreventionAvailable) | SLAT: $($hv.HyperVRequirementSecondLevelAddressTranslation) | VT-x/SVM Enabled in BIOS: $($hv.HyperVRequirementVirtualizationFirmwareEnabled) | VM Monitor: $($hv.HyperVRequirementVMMonitorModeExtensions)"
  if (-not $hv.HyperVRequirementVMMonitorModeExtensions) { Fail "CPU lacks VT-x/AMD-V. Exiting."; Stop-Transcript; exit 200 }
  if (-not $hv.HyperVRequirementVirtualizationFirmwareEnabled) {
    Fail "Hardware virtualization is DISABLED in BIOS/UEFI. This cannot be toggled by Windows."
    Warn "Enable: Intel VT-x (or AMD SVM) in BIOS, then rerun."
    Stop-Transcript; exit 201
  }
  Ok "Hardware virtualization available and enabled."
} catch {
  Warn "Hyper-V capability check failed: $($_.Exception.Message)"
}

# --- Enable WSL features ---
$FeaturesChanged = $false
$features = @("Microsoft-Windows-Subsystem-Linux","VirtualMachinePlatform")
foreach($f in $features){
  $state = (Get-WindowsOptionalFeature -Online -FeatureName $f).State
  if ($state -ne "Enabled") {
    Info "Enabling feature: $f"
    Enable-WindowsOptionalFeature -Online -FeatureName $f -NoRestart | Out-Null
    $FeaturesChanged = $true
  } else { Ok "$f already enabled." }
}

# --- If features changed, set RunOnce + reboot or exit ---
if ($FeaturesChanged) {
  Warn "System features were changed; reboot is recommended before continuing."
  $state = @{
    PendingReboot = $true
    Distro = $Distro
    OfflineAppx = $OfflineAppx
    SkipAppInstall = [bool]$SkipAppInstall
    InteractiveInstall = [bool]$InteractiveInstall
    ConfigureRancher = [bool]$ConfigureRancher
  }
  Save-State $state
  $cmd = "powershell -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -Distro `"$Distro`" " +
         ($(if($OfflineAppx){ "-OfflineAppx `"$OfflineAppx`" " } else { "" })) +
         ($(if($SkipAppInstall){ "-SkipAppInstall " } else { "" })) +
         ($(if($InteractiveInstall){ "-InteractiveInstall " } else { "" })) +
         ($(if($ConfigureRancher){ "-ConfigureRancher " } else { "" }))
  New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "setup-wsl-resume" -Value $cmd -Force | Out-Null
  if ($ForceReboot) {
    Info "Rebooting now to complete feature enable..."
    Stop-Transcript | Out-Null
    Restart-Computer
    exit 0
  } else {
    Warn "Please reboot manually, then the script will resume automatically."
    Stop-Transcript | Out-Null
    exit 0
  }
}

# --- WSL platform & kernel ---
function WslAvailable { try { wsl.exe --status | Out-Null; return $true } catch { return $false } }
if (-not (WslAvailable)) {
  Info "Installing WSL platform..."
  try { wsl --install --no-distribution } catch { Warn "wsl --install failed: $($_.Exception.Message)" }
} else { Ok "WSL platform available." }

try { wsl --set-default-version 2; Ok "WSL default set to v2." } catch { Warn "Could not set default WSL2: $($_.Exception.Message)" }
try { wsl --update; Ok "WSL kernel updated (if needed)." } catch { Warn "Kernel update skipped/failed: $($_.Exception.Message)" }

# --- Install Ubuntu (Store or Offline) ---
function DistroInstalled($name){ try { (wsl -l -q) -contains $name } catch { $false } }

if (-not (DistroInstalled $Distro)) {
  if ($OfflineAppx -and (Test-Path $OfflineAppx)) {
    Info "Installing $Distro from offline package: $OfflineAppx"
    try {
      Add-AppxPackage -Path $OfflineAppx
      Ok "$Distro appx installed. Launch it once to finalize user setup."
    } catch {
      Fail "Offline install failed: $($_.Exception.Message)"
    }
  } else {
    Info "Installing $Distro via WSL..."
    try {
      wsl --install -d $Distro
      Warn "If prompted to reboot or finalize setup, please do so; launch $Distro once to create your Linux user."
    } catch {
      Warn "Automatic $Distro install failed: $($_.Exception.Message). You can install it from Microsoft Store."
    }
  }
} else { Ok "$Distro already installed." }

# ==================================================================
# Rancher Desktop section
# ==================================================================

function Is-RancherInstalled {
  try {
    $paths = @(
      "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
      "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach($p in $paths){
      $apps = Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "Rancher Desktop*" }
      if ($apps) { return $true }
    }
  } catch {}
  # quick CLI probe:
  $rd = Get-Command "rdctl.exe" -ErrorAction SilentlyContinue
  if ($rd) { return $true }
  return $false
}

# Pick Rancher Desktop installer in this folder (prefer MSI)
$rancherMsi = Get-ChildItem -Path $PSScriptRoot -Filter "*Rancher*Desktop*.msi" -File -ErrorAction SilentlyContinue | Select-Object -First 1
$rancherExe = Get-ChildItem -Path $PSScriptRoot -Filter "*Rancher*Desktop*.exe" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne $ScriptName } | Select-Object -First 1

if (Is-RancherInstalled) {
  Ok "Rancher Desktop already installed. Skipping installer."
} elseif ($rancherMsi -or $rancherExe) {
  Info "Installing Rancher Desktop..."
  try {
    if ($rancherMsi) {
      if ($InteractiveInstall) {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$($rancherMsi.FullName)`"" -Wait
      } else {
        Start-Process "msiexec.exe" -ArgumentList "/i `"$($rancherMsi.FullName)`" /qn" -Wait
      }
      Ok "Rancher Desktop MSI installation completed."
    } else {
      if ($InteractiveInstall) {
        Start-Process $rancherExe.FullName -Wait
        Ok "Rancher Desktop EXE installation (interactive) completed."
      } else {
        $silentArgs = @("/S","/silent","/verysilent","/quiet","/qn")  # try common silent switches
        $done = $false
        foreach($a in $silentArgs){
          try { Start-Process $rancherExe.FullName -ArgumentList $a -Wait; $done=$true; Ok "Rancher Desktop EXE installed silently ($a)."; break } catch { }
        }
        if (-not $done) {
          Warn "Silent flags not supported; launching interactive installer..."
          Start-Process $rancherExe.FullName -Wait
          Ok "Rancher Desktop EXE installation completed (interactive)."
        }
      }
    }
  } catch {
    Fail "Rancher Desktop installation failed: $($_.Exception.Message)"
  }
} else {
  Warn "No Rancher Desktop installer found in script folder. Place the MSI/EXE here and rerun if you want it installed."
}

# --- Optional post-install configuration for Rancher Desktop ---
if ($ConfigureRancher -and (Is-RancherInstalled)) {
  Info "Attempting basic Rancher Desktop configuration (moby/dockerd, Kubernetes off)..."
  try {
    # Try rdctl if available
    $rdctl = Get-Command "rdctl.exe" -ErrorAction SilentlyContinue
    if ($rdctl) {
      # These commands are best-effort; if unsupported, they will be ignored gracefully.
      try { & $rdctl.Path shutdown | Out-Null } catch {}
      try { & $rdctl.Path set --container-engine moby | Out-Null } catch {}
      try { & $rdctl.Path set --kubernetes-enabled false | Out-Null } catch {}
      try { & $rdctl.Path start | Out-Null } catch {}
      Ok "Rancher Desktop configured (best-effort)."
    } else {
      Warn "rdctl CLI not found in PATH. You can adjust settings in Rancher Desktop UI (Preferences → Container Runtime: moby, Kubernetes: Off)."
    }
  } catch {
    Warn "Could not apply Rancher defaults automatically: $($_.Exception.Message)"
  }
}

# --- Optional: generic EXE/MSI from this folder (non-Rancher) ---
if (-not $SkipAppInstall) {
  # Avoid running the Rancher installer again by excluding it
  $msi = Get-ChildItem -Path $PSScriptRoot -Filter *.msi -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $rancherMsi.FullName } | Select-Object -First 1
  $exe = Get-ChildItem -Path $PSScriptRoot -Filter *.exe -File -ErrorAction SilentlyContinue | Where-Object { ($_.Name -ne $ScriptName) -and ($_.FullName -ne $rancherExe.FullName) } | Select-Object -First 1

  if ($msi -or $exe) {
    Info "Installing additional EXE/MSI found in folder..."
    try {
      if ($msi) {
        if ($InteractiveInstall) { Start-Process "msiexec.exe" -ArgumentList "/i `"$($msi.FullName)`"" -Wait }
        else { Start-Process "msiexec.exe" -ArgumentList "/i `"$($msi.FullName)`" /qn" -Wait }
        Ok "MSI installed."
      } else {
        if ($InteractiveInstall) {
          Start-Process $exe.FullName -Wait; Ok "EXE finished (interactive)."
        } else {
          $silentArgs = @("/S","/silent","/verysilent","/quiet","/qn")
          $done = $false
          foreach($a in $silentArgs){
            try { Start-Process $exe.FullName -ArgumentList $a -Wait; $done=$true; Ok "EXE installed silently ($a)."; break } catch { }
          }
          if (-not $done) { Start-Process $exe.FullName -Wait; Ok "EXE finished (interactive)." }
        }
      }
    } catch {
      Fail "Additional installer failed: $($_.Exception.Message)"
    }
  } else {
    Info "No additional EXE/MSI found (besides Rancher)."
  }
} else {
  Info "SkipAppInstall set: not installing extra EXE/MSI."
}

# --- Summary popup ---
$summary = @()
$virtOK = $true
try {
  $hv = Get-ComputerInfo -Property "HyperVRequirement*"
  $virtOK = [bool]$hv.HyperVRequirementVirtualizationFirmwareEnabled
} catch {}
$summary += "Virtualization (BIOS): " + ($virtOK ? "Enabled" : "Disabled")
$summary += "WSL platform: " + ($(WslAvailable) ? "OK" : "Missing")
$summary += "$Distro installed: " + ((DistroInstalled $Distro) ? "Yes" : "No (install from Store)")
$summary += "Rancher Desktop: " + ($(Is-RancherInstalled) ? "Installed" : "Not found/Not installed")
$summary += "Log: $LogFile"
$summaryText = $summary -join "`r`n"

try {
  Add-Type -AssemblyName PresentationFramework | Out-Null
  [System.Windows.MessageBox]::Show($summaryText, "Setup Summary", "OK", "Information") | Out-Null
} catch {
  Write-Host "`n--- SUMMARY ---`n$summaryText`n----------------" -ForegroundColor Magenta
}

Ok "Done."
Stop-Transcript | Out-Null
exit 0
