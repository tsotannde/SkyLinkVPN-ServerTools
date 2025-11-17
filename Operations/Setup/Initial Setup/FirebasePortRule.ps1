# ===============================================
# Firebase Listener Port Configurator (Dynamic Port Version)
# Author: Adebayo Sotannde
# ===============================================

# --- Setup Logging ---
$ScriptName  = "Firebase Listener Port Configurator Script"
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
Write-Host "   Firebase Listener Port Configurator" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Load Config File ---
$configPath = "C:\Users\Administrator\Desktop\Operations\System Core\Device Configuration\DeviceConfig.config"

if (!(Test-Path $configPath)) {
    Write-Host "[ERROR] Config file not found at $configPath" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

try {
    $configContent = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $port = $configContent.port
    if (-not $port) {
        throw "Port value missing in config file."
    }
    Write-Host ("[INFO] Loaded port {0} from config file." -f $port) -ForegroundColor Yellow
} catch {
    Write-Host ("[ERROR] Failed to parse config file: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Stop-Transcript
    exit 1
}

$ruleName = "Firebase Listener Port $port"

# --- Check existing firewall rules ---
Write-Host "[INFO] Checking existing firewall rules..." -ForegroundColor Yellow
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

# --- Remove existing rule if found ---
if ($existingRule) {
    Write-Host ("[MATCH] Existing rule '{0}' found - removing first..." -f $ruleName) -ForegroundColor Yellow
    try {
        Remove-NetFirewallRule -DisplayName $ruleName -Confirm:$false -ErrorAction Stop
    } catch {
        Write-Host ("[WARN] Could not remove existing rule: {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
}

# --- Create new rule for dynamic port ---
try {
    Write-Host ("[ACTION] Creating inbound rule for TCP port {0}..." -f $port) -ForegroundColor Cyan
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $port `
        -Action Allow `
        -Profile Any | Out-Null

    Write-Host ("[OK] Firewall rule '{0}' active for TCP port {1}" -f $ruleName, $port) -ForegroundColor Green
}
catch {
    Write-Host ("[ERROR] Failed to create firewall rule for port {0}: {1}" -f $port, $_.Exception.Message) -ForegroundColor Red
    Stop-Transcript
    exit 1
}

# --- Summary ---
Write-Host ""
Write-Host "================================" -ForegroundColor Yellow
Write-Host "   Firewall configuration complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow

# --- Display matching rules for verification ---
Get-NetFirewallRule | Where-Object { $_.DisplayName -match "Firebase" } | Format-Table -AutoSize

Stop-Transcript