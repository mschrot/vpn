🚀 VPN + DNS Stack (AdGuard + WireGuard) auf Ubuntu 22.04

Dieses Projekt stellt eine einfache Möglichkeit bereit, einen sicheren VPN-Server (WireGuard) mit integriertem DNS-Filter (AdGuard Home) auf Ubuntu zu betreiben – komplett containerisiert mit Docker.

--------------------------------------------------

📦 Features

- 🔐 WireGuard VPN (wg-easy WebUI)
- 🛡️ AdGuard Home (DNS-Filter + Tracking-Schutz)
- 🐳 Docker + Portainer Verwaltung
- 🌐 Eigenes Netzwerk (10.10.0.0/24)
- ⚡ Schnelle Installation

--------------------------------------------------

🧰 Voraussetzungen

- Ubuntu 22.04 Server
- Root oder sudo Zugriff
- Öffentliche IP oder Domain
- Firewall korrekt konfiguriert

--------------------------------------------------

🔥 Firewall Ports

TCP:
9000, 81, 3000, 51821

UDP:
53, 51820

--------------------------------------------------

⚙️ Installation

1. Repository klonen:
git clone <dein-repo>
cd <dein-repo>

2. Installationsskript:
chmod +x install_docker_portainer.sh
sudo ./install_docker_portainer.sh

3. Stack über Portainer deployen

--------------------------------------------------

🌐 Zugriff

Portainer:
https://SERVER-IP:9443
http://SERVER-IP:9000

AdGuard:
http://SERVER-IP:81

WireGuard:
http://SERVER-IP:51821

--------------------------------------------------

⚠️ Wichtige Einstellungen

WG_HOST=DEINE_SERVER_IP
PASSWORD=SICHERES_PASSWORT

--------------------------------------------------

🔒 Sicherheit

- Passwort > 12 Zeichen
- Admin-Zugriff nur eigene IP
- SSH nur mit Key
- Regelmäßige Updates

--------------------------------------------------

🌍 Netzwerk

AdGuard:   10.10.0.2
WireGuard: 10.10.0.3

--------------------------------------------------

🧪 Funktionsweise

Client → WireGuard → AdGuard → Internet

--------------------------------------------------

🛠️ Befehle

docker ps
docker logs wireguard
docker logs adguardhome

--------------------------------------------------

🔗 Links

WireGuard Install:
https://www.wireguard.com/install/

Projekt:
https://github.com/mschrot/vpn

YouTube:
https://www.youtube.com/@mschrot

--------------------------------------------------

📌 Credits

Erstellt von Michael Schrot

--------------------------------------------------
❤️ Support

⭐ Repo liken & teilen
