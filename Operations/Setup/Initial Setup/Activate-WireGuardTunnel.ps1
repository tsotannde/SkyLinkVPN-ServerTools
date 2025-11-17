# ===============================================
# WireGuard Tunnel Activator
# Author: Adebayo Sotannde
# Automatically activates all tunnel .conf files
# located in Desktop\Operations\System Core\Tunnels
# ===============================================

# --- Setup Logging ---
$ScriptName  = "WireGuard Tunnel Activator Script"
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
Write-Host "   WireGuard Tunnel Activator" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Dynamically locate the System Core\Tunnels folder ---
$desktopPath = [Environment]::GetFolderPath('Desktop')
$tunnelDir   = Join-Path $desktopPath "Operations\System Core\Tunnels"
$wgExe       = "C:\Program Files\WireGuard\wireguard.exe"

# --- Ensure folder exists ---
if (-not (Test-Path $tunnelDir)) {
    Write-Host "[ERROR] Tunnels folder not found: $tunnelDir" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Get all tunnel configs ---
$tunnels = Get-ChildItem -Path $tunnelDir -Filter "*.conf" -ErrorAction SilentlyContinue
if (-not $tunnels) {
    Write-Host "[ERROR] No .conf files found in $tunnelDir" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

foreach ($file in $tunnels) {
    $name     = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $confPath = $file.FullName
    $svcName  = "WireGuardTunnel$" + $name
    $svc      = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $svcName }

    Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Tunnel: $name" -ForegroundColor Cyan

    if ($svc -and $svc.Status -eq 'Running') {
        Write-Host "[SKIP] $name already running." -ForegroundColor Yellow
        continue
    }

    Write-Host "[INFO] Activating $name..." -ForegroundColor Cyan
    try {
        & $wgExe /installtunnelservice $confPath | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "[SUCCESS] $name activated successfully." -ForegroundColor Green
    }
    catch {
        Write-Host ("[ERROR] Failed to activate {0}: {1}" -f $name, $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host "`n================================" -ForegroundColor Yellow
Write-Host "   Activation Complete" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow

Stop-Transcript
