# ================================
# Server-Mode Power Settings Script (Final GUI-Consistent Version)
# Author: Adebayo Sotannde
# ================================

# --- Setup Logging ---
$ScriptName  = "Server-Mode Power Settings Script"
$Root        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LogDir      = Join-Path $Root "System Core\Logs\$ScriptName"
$TimeStamp   = (Get-Date).ToString("MMMM dd yyyy h-mm-ss tt").Replace(":", "-")

$LogFile     = Join-Path $LogDir "$TimeStamp.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Start-Transcript -Path $LogFile -Append

# --- Header ---
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "   Applying Server-Mode Power Settings" -ForegroundColor Yellow
Write-Host "================================`n" -ForegroundColor Cyan

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Get Active Power Scheme ---
try {
    $schemeGUID = (powercfg /GETACTIVESCHEME) -replace '.*GUID:\s*([a-f0-9-]+).*','$1'
    if (-not $schemeGUID) { throw "Unable to detect active power scheme." }
}
catch {
    Write-Host "[ERROR] Failed to detect power scheme: $_" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Apply Server Settings ---
try {
    Write-Host "[STEP] Disabling display and sleep timeouts..." -ForegroundColor Yellow
    powercfg /change monitor-timeout-ac 0 | Out-Null
    powercfg /change monitor-timeout-dc 0 | Out-Null
    powercfg /change standby-timeout-ac 0 | Out-Null
    powercfg /change standby-timeout-dc 0 | Out-Null

    Write-Host "[STEP] Disabling hibernation..." -ForegroundColor Yellow
    powercfg /change hibernate-timeout-ac 0 | Out-Null
    powercfg /change hibernate-timeout-dc 0 | Out-Null
    powercfg /hibernate off | Out-Null

    Write-Host "[STEP] Setting button and lid actions to 'Do Nothing'..." -ForegroundColor Yellow
    foreach ($key in @("LIDACTION","PBUTTONACTION","SBUTTONACTION")) {
        powercfg /SETACVALUEINDEX $schemeGUID SUB_BUTTONS $key 0 | Out-Null 2>$null
        powercfg /SETDCVALUEINDEX $schemeGUID SUB_BUTTONS $key 0 | Out-Null 2>$null
    }

    powercfg /SETACTIVE $schemeGUID | Out-Null
}
catch {
    Write-Host "[ERROR] Failed to apply settings: $_" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Confirmation ---
Write-Host "[OK] Server mode applied successfully.`n" -ForegroundColor Green

# --- Final Summary ---
Write-Host ("   {0,-25}: {1}" -f "Screen timeout", "Disabled (0 / 0 min)") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Sleep timeout", "Disabled (0 / 0 min)") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Hibernate timeout", "Disabled (0 / 0 min)") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Hibernate feature", "Disabled (file removed)") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Lid close action", "Do nothing") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Power button action", "Do nothing") -ForegroundColor Green
Write-Host ("   {0,-25}: {1}" -f "Sleep button action", "Do nothing") -ForegroundColor Green

Write-Host "`nSystem optimized for continuous uptime and remote operation." -ForegroundColor Yellow

Stop-Transcript
