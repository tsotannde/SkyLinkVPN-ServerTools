# ===============================
# Disable All Windows Updates
# ===============================

Write-Host "[INFO] Disabling Windows Update services and policies..." -ForegroundColor Cyan

# --- Logging setup ---
$ScriptName  = "Disable Windows Update Script"
$Root        = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LogDir      = Join-Path $Root "System Core\Logs\$ScriptName"
$TimeStamp   = (Get-Date).ToString("MMMM dd yyyy h-mm-ss tt").Replace(":", "-")

$LogFile     = Join-Path $LogDir "$TimeStamp.log"

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Start-Transcript -Path $LogFile -Append

# 1. Stop and disable core update services
$services = @(
    "wuauserv",       # Windows Update
    "bits",           # Background Intelligent Transfer Service
    "dosvc",          # Delivery Optimization
    "UsoSvc",         # Update Orchestrator Service
    "WaaSMedicSvc"    # Windows Update Medic Service
)

foreach ($svc in $services) {
    Write-Host "Stopping $svc..." -ForegroundColor Yellow
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Write-Host "Disabling $svc..." -ForegroundColor Yellow
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# 2. Disable scheduled tasks related to updates
Write-Host "Disabling scheduled update tasks..." -ForegroundColor Cyan
$tasks = @(
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task",
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask",
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker",
    "\Microsoft\Windows\UpdateOrchestrator\Reboot",
    "\Microsoft\Windows\WindowsUpdate\Automatic App Update",
    "\Microsoft\Windows\WindowsUpdate\sih",
    "\Microsoft\Windows\WindowsUpdate\sihboot"
)
foreach ($task in $tasks) {
    schtasks /Change /TN $task /Disable 2>$null
}

# 3. Apply Group Policy registry overrides
Write-Host "Applying policy overrides..." -ForegroundColor Cyan
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "AUOptions" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1 -Type DWord

# 4. Disable Windows Update through local policy (optional fallback)
Write-Host "Blocking access to Windows Update servers..." -ForegroundColor Cyan
New-Item -Path "HKLM:\SYSTEM\Internet Communication Management\Internet Communication" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\Internet Communication Management\Internet Communication" `
    -Name "DisableWindowsUpdateAccess" -Value 1 -Type DWord

# 5. Optional: block update URLs via hosts file
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "`n# Block Windows Update`n0.0.0.0 windowsupdate.microsoft.com`n0.0.0.0 update.microsoft.com`n0.0.0.0 download.windowsupdate.com`n0.0.0.0 windowsupdate.com"

Write-Host "`nWindows Updates fully disabled. Reboot recommended." -ForegroundColor Green
Stop-Transcript