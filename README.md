<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows_Server-0078D4?style=for-the-badge&logo=windows" />
  <img src="https://img.shields.io/badge/PowerShell-Automation-5391FE?style=for-the-badge&logo=powershell" />
  <img src="https://img.shields.io/badge/WireGuard-Integration-88171A?style=for-the-badge&logo=wireguard" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

# **SkyLinkVPN-ServerTools – One-Click Automatic Configuration Toolkit for SkyLinkVPN Windows Servers**

SkyLinkVPN-ServerTools is a fully automated provisioning system designed to turn any Windows Server into a complete WireGuard VPN node — with zero manual setup.

From installation → configuration → NAT → tunnel creation → Firebase registration → listener service → hardening…
The entire server builds itself.

⸻

🚀 Overview

This toolkit:
	•	Installs WireGuard
	•	Generates secure tunnels
	•	Configures NAT + IP forwarding
	•	Assigns dynamic client IPs
	•	Registers server metadata to Firebase
	•	Applies Windows hardening
	•	Opens firewall rules
	•	Enables RDP
	•	Sets persistent power mode (never sleep)
	•	Disables Windows Update
	•	Builds a consistent directory structure
	•	Logs every operation automatically

Everything is repeatable, deterministic, and production-ready.

⸻

🔧 Key Features

🛡 WireGuard Automation

Feature	Description
🔑 Key Generation	Auto-generate private/public key pairs
🌐 IP Allocation	Smart 10.x.x.x subnet detection
🔄 Dynamic Tunnel Creation	No overlap with existing tunnels
🟢 Service Activation	Auto-start each tunnel using WG Service mode
📡 NAT + Forwarding	Supports client routing out to the internet


⸻

☁️ Firebase Integration
	•	Registers server under country hierarchy
	•	Sends metadata (IP, port, OS, nickname, location, capacity)
	•	Syncs server availability
	•	Saves a local JSON config for other scripts to reference

⸻

⚙️ Windows System Configuration
	•	Disable system updates
	•	Enable Remote Desktop
	•	Apply server-mode power config
	•	Configure static IP (optional)
	•	Create Windows firewall rules automatically
	•	Full logging for every command executed

⸻

📂 Directory Layout

Operations/
├── Applications/
│     └── wireguard-amd64.msi
│
├── System Core/
│     ├── Device Configuration/
│     │      └── DeviceConfig.config
│     ├── Logs/
│     │      └── (auto-generated logs...)
│     └── Scripts/
│            └── (PowerShell scripts)
│
└── Setup/
       ├── Deploy-WireGuardNode.bat
       └── Services/
             └── assign_ip.ps1
             └── ListeningService.ps1


⸻

▶️ Quick Start

1. Download repository

git clone https://github.com/tsotnande/SkyLinkVPN-ServerTools.git

2. Run as Administrator

Deploy-WireGuardNode.bat

3. Answer prompts
	•	Server Name
	•	Country
	•	City
	•	Port
	•	Subscription flags
	•	Capacity

4. Server registers itself in Firebase

5. Node appears in the SkyLinkVPN platform

Done — your server is now a live VPN node.

⸻

Architecture Diagram

              ┌────────────────────────────┐
              │ Deploy-WireGuardNode.bat   │
              └──────────────┬─────────────┘
                             ↓
      ┌──────────────────────────────────────────────┐
      │ PowerShell Automation Stack                  │
      │ - WG Install                                 │
      │ - NAT Setup                                  │
      │ - IP Assignment Service                      │
      │ - Firebase Sync                              │
      │ - Power/Firewall/RDP Configuration           │
      └───────────────────┬──────────────────────────┘
                          ↓
                ┌───────────────────────┐
                │ WireGuard Interfaces  │
                └───────────────────────┘
                          ↓
                ┌───────────────────────┐
                │ Firebase Database     │
                └───────────────────────┘
                          ↓
                ┌───────────────────────┐
                │  SkyLinkVPN Clients   │
                └───────────────────────┘


⸻

🛠 Included Tools

WireGuard
	•	Create-Tunnel.ps1
	•	Activate-WireGuardTunnel.ps1
	•	SetupWireGuardNAT.ps1
	•	InstallWireGuard.ps1

System Config
	•	DisableUpdate.ps1
	•	EnableRDP.ps1
	•	PreventSleep.ps1
	•	AssignStaticNetwork.ps1

Firebase / Listener
	•	Register-WireGuardServer.ps1
	•	FirebasePortRule.ps1
	•	assign_ip.ps1
	•	ListeningService.ps1

Entry Point
	•	Deploy-WireGuardNode.bat

⸻

🧑‍💻 Developer Notes

This toolchain was designed for:
	•	Performance
	•	Scalability
	•	Reproducible provisioning
	•	Minimal user input
	•	Windows Server compatibility

Ideal for building large-scale global VPN infrastructure.

⸻

📄 License

MIT © 2025 Adebayo Sotannde
Use it, sell it, fork it, love it.

⸻

✨ Author

Adebayo Sotannde
Creator of SkyLinkVPN Server Automation Stack.
