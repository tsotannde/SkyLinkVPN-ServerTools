<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20Server-0078D4?style=for-the-badge&logo=windows" />
  <img src="https://img.shields.io/badge/Automation-PowerShell-5391FE?style=for-the-badge&logo=powershell" />
  <img src="https://img.shields.io/badge/Integration-WireGuard-88171A?style=for-the-badge&logo=wireguard" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" />
</p>

<h1 align="center">SkyLinkVPN-ServerTools</h1>
<h3 align="center">⚡ Fully Automated Configuration Toolkit for SkyLinkVPN Windows Servers ⚡</h3>

<p align="center">
Deploy a complete WireGuard-powered VPN node in minutes — fully scripted, zero manual setup.
</p>

---

## ✨ Introduction

**SkyLinkVPN-ServerTools** is a full automation suite that transforms any Windows Server into a fully configured, production-ready WireGuard VPN node.

The toolkit handles:

- Installation  
- Configuration  
- Security hardening  
- NAT + IP forwarding  
- Automatic dynamic IP assigning  
- Firebase server registration  
- Logging + directory setup  

Everything runs automatically.

---

## 🚀 Features

### 🔐 **WireGuard Automation**
| Capability | Description |
|-----------|-------------|
| 🔑 Key Generation | Auto-generate secure private/public pairs |
| 🌐 Smart IP Allocation | Auto-detects available `10.x.x.x` subnets |
| 🔄 Tunnel Generation | No overlapping ports or subnets |
| ⚙️ Service Activation | Runs WG as a service for persistence |
| 🛰 NAT Routing | Automatic outbound routing for clients |

---

### ☁️ **Firebase Integration**
- Registers server under: `servers/{country}/servers/{name}`  
- Stores: IP, port, OS, nickname, capacity, subscription flags  
- Updates country requirement flags  
- Creates local `DeviceConfig.config` for other scripts  

---

### 🛡 **Windows Server Hardening**
- Disable Windows Update  
- Enable RDP  
- Disable sleep + hibernate  
- Configure power plan  
- Create firewall rules dynamically  
- Assign static network (optional)  
- Log all actions to structured folders  

---

## 📂 Directory Structure

Operations/
├── Applications/
│     └── wireguard-amd64.msi
│
├── System Core/
│     ├── Device Configuration/
│     │      └── DeviceConfig.config
│     ├── Logs/
│     │      ├── WireGuard Dynamic Tunnel Generator/
│     │      └── Listening Service/
│     └── Scripts/
│            ├── Activate-WireGuardTunnel.ps1
│            ├── Create-Tunnel.ps1
│            ├── SetupWireGuardNAT.ps1
│            └── …
│
└── Setup/
├── Deploy-WireGuardNode.bat
└── Services/
├── assign_ip.ps1
└── ListeningService.ps1

---

## ▶️ Quick Start

### **1️⃣ Clone the repository**
```bash
git clone https://github.com/tsotnande/SkyLinkVPN-ServerTools.git

2️⃣ Run as Administrator

Deploy-WireGuardNode.bat

3️⃣ Follow the on-screen prompts

The script will configure:
	•	WireGuard
	•	NAT
	•	Tunnels
	•	Device configuration
	•	Server registration
	•	Listener service
	•	Firewall rules

4️⃣ Server is automatically added to Firebase

Clients can now dynamically retrieve the node.

⸻

🔥 High-Level Architecture

                   ┌──────────────────────────┐
                   │ Deploy-WireGuardNode.bat │
                   └───────────────┬──────────┘
                                   ↓
         ┌────────────────────────────────────────────┐
         │ PowerShell Automation Engine               │
         │ • WireGuard install                        │
         │ • NAT setup                                │
         │ • Firewall rules                           │
         │ • System hardening                         │
         │ • Firebase registration                    │
         └───────────────────┬────────────────────────┘
                             ↓
                     ┌─────────────┐
                     │ WireGuard   │
                     └─────────────┘
                             ↓
                     ┌─────────────┐
                     │ Firebase DB │
                     └─────────────┘
                             ↓
                     ┌─────────────┐
                     │ VPN Clients │
                     └─────────────┘


⸻

🧑‍💻 Included Scripts

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

Entrypoint
	•	Deploy-WireGuardNode.bat

⸻

📄 License

MIT License – Free for personal and commercial use.

⸻

✨ Author

Adebayo Sotannde
Creator of SkyLinkVPN Server Automation Stack
