# Per-user uninstaller for HermesPill - the counterpart to scripts\install.ps1.
#
#   powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1 -PurgeConfig
#
# Removes the autostart entry, shortcuts and the installed files. Settings in
# %APPDATA%\hermespill are kept unless -PurgeConfig is passed, so a reinstall comes
# back exactly as it was left.
[CmdletBinding()]
param(
    [switch]$PurgeConfig
)

$ErrorActionPreference = "SilentlyContinue"

Get-Process hermespill | Stop-Process -Force
Start-Sleep -Milliseconds 500

# Autostart entry, plus the Task Manager approval leftover next to it.
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "HermesPill"
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "HermesPill"

$group = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\HermesPill"
Remove-Item (Join-Path $group "HermesPill.lnk") -Force
Remove-Item $group -Force
Remove-Item (Join-Path ([Environment]::GetFolderPath("Desktop")) "HermesPill.lnk") -Force

$dest = Join-Path $env:LOCALAPPDATA "Programs\HermesPill"
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }

Write-Host "HermesPill uninstalled."
if ($PurgeConfig) {
    Remove-Item (Join-Path $env:APPDATA "hermespill") -Recurse -Force
    Write-Host "Configuration removed (%APPDATA%\hermespill)."
} else {
    Write-Host "Configuration kept at %APPDATA%\hermespill (use -PurgeConfig to remove)."
}
