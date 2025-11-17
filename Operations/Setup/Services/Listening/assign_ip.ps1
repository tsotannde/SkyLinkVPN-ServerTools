param(
    [Parameter(Mandatory = $true)][string]$PublicKey
)

# =====================================================
#  CONFIG
# =====================================================
$WGPath  = "C:\Program Files\WireGuard\wg.exe"
$Desktop = [Environment]::GetFolderPath("Desktop")
$LogDir  = "$Desktop\Operations\System Core\Logs\Listening Service"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile   = "$LogDir\assign_ip_$TimeStamp.log"

# =====================================================
#  LOGGING
# =====================================================
function Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $entry
    Add-Content -Path $LogFile -Value $entry
}

Log "================ ASSIGN_IP START ================"
Log "[STEP 1] Received public key: $PublicKey"

if (!(Test-Path $WGPath)) {
    Log "[ERROR] WireGuard not found at $WGPath"
    exit 1
}

# =====================================================
#  STEP 2: DETECT VALID WG INTERFACE
# =====================================================
$tunnelsRaw = & $WGPath show interfaces 2>$null
if ([string]::IsNullOrWhiteSpace($tunnelsRaw)) {
    Log "[ERROR] No active WireGuard interfaces found"
    exit 1
}

# Clean interface names (handle "interface: NAME" variants)
$tunnels = @()
foreach ($line in ($tunnelsRaw -split "[`r`n]+")) {
    $line = $line.Trim()
    if ($line -match "^interface:\s*(.+)$") { $tunnels += $Matches[1].Trim() }
    elseif ($line -ne "") { $tunnels += $line }
}
$tunnel = $tunnels[0]
Log "[STEP 2] Active WG interface detected: $tunnel"

# =====================================================
#  STEP 3: GATHER INTERFACE INFO
# =====================================================
$info = & $WGPath show $tunnel 2>$null
Log "[DEBUG] wg show output:`n$info"

# Use regex matches explicitly to avoid $matches reuse surprises
$portMatch = [regex]::Match($info, "listening port:\s*(\d+)", 'IgnoreCase')
$keyMatch  = [regex]::Match($info, "public key:\s*([A-Za-z0-9+/=]+)", 'IgnoreCase')

$listenPort   = if ($portMatch.Success) { [int]$portMatch.Groups[1].Value } else { 51820 }
$tunnelPubKey = if ($keyMatch.Success)  {        $keyMatch.Groups[1].Value } else { "unknown" }

Log "[INFO] Listen port: $listenPort"
Log "[INFO] Server public key: $tunnelPubKey"

# =====================================================
#  STEP 4: DETECT SUBNET
# =====================================================
$baseSubnet = "10.0.0"
try {
    $iface = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq $tunnel }
    if ($iface) {
        $ip = $iface.IPAddress
        $octets = $ip.Split('.')
        if ($octets.Length -ge 3) {
            $baseSubnet = "$($octets[0]).$($octets[1]).$($octets[2])"
        }
        # IMPORTANT: avoid colon right after variable name
        Log ("[INFO] Detected base subnet from {0}: {1}" -f $tunnel, $baseSubnet)
    } else {
        Log "[WARN] No IP found on interface; fallback to $baseSubnet"
    }
}
catch {
    Log "[WARN] Subnet detection failed: $($_.Exception.Message)"
}

# =====================================================
#  STEP 5: EXISTING PEER IPS
# =====================================================
$existingIPs = @()
$ipMatches = [regex]::Matches($info, "allowed ips:\s*([\d\.]+)/32", 'IgnoreCase')
if ($ipMatches.Count -gt 0) {
    $existingIPs = $ipMatches | ForEach-Object { $_.Groups[1].Value }
}
Log "[INFO] Existing peer IPs: $($existingIPs -join ', ')"

# =====================================================
#  STEP 6: GENERATE UNIQUE IP
# =====================================================
Log "[STEP 6] Generating unique IP..."
$newIP = $null
for ($i = 0; $i -lt 500; $i++) {
    $last = Get-Random -Minimum 2 -Maximum 254
    $candidate = "$baseSubnet.$last"
    if ($existingIPs -notcontains $candidate) {
        $newIP = $candidate
        break
    }
}
if (-not $newIP) {
    $newIP = "$baseSubnet.99"
    Log "[WARN] Could not find unique IP; using fallback $newIP"
}
Log "[INFO] Selected IP: $newIP"

# =====================================================
#  STEP 7: ADD PEER
# =====================================================
Log "[STEP 7] Adding peer to $tunnel..."
try {
    $args = @("set", $tunnel, "peer", $PublicKey, "allowed-ips", "$newIP/32", "persistent-keepalive", "25")
    $proc = Start-Process -FilePath $WGPath -ArgumentList $args `
        -NoNewWindow -RedirectStandardOutput "$LogFile.tmp" -RedirectStandardError "$LogFile.err" `
        -PassThru -Wait
    $stderr = Get-Content "$LogFile.err" -Raw -ErrorAction SilentlyContinue
    if ($proc.ExitCode -eq 0) {
        Log "[CMD-OK] Peer added successfully"
    } else {
        Log "[CMD-FAIL] Exit code: $($proc.ExitCode)"
        Log "[STDERR] $stderr"
    }
} catch {
    Log "[ERROR] WireGuard command failed: $($_.Exception.Message)"
}

# =====================================================
#  STEP 8: FINAL JSON OUTPUT
# =====================================================
$result = @{
    port            = $listenPort
    serverPublicKey = $tunnelPubKey
    assignedIP      = $newIP
}

Log "[STEP 8] Final JSON result:`n$(($result | ConvertTo-Json -Depth 3))"
Log "================ ASSIGN_IP END ================"

$result | ConvertTo-Json -Compress
exit