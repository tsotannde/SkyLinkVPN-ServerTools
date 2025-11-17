# ===============================================
# WireGuard Local Installer 
# Author: Adebayo Sotannde
# Installs WireGuard from Desktop\Operations\Applications
# Compatible with offline MSI package
# ===============================================

# --- Setup Logging ---
$ScriptName  = "WireGuard Local Installer Script"
$Root        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LogDir      = Join-Path $Root "System Core\Logs\$ScriptName"
$TimeStamp   = (Get-Date).ToString("MMMM dd yyyy h-mm-ss tt").Replace(":", "-")

$LogFile     = Join-Path $LogDir "$TimeStamp.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Start-Transcript -Path $LogFile -Append

# --- Header ---
Write-Host "================================" -ForegroundColor Yellow
Write-Host "     Installing WireGuard..." -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Resolve paths ---
$desktopPath = [Environment]::GetFolderPath('Desktop')
$opsDir      = Join-Path $desktopPath "Operations"
$appDir      = Join-Path $opsDir "Applications"
$localMsi    = Join-Path $appDir "wireguard-amd64-0.5.3.msi"
$wgExe       = "C:\Program Files\WireGuard\wireguard.exe"

# === DEBUG START ===
Write-Host "`n[DEBUG] Desktop path: $desktopPath" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Operations path: $opsDir" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Applications path: $appDir" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Looking for installer at: $localMsi" -ForegroundColor DarkCyan
Write-Host "[DEBUG] Directory contents:" -ForegroundColor DarkCyan
Get-ChildItem -Path $appDir | ForEach-Object { Write-Host " - $($_.Name)" -ForegroundColor DarkGray }
# === DEBUG END ===

# --- Verify local installer presence ---
if (-not (Test-Path $localMsi)) {
    Write-Host "[ERROR] WireGuard MSI not found at: $localMsi" -ForegroundColor Red
    Write-Host "Place wireguard-amd64-0.5.3.msi inside Desktop\Operations\Applications first." -ForegroundColor Yellow
    Stop-Transcript
    exit 1
}

# --- Step 1: Install WireGuard silently from MSI ---
Write-Host "[INFO] Installing WireGuard from local MSI..." -ForegroundColor Cyan
Write-Host "[DEBUG] Running command: msiexec.exe /i `"$localMsi`" /quiet /norestart" -ForegroundColor DarkCyan

try {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$localMsi`" /quiet /norestart" -Wait
    Write-Host "[OK] Installation completed successfully." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Step 2: Verify installation path ---
if (Test-Path $wgExe) {
    Write-Host "[INFO] WireGuard executable found at: $wgExe" -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Could not locate wireguard.exe after installation." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Step 3: Verify functionality ---
try {
    & $wgExe /version | Out-Null
    Write-Host "[OK] WireGuard binary verified and working." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] WireGuard verification failed: $($_.Exception.Message)" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

Write-Host "`n================================" -ForegroundColor Yellow
Write-Host "   WireGuard Installation Complete" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Executable Path: $wgExe" -ForegroundColor Cyan

Stop-Transcript
