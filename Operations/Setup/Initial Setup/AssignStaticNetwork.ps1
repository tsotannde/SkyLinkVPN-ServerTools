# ================================
# Set-EthernetConfig.ps1 
# Author: Adebayo Sotannde
# ================================

# --- Setup Logging ---
$ScriptName  = "Set-EthernetConfig Script"
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
Write-Host "   Ethernet Configuration Tool"
Write-Host "================================" -ForegroundColor Cyan

# ---- Admin check ----
$isAdmin = ([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Host "[ERROR] Run this script as Administrator." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# ---- Find the first active Ethernet adapter ----
$ethernet = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -match "Ethernet" } | Select-Object -First 1
if (-not $ethernet) {
    Write-Host "[WARNING] No active Ethernet adapter found." -ForegroundColor Yellow
    Get-NetAdapter | Select Name, Status, InterfaceDescription
    Stop-Transcript
    exit 0
}

Write-Host "[INFO] Using adapter: $($ethernet.Name)" -ForegroundColor Cyan

# ---- Pull current network info ----
$cfg = Get-NetIPConfiguration -InterfaceIndex $ethernet.ifIndex
$currentIP      = $cfg.IPv4Address.IPAddress
$currentGateway = if ($cfg.IPv4DefaultGateway) { $cfg.IPv4DefaultGateway.NextHop } else { "" }

Write-Host "`n[Current Network Info]" -ForegroundColor Green
Write-Host "   Adapter : $($ethernet.Name)"
Write-Host "   IP      : $currentIP"
Write-Host "   Gateway : $currentGateway"
Write-Host "   DNS     : $($cfg.DnsServer.ServerAddresses -join ', ')`n"

# ---- Ask user whether to assign static IP ----
$choice = Read-Host "Do you want to assign a static IP address? (Y/N)"
if ($choice -notin @("Y", "y")) {
    Write-Host "[INFO] Skipping static IP configuration." -ForegroundColor Yellow
    Write-Host "This is fine for AWS, VPS, or DHCP-based networks.`n" -ForegroundColor Gray
    Stop-Transcript
    exit 0
}

# ---- Proceed with static IP setup ----
$gateway = $cfg.IPv4DefaultGateway.NextHop
if (-not $gateway) {
    Write-Host "[ERROR] No default gateway detected; cannot derive prefix." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# ---- Derive subnet and prompt user for last octet ----
$prefix = ($gateway -split '\.')[0..2] -join '.'
Write-Host "`nDetected subnet: $prefix.*" -ForegroundColor Cyan
$lastOctet = Read-Host "Enter the last octet for your desired IP (e.g., 54 for $prefix.54)"
if (-not ($lastOctet -match '^\d{1,3}$') -or [int]$lastOctet -gt 254) {
    Write-Host "[ERROR] Invalid entry. Must be a number between 1 and 254." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

$newIP  = "$prefix.$lastOctet"
$dns    = @("8.8.8.8","1.1.1.1")

Write-Host "`n[INFO] Gateway detected : $gateway"
Write-Host "[INFO] Target IP address: $newIP`n"

# ---- Compare current vs target ----
if ($currentIP -ne $newIP -or $currentGateway -ne $gateway) {
    Write-Host "[ACTION] Updating network configuration..." -ForegroundColor Yellow

    # Remove old settings
    Get-NetIPAddress -InterfaceIndex $ethernet.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Get-NetRoute -InterfaceIndex $ethernet.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    # Apply new config
    try {
        New-NetIPAddress -InterfaceIndex $ethernet.ifIndex -IPAddress $newIP -PrefixLength 24 -DefaultGateway $gateway -ErrorAction Stop | Out-Null
        Set-DnsClientServerAddress -InterfaceIndex $ethernet.ifIndex -ServerAddresses $dns
        Set-NetIPInterface -InterfaceIndex $ethernet.ifIndex -InterfaceMetric 5
        Start-Sleep -Seconds 2
        Write-Host "[OK] Ethernet reconfigured." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to apply new IP configuration: $_" -ForegroundColor Red
        Stop-Transcript
        exit 1
    }
} else {
    Write-Host "[OK] Ethernet already matches desired config." -ForegroundColor Green
}

# ---- Display final result ----
$cfg = Get-NetIPConfiguration -InterfaceIndex $ethernet.ifIndex
Write-Host "`n[Final Ethernet Status]" -ForegroundColor Green
Write-Host "   Adapter : $($ethernet.Name)"
Write-Host "   IP      : $($cfg.IPv4Address.IPAddress)"
Write-Host "   Gateway : $($cfg.IPv4DefaultGateway.NextHop)"
Write-Host "   DNS     : $($cfg.DnsServer.ServerAddresses -join ', ')"
Write-Host "`nDone.`n" -ForegroundColor Cyan

Stop-Transcript
