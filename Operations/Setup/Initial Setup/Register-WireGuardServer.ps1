# ===============================================
# WireGuard → Firebase Registration 
# Author: Adebayo Sotannde
# ===============================================

# --- Setup Logging ---
$ScriptName  = "WireGuard Firebase Registration Script"
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
Write-Host "   WireGuard Firebase Registration" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Firebase URL ---
$firebaseUrl = "https://vpn-se-default-rtdb.firebaseio.com/"

# --- Inputs ---
$serverName = Read-Host "Enter a Server Name (e.g. NYServer-Windows2025)"
$nickname   = Read-Host "Enter a Nickname (leave blank for auto)"
$country    = Read-Host "Enter Country (e.g. United States)"
$city       = Read-Host "Enter City (e.g. Austin)"
$state      = Read-Host "Enter State or Region (e.g. Texas)"
$port       = Read-Host "Enter Server Port (e.g. 51820)"
$countryRequiresSubscription = Read-Host "Does this country require a subscription? (true/false, y/n, 1/0)"
$requiresSubscription        = Read-Host "Does this server require a subscription? (true/false, y/n, 1/0)"
$capacity        = Read-Host "Enter Server Capacity (e.g. 65534)"
$currentCapacity = Read-Host "Enter Current Active Connections (e.g. 0)"
$allowNewConnection = Read-Host "Allow New Connections? (true/false, y/n, 1/0)"

# --- Normalize booleans ---
function Normalize-Bool {
    param([object]$text, [bool]$default = $false)
    if ($null -eq $text) { return $default }
    $s = ([string]$text).Trim().ToLower()
    switch ($s) {
        { $_ -in @('true','t','yes','y','1') }  { return $true }
        { $_ -in @('false','f','no','n','0') } { return $false }
        default { return $default }
    }
}

$countryRequiresSubscriptionBool = Normalize-Bool $countryRequiresSubscription $false
$requiresSubscriptionBool        = Normalize-Bool $requiresSubscription $false
$allowNewConnectionBool          = Normalize-Bool $allowNewConnection $true

# --- System info ---
Write-Host "`n[INFO] Capturing system information..." -ForegroundColor Cyan
try { $publicIP = Invoke-RestMethod -Uri "https://api.ipify.org?format=text" -TimeoutSec 10 }
catch { $publicIP = "Unknown" }

$osVersion = (Get-CimInstance Win32_OperatingSystem).Caption
$timestamp = (Get-Date).ToString("o")
$location  = "$city, $state, $country"

# --- Server payload ---
$serverData = @{
  name                 = $serverName
  nickname             = $nickname
  location             = $location
  country              = $country
  state                = $state
  city                 = $city
  port                 = [int]$port
  publicIP             = $publicIP
  osVersion            = $osVersion
  requiresSubscription = $requiresSubscriptionBool
  capacity             = [int]$capacity
  currentCapacity      = [int]$currentCapacity
  lastUpdated          = $timestamp
  allowNewConnection   = $allowNewConnectionBool
}

# --- Upload (append-only, safe on empty DB) ---
Write-Host "`n[INFO] Uploading this server to Firebase..." -ForegroundColor Cyan
try {
    $serverUrl = "$firebaseUrl/servers/$country/servers/$serverName.json"
    Invoke-RestMethod -Uri $serverUrl -Method Put -ContentType "application/json" `
        -Body ($serverData | ConvertTo-Json -Depth 10 -Compress)

    $flagUrl = "$firebaseUrl/servers/$country/requiresSubscription.json"
    Invoke-RestMethod -Uri $flagUrl -Method Put -ContentType "application/json" `
        -Body ($countryRequiresSubscriptionBool | ConvertTo-Json)

    Write-Host "[OK] Server uploaded successfully." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Upload failed: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Summary ---
Write-Host "----------------------------------------"
Write-Host "Country: $country"
Write-Host "Country Requires Subscription: $countryRequiresSubscriptionBool"
Write-Host "Server: $serverName"
Write-Host "Nickname: $nickname"
Write-Host "Location: $location"
Write-Host "Port: $port"
Write-Host "Public IP: $publicIP"
Write-Host "Server Requires Subscription: $requiresSubscriptionBool"
Write-Host "Capacity: $capacity"
Write-Host "Current Capacity: $currentCapacity"
Write-Host "Allow New Connection: $allowNewConnectionBool"
Write-Host "Firebase Path: servers/$country/servers/$serverName"
Write-Host "----------------------------------------"

# --- Save Local Device Configuration for Future Use ---
Write-Host "`n[INFO] Saving local device configuration..." -ForegroundColor Cyan

# Resolve Desktop path & System Core directory
$desktopPath = [Environment]::GetFolderPath('Desktop')
$coreDir     = Join-Path $desktopPath "Operations\System Core"
$configDir   = Join-Path $coreDir "Device Configuration"

# Create folder if missing
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "[OK] Created directory: $configDir" -ForegroundColor Green
}

# Define config file path
$configFile = Join-Path $configDir "DeviceConfig.config"

# Build config object
$configData = @{
    serverName     = $serverName
    port           = [int]$port
    publicIP       = $publicIP
    country        = $country
    state          = $state
    city           = $city
    firebasePath   = "servers/$country/servers/$serverName"
}

# Save as JSON
$configData | ConvertTo-Json -Depth 5 | Set-Content -Path $configFile -Encoding UTF8

Write-Host "[OK] Configuration saved at: $configFile" -ForegroundColor Green
Write-Host "[INFO] Future scripts can use this file to identify and update this node automatically." -ForegroundColor Yellow

Stop-Transcript
