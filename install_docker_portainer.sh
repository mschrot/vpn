#!/bin/bash

# Docker und Portainer Installationsskript für Ubuntu Server 24.04
# Ausführen mit: chmod +x install.sh && sudo ./install.sh

set -e
set -u

# Farben
ROT='\033[0;31m'
GRUEN='\033[0;32m'
GELB='\033[1;33m'
BLAU='\033[0;34m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GRUEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${GELB}[WARNUNG]${NC} $1"; }
log_error() { echo -e "${ROT}[FEHLER]${NC} $1"; }
log_step() { echo -e "${BLAU}[SCHRITT]${NC} $1"; }

# Benutzer ermitteln
if [[ $SUDO_USER ]]; then
    ECHTER_BENUTZER=$SUDO_USER
else
    ECHTER_BENUTZER=$(whoami)
fi

if [[ "$ECHTER_BENUTZER" == "root" ]]; then
    BENUTZER_HOME="/root"
else
    BENUTZER_HOME="/home/$ECHTER_BENUTZER"
fi

echo ""
echo "============================================"
echo -e "${BLAU}Docker und Portainer Installationsskript${NC}"
echo "============================================"
echo ""
log_info "Installation für Benutzer: $ECHTER_BENUTZER"
log_info "Home: $BENUTZER_HOME"
echo ""

# Systemupdate
log_step "System aktualisieren..."
apt update && apt upgrade -y

# Pakete installieren
log_step "Installiere benötigte Pakete..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ufw \
    wget \
    git

# ================================
# DNS KONFIGURATION (OPTIONAL)
# ================================
log_step "Konfiguriere DNS (Cloudflare + Google)..."

if systemctl is-active --quiet systemd-resolved; then
    log_warn "systemd-resolved ist aktiv – wird deaktiviert (kann Netzwerk beeinflussen!)"
fi

# Backup
if [[ -f /etc/resolv.conf ]]; then
    cp /etc/resolv.conf /etc/resolv.conf.backup
    log_info "Backup erstellt: /etc/resolv.conf.backup"
fi

# Dienst deaktivieren
systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true

# Neue resolv.conf
rm -f /etc/resolv.conf
echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8" | tee /etc/resolv.conf > /dev/null

log_info "DNS gesetzt auf 1.1.1.1 & 8.8.8.8"

# Alte Docker entfernen
log_step "Entferne alte Docker-Versionen..."
apt remove -y docker docker-engine docker.io containerd runc || true

# Docker GPG Key
log_step "Füge Docker GPG Key hinzu..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Repo hinzufügen
log_step "Füge Docker Repository hinzu..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update

# Docker installieren
log_step "Installiere Docker..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# User zur Gruppe
if [[ "$ECHTER_BENUTZER" != "root" ]]; then
    log_step "Füge Benutzer zur Docker-Gruppe hinzu..."
    usermod -aG docker $ECHTER_BENUTZER
fi

# Docker starten
log_step "Starte Docker..."
systemctl enable docker
systemctl start docker

sleep 3

# Test
log_step "Teste Docker..."
if docker --version > /dev/null 2>&1; then
    log_info "$(docker --version)"
else
    log_error "Docker Fehler!"
    exit 1
fi

log_info "$(docker compose version)"

# Portainer Volume
log_step "Erstelle Portainer Volume..."
docker volume create portainer_data || true

# Portainer starten
log_step "Starte Portainer..."
docker run -d \
    --name=portainer \
    --restart=always \
    -p 8000:8000 \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

sleep 5

if docker ps | grep -q portainer; then
    log_info "Portainer läuft!"
else
    log_error "Portainer Fehler!"
    exit 1
fi

# IP holen
SERVER_IP=$(hostname -I | awk '{print $1}')
[[ -z "$SERVER_IP" ]] && SERVER_IP="localhost"

# Abschluss
echo ""
echo "============================================"
echo -e "${GRUEN}✅ Installation abgeschlossen!${NC}"
echo "============================================"
echo ""
echo "🌐 Portainer:"
echo "  https://${SERVER_IP}:9443"
echo "  http://${SERVER_IP}:9000"
echo ""
echo "📦 Docker:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

if [[ "$ECHTER_BENUTZER" != "root" ]]; then
    echo "⚠️ Bitte neu einloggen oder:"
    echo "   newgrp docker"
fi

echo ""
echo "============================================"
echo -e "${GRUEN}Fertig 🚀${NC}"
echo "============================================"
