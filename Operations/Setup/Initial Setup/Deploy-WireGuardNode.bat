@echo off
:: ===============================================
::   WireGuard Server Setup Automation
::   Author: Adebayo Sotannde
::   Description: Automates setup and registration
:: ===============================================

setlocal
set "scriptdir=%~dp0"

echo ==============================================
echo   WireGuard Automated Setup
echo ==============================================
echo.

:: Step 1 - Register Server
echo [STEP 1] Registering Server with Firebase...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%Register-WireGuardServer.ps1"

:: Step 2 - Disable Windows Updates
echo [STEP 2] Disable Windows Updates...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%DisableUpdate.ps1"

:: Step 3 - Enable Remote Desktop
echo [STEP 3] Enabling Remote Desktop...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%EnableRDP.ps1"

:: Step 4 - Apply Server Power Settings
echo [STEP 4] Configuring Power Settings...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%PreventSleep.ps1"

:: Step 5 - Configure Static Network
echo [STEP 5] Configuring Static Network...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%AssignStaticNetwork.ps1"

:: Step 6 - Install WireGuard
echo [STEP 6] Installing WireGuard...
::PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%InstallWireGuard.ps1"

:: Step 7 - Create Client Tunnel
echo [STEP 7] Creating WireGuard Tunnels...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%Create-Tunnel.ps1"

:: Step 8 - Activate Tunnels
echo [STEP 8] Activating WireGuard Tunnels...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%Activate-WireGuardTunnel.ps1"

:: Step 9 - Configure WireGuard NAT
echo [STEP 9] Configuring WireGuard NAT...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%SetupWireGuardNAT.ps1"

:: Step 10 - Allowing Imbount Trafffic on Port X
echo [STEP 10] Opening Port X...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%scriptdir%FirebasePortRule.ps1"



echo.
echo ==============================================
echo   Setup Complete!
echo   Deploy-WireGuardNode.bat Ran Sucessfully
echo ==============================================

pause
endlocal
