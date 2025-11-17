# ===============================================
# WireGuard Dynamic Tunnel Generator
# Author: Adebayo Sotannde
# Creates unique tunnel configs in Desktop\Operations\System Core\Tunnels
# ===============================================

# --- Setup Logging ---
$ScriptName  = "WireGuard Dynamic Tunnel Generator Script"
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
Write-Host "   WireGuard Dynamic Tunnel Generator" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Yellow

# --- Detect user's Desktop dynamically ---
$desktopPath   = [Environment]::GetFolderPath('Desktop')
$operationsDir = Join-Path $desktopPath "Operations"
$coreDir       = Join-Path $operationsDir "System Core"
$tunnelDir     = Join-Path $coreDir "Tunnels"
$wgPath        = "C:\Program Files\WireGuard\wg.exe"

# --- Ensure required directories exist ---
foreach ($dir in @($operationsDir, $coreDir, $tunnelDir)) {
    if (-not (Test-Path $dir)) {
        Write-Host "[INFO] Creating directory: $dir" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ================================
# Helper Functions
# ================================

function Get-RandomName {
    try {
        $url = "https://random-word-api.herokuapp.com/word?number=1"
        $word = (Invoke-RestMethod -Uri $url -TimeoutSec 5)[0]
        if ($word -match "^[a-zA-Z0-9]+$") {
            return "Tunnel-$($word.Substring(0,[Math]::Min(8,$word.Length)))"
        }
    } catch {
        $letters = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_})
        return "Tunnel-$letters"
    }
}

function Get-UsedPorts {
    $usedPorts = @()
    if (Test-Path $tunnelDir) {
        Get-ChildItem $tunnelDir -Filter *.conf | ForEach-Object {
            $content = Get-Content $_.FullName -ErrorAction SilentlyContinue
            foreach ($line in $content) {
                if ($line -match "ListenPort\s*=\s*(\d+)") {
                    $usedPorts += [int]$matches[1]
                }
            }
        }
    }
    return $usedPorts
}

function Get-UsedIPs {
    $usedSubnets = @()
    if (Test-Path $tunnelDir) {
        Get-ChildItem $tunnelDir -Filter *.conf | ForEach-Object {
            $content = Get-Content $_.FullName -ErrorAction SilentlyContinue
            foreach ($line in $content) {
                if ($line -match "Address\s*=\s*([\d\.\/]+)") {
                    $ip = $matches[1]
                    if ($ip -match '^10\.(\d+)\.') {
                        $usedSubnets += [int]$matches[1]
                    }
                }
            }
        }
    }
    return $usedSubnets
}

function Get-UniquePort {
    param([int]$min = 51820, [int]$max = 51900)
    $usedPorts = Get-UsedPorts
    $available = ($min..$max) | Where-Object { $_ -notin $usedPorts }
    if ($available.Count -eq 0) {
        throw "No available ports in range $min-$max."
    }
    return (Get-Random -InputObject $available)
}

function Get-UniqueIP {
    $usedSubnets = Get-UsedIPs
    for ($x = 1; $x -lt 255; $x++) {
        if ($x -notin $usedSubnets) {
            return "10.$x.0.1/16"
        }
    }
    throw "No available subnets in 10.X.0.0/16 range."
}

function Create-Tunnel {
    param($Name, $IP, $Port)

    $configFile = Join-Path $tunnelDir "$Name.conf"

    Write-Host "INFO - Generating keys for $Name..." -ForegroundColor Cyan
    $PrivateKey = & $wgPath genkey
    $PublicKey  = $PrivateKey | & $wgPath pubkey

@"
# ==========================================
# Tunnel: $Name
# PublicKey : $PublicKey
# ==========================================

[Interface]
PrivateKey = $PrivateKey
Address = $IP
ListenPort = $Port
"@ | Out-File -FilePath $configFile -Encoding ascii -Force

    Write-Host ("OK - Created config file -> " + $configFile) -ForegroundColor Green
    Write-Host ("  Name  : " + $Name)
    Write-Host ("  IP    : " + $IP)
    Write-Host ("  Port  : " + $Port)
    Write-Host ("  PublicKey : " + $PublicKey)
    Write-Host "----------------------------------------`n"
}

# ================================
# Main Execution
# ================================

Write-Host "[INFO] Checking for existing tunnels..." -ForegroundColor Cyan

# === Name Selection ===
while ($true) {
    $inputName = Read-Host "Enter tunnel name (press Enter to auto-generate)"
    if ([string]::IsNullOrWhiteSpace($inputName)) {
        $tunnelName = Get-RandomName
        Write-Host "[AUTO] Generated tunnel name: $tunnelName" -ForegroundColor Yellow
    } else {
        $tunnelName = $inputName
    }

    $configFile = Join-Path $tunnelDir "$tunnelName.conf"
    if (-not (Test-Path $configFile)) { break }
    Write-Host "[WARN] Tunnel '$tunnelName' already exists. Please choose another name." -ForegroundColor Red
}

# === IP Selection ===
$usedSubnets = Get-UsedIPs
while ($true) {
    $inputIP = Read-Host "Enter tunnel IP (press Enter to auto-assign)"
    if ([string]::IsNullOrWhiteSpace($inputIP)) {
        $tunnelIP = Get-UniqueIP
        Write-Host "[AUTO] Assigned IP: $tunnelIP" -ForegroundColor Yellow
    } else {
        $tunnelIP = $inputIP
    }

    if ($tunnelIP -match '^10\.(\d+)\.') {
        $subnetNum = [int]$matches[1]
    } else {
        $subnetNum = -1
    }

    if ($subnetNum -notin $usedSubnets) { break }
    Write-Host "[WARN] Subnet $subnetNum already in use. Please choose another." -ForegroundColor Red
}

# === Port Selection ===
$usedPorts = Get-UsedPorts
while ($true) {
    $inputPort = Read-Host "Enter tunnel port (press Enter to auto-assign)"
    if ([string]::IsNullOrWhiteSpace($inputPort)) {
        $tunnelPort = Get-UniquePort
        Write-Host "[AUTO] Assigned port: $tunnelPort" -ForegroundColor Yellow
    } elseif ($inputPort -as [int]) {
        $tunnelPort = [int]$inputPort
    } else {
        Write-Host "[WARN] Invalid port format. Please try again." -ForegroundColor Red
        continue
    }

    if ($tunnelPort -notin $usedPorts) { break }
    Write-Host "[WARN] Port $tunnelPort already in use. Please choose another." -ForegroundColor Red
}

# === Create Tunnel ===
Create-Tunnel -Name $tunnelName -IP $tunnelIP -Port $tunnelPort

Write-Host ""
Write-Host "================================" -ForegroundColor Yellow
Write-Host " Tunnel generation complete." -ForegroundColor Green
Write-Host ("Config saved to: " + $tunnelDir) -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Yellow

Stop-Transcript
