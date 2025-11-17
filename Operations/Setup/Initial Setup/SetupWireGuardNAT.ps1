# ===============================================
# WireGuard Auto-NAT Configurator
# Author: Adebayo Sotannde
# Enables IP forwarding and configures NAT for WireGuard interfaces
# ===============================================

# --- Setup Logging ---
$ScriptName  = "WireGuard Auto-NAT Configurator Script"
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
Write-Host "   WireGuard Auto-NAT Configurator" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Enable IP forwarding ---
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
        -Name "IPEnableRouter" -Value 1 -ErrorAction Stop
    Write-Host "[OK] IP forwarding enabled." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to enable IP forwarding: $($_.Exception.Message)" -ForegroundColor Red
}

# --- Get all adapters with IPv4 addresses ---
$allAdapters = Get-NetIPConfiguration | Where-Object { $_.IPv4Address }

if (-not $allAdapters) {
    Write-Host "[INFO] No active interfaces with IPv4 addresses found." -ForegroundColor Red
    Stop-Transcript
    exit 0
}

foreach ($adapter in $allAdapters) {

    $alias  = $adapter.InterfaceAlias
    $ipObj  = $adapter.IPv4Address
    $ip     = $ipObj.IPAddress
    $prefix = $ipObj.PrefixLength

    # --- Detect if adapter is WireGuard/VPN by alias or IP range ---
    $isWG = (
        $alias -match "WireGuard" -or
        $alias -match "VPN" -or
        $alias -match "Tunnel" -or
        $alias -match "ADMIN" -or
        $alias -match "CLIENT" -or
        $alias -match "USER" -or
        ($ip -match '^10\.\d+\.\d+\.\d+$')   # Detect any 10.x.x.x address
    )

    if ($isWG) {

        $subnet  = ($ip -replace '\d+$','0') + "/" + $prefix
        $natName = ($alias -replace '[^A-Za-z0-9_-]','_')

        Write-Host ""
        Write-Host ("[MATCH] Configuring NAT for {0} ({1}/{2})..." -f $alias, $ip, $prefix) -ForegroundColor Cyan

        # --- Remove any existing NAT with same name ---
        $existingNat = Get-NetNat -Name $natName -ErrorAction SilentlyContinue
        if ($existingNat) {
            Write-Host ("  Existing NAT '{0}' found - removing first..." -f $natName) -ForegroundColor Yellow
            try {
                Remove-NetNat -Name $natName -Confirm:$false -ErrorAction Stop
                Start-Sleep -Milliseconds 300
            } catch {
                Write-Host ("  [WARN] Could not remove existing NAT '{0}': {1}" -f $natName, $_.Exception.Message) -ForegroundColor DarkYellow
            }
        }

        # --- Create new NAT ---
        try {
            New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $subnet | Out-Null
            Write-Host ("  [OK] NAT rule '{0}' active for {1}" -f $natName, $subnet) -ForegroundColor Green
        }
        catch {
            Write-Host ("  [ERROR] Failed to create NAT for {0}: {1}" -f $alias, $_.Exception.Message) -ForegroundColor Red
        }

    }
    else {
        Write-Host ("[SKIP] Non-WireGuard interface: {0} ({1})" -f $alias, $ip) -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Yellow
Write-Host "   NAT setup complete." -ForegroundColor Green
Write-Host "================================" -ForegroundColor Yellow

# --- Display all active NAT rules ---
Get-NetNat | Format-Table -AutoSize

Stop-Transcript
