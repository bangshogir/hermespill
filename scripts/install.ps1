# Per-user installer for HermesPill - no admin rights, no external tooling.
#
#   powershell -ExecutionPolicy Bypass -File scripts\install.ps1
#
# Copies the built hermespill.exe to %LOCALAPPDATA%\Programs\HermesPill, creates a Start
# Menu shortcut and (optionally) registers the launch-on-startup entry.
# scripts\uninstall.ps1 removes everything again.
#
# Switches:
#   -Source <path>      exe to install (default: target\release\hermespill.exe)
#   -Startup            also register "launch when Windows starts"
#   -DesktopShortcut    also create a desktop shortcut
#   -NoLaunch           do not start HermesPill after installing
[CmdletBinding()]
param(
    [string]$Source,
    [switch]$Startup,
    [switch]$DesktopShortcut,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

if (-not $Source) { $Source = Join-Path $PSScriptRoot "..\target\release\hermespill.exe" }
if (-not (Test-Path $Source)) {
    throw "hermespill.exe not found at '$Source' - run 'cargo build --release' first"
}
$Source = (Resolve-Path $Source).Path

$DestDir = Join-Path $env:LOCALAPPDATA "Programs\HermesPill"
$DestExe = Join-Path $DestDir "hermespill.exe"

# A running copy would keep the exe locked and keep drawing its overlay.
Get-Process hermespill -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
Copy-Item $Source $DestExe -Force
Copy-Item (Join-Path $PSScriptRoot "..\LICENSE") $DestDir -Force -ErrorAction SilentlyContinue

$ws = New-Object -ComObject WScript.Shell
$group = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\HermesPill"
New-Item -ItemType Directory -Force -Path $group | Out-Null
$lnk = $ws.CreateShortcut((Join-Path $group "HermesPill.lnk"))
$lnk.TargetPath = $DestExe
$lnk.WorkingDirectory = $DestDir
$lnk.Save()
Write-Host "Start Menu shortcut:" (Join-Path $group "HermesPill.lnk")

if ($DesktopShortcut) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $d = $ws.CreateShortcut((Join-Path $desktop "HermesPill.lnk"))
    $d.TargetPath = $DestExe
    $d.WorkingDirectory = $DestDir
    $d.Save()
    Write-Host "Desktop shortcut:" (Join-Path $desktop "HermesPill.lnk")
}

if ($Startup) {
    # HermesPill adopts this entry on first run; from then on it is managed from
    # Settings > App > Preferences (or the Startup list in Task Manager).
    $run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (-not (Test-Path $run)) { New-Item -Path $run -Force | Out-Null }
    Set-ItemProperty -Path $run -Name "HermesPill" -Value ('"{0}" --startup' -f $DestExe)
    Write-Host "Launch on startup: enabled"
}

Write-Host ""
Write-Host "HermesPill installed:" $DestExe
Write-Host "Settings survive reinstalls; %APPDATA%\hermespill\config.json is shared."

if (-not $NoLaunch) {
    # Without --startup the settings window opens, so a fresh install starts
    # with the app in front of the user.
    Start-Process $DestExe
}
