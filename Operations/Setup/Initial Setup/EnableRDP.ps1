# ================================
# Enable Remote Desktop
# ================================

# --- Setup Logging ---
$ScriptName  = "Enable Remote Desktop Script"
$Root        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LogDir      = Join-Path $Root "System Core\Logs\$ScriptName"
$TimeStamp   = (Get-Date).ToString("MMMM dd yyyy h-mm-ss tt").Replace(":", "-")

$LogFile     = Join-Path $LogDir "$TimeStamp.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Start-Transcript -Path $LogFile -Append

# --- Header ---
Write-Host "================================" -ForegroundColor Cyan
Write-Host "   Configuring Remote Desktop..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan

# --- Apply Settings ---
Write-Host "`n[STEP] Enabling Remote Desktop..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 0 | Out-Null

Write-Host "[STEP] Allowing Remote Desktop through Firewall..." -ForegroundColor Yellow
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null

# --- Verification ---
$rdpEnabled = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
$firewallRule = Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Where-Object { $_.Enabled -eq "True" }

Write-Host "`n[OK] Remote Desktop configuration applied." -ForegroundColor Green
Write-Host "`nSettings:" -ForegroundColor Cyan

if ($rdpEnabled -eq 0) {
    Write-Host "   Remote Desktop connections are enabled" -ForegroundColor Green
} else {
    Write-Host "   Remote Desktop connections are disabled" -ForegroundColor Red
}

if ($firewallRule) {
    Write-Host "   Firewall rule for Remote Desktop is enabled" -ForegroundColor Green
} else {
    Write-Host "   Firewall rule for Remote Desktop is disabled" -ForegroundColor Red
}

Write-Host "`nSystem is ready for Remote Desktop connections." -ForegroundColor Yellow

Stop-Transcript