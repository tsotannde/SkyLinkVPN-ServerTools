# =====================================================
#  VPN Listening Service
# =====================================================

$desktop       = [Environment]::GetFolderPath("Desktop")
$baseDir       = Join-Path $desktop "Operations\Setup\Services\Listening"
$logDir        = Join-Path $desktop "Operations\System Core\Logs\Listening Service"
$configPath    = Join-Path $desktop "Operations\System Core\Device Configuration\DeviceConfig.config"
$assignScript  = Join-Path $baseDir "assign_ip.ps1"
$timestamp     = (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
$logFile       = Join-Path $logDir "ListeningService_$timestamp.log"

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry  = "$timestamp [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log "INFO" "=============================================="
Write-Log "INFO" "   VPN Listening Service Startup (PowerShell)"
Write-Log "INFO" "=============================================="
Write-Log "INFO" "Logs saved at: $logFile"

# === Load Port Config ===
$port = 5000
try {
    if (Test-Path $configPath) {
        Write-Log "INFO" "Reading config: $configPath"
        $configData = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($configData.port) {
            $port = [int]$configData.port
            Write-Log "INFO" "Loaded port: $port"
        }
        else {
            Write-Log "WARN" "Port not found, using default 5000"
        }
    }
    else {
        Write-Log "WARN" "Config not found, using default 5000"
    }
}
catch {
    Write-Log "ERROR" "Failed to read config: $_"
    $port = 5000
}

# === Start HTTP Listener ===
try {
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://*:$port/")
    $listener.Start()
    Write-Log "INFO" "Listening on port $port..."
}
catch {
    Write-Log "FATAL" "Could not start listener: $_"
    exit 1
}

# === Main Loop ===
try {
    while ($true) {
        try {
            $context  = $listener.GetContext()
            $request  = $context.Request
            $response = $context.Response

            Write-Log "INFO" "================= NEW REQUEST ================="
            Write-Log "INFO" "Path: $($request.RawUrl)"

            if ($request.HttpMethod -ne "POST" -or $request.RawUrl -ne "/assign-ip") {
                $response.StatusCode = 404
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Unknown path"}')
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.Close()
                continue
            }

            # Read request body
            $reader = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body   = $reader.ReadToEnd()
            $reader.Close()
            Write-Log "DEBUG" "Body: $body"

            try { $data = $body | ConvertFrom-Json } catch { $data = $null }
            $publicKey = $data.publicKey
            Write-Log "INFO" "PublicKey: $publicKey"

            if (-not $publicKey) {
                $response.StatusCode = 400
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Missing publicKey"}')
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.Close()
                continue
            }

            if (-not (Test-Path $assignScript)) {
                throw "assign_ip.ps1 not found at $assignScript"
            }

            Write-Log "STEP" "Running assign_ip.ps1..."
            $result = powershell -ExecutionPolicy Bypass -File $assignScript $publicKey 2>&1
            Write-Log "DEBUG" "assign_ip.ps1 output:`n$result"

# --- Extract the last JSON object from output ---
$jsonMatch = [regex]::Match($result, '\{(?:[^{}]|(?<open>\{)|(?<-open>\}))*(?(open)(?!))\}$', 'Singleline')

if ($jsonMatch.Success) {
    $jsonText = $jsonMatch.Value.Trim()
    try {
        $null = $jsonText | ConvertFrom-Json -ErrorAction Stop
        $result = $jsonText
        Write-Log "INFO" "Detected and extracted valid JSON from output."
    }
    catch {
        Write-Log "WARN" "Extracted text failed JSON parse: $_"
        $result = (@{ stdout = $result } | ConvertTo-Json -Compress)
    }
}
else {
    Write-Log "WARN" "No JSON detected in assign_ip output; wrapping raw text."
    $result = (@{ stdout = $result } | ConvertTo-Json -Compress)
}
            $response.StatusCode = 200
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($result)
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()

            Write-Log "OK" "Responded to $($context.Request.RemoteEndPoint.Address)"
        }
        catch {
            Write-Log "ERROR" "Inner loop exception: $_"
            try {
                $response.StatusCode = 500
                $errObj = @{ error = $_.Exception.Message }
                $errJson = $errObj | ConvertTo-Json -Compress
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($errJson)
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
                $response.Close()
            }
            catch { }
        }
    }
}
finally {
    $listener.Stop()
    Write-Log "INFO" "Server stopped."
}