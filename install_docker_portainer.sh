#!/bin/bash

# Docker und Portainer Installationsskript für Ubuntu Server 24.04
# Ausführen mit: chmod +x install.sh && sudo ./install.sh

set -e  # Beenden bei Fehlern
set -u  # Beenden bei undefinierten Variablen

# Farben für die Ausgabe
ROT='\033[0;31m'
GRUEN='\033[0;32m'
GELB='\033[1;33m'
BLAU='\033[0;34m'
NC='\033[0m' # Keine Farbe

# Logging-Funktionen
log_info() {
    echo -e "${GRUEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${GELB}[WARNUNG]${NC} $1"
}

log_error() {
    echo -e "${ROT}[FEHLER]${NC} $1"
}

log_step() {
    echo -e "${BLAU}[SCHRITT]${NC} $1"
}

# Ermittle den echten Benutzer (auch wenn mit sudo ausgeführt)
if [[ $SUDO_USER ]]; then
    ECHTER_BENUTZER=$SUDO_USER
else
    ECHTER_BENUTZER=$(whoami)
fi

# Bestimme das richtige Home-Verzeichnis
if [[ "$ECHTER_BENUTZER" == "root" ]]; then
    BENUTZER_HOME="/root"
else
    BENUTZER_HOME="/home/$ECHTER_BENUTZER"
fi

# Begrüßung
echo ""
echo "============================================"
echo -e "${BLAU}Docker und Portainer Installationsskript${NC}"
echo "============================================"
echo ""
log_info "Installation wird für Benutzer: $ECHTER_BENUTZER durchgeführt"
log_info "Home-Verzeichnis: $BENUTZER_HOME"
echo ""

# Systemaktualisierung
log_step "Aktualisiere Systempakete..."
apt update && apt upgrade -y

# Installiere Abhängigkeiten
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

# Entferne alte Docker-Versionen falls vorhanden
log_step "Entferne alte Docker-Versionen..."
apt remove -y docker docker-engine docker.io containerd runc || true

# Füge Dockers offiziellen GPG-Schlüssel hinzu
log_step "Füge Dockers offiziellen GPG-Schlüssel hinzu..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Füge Docker Repository hinzu
log_step "Füge Docker Repository hinzu..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Aktualisiere Paketindex erneut
apt update

# Installiere Docker Engine
log_step "Installiere Docker Engine..."
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Füge Benutzer zur Docker-Gruppe hinzu (falls nicht root)
if [[ "$ECHTER_BENUTZER" != "root" ]]; then
    log_step "Füge Benutzer $ECHTER_BENUTZER zur Docker-Gruppe hinzu..."
    usermod -aG docker $ECHTER_BENUTZER
    log_info "Benutzer wurde zur Docker-Gruppe hinzugefügt"
fi

# Aktiviere und starte Docker Dienst
log_step "Aktiviere und starte Docker Dienst..."
systemctl enable docker
systemctl start docker

# Warte kurz bis Docker bereit ist
sleep 3

# Überprüfe Docker Installation
log_step "Überprüfe Docker Installation..."
if docker --version > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    log_info "Docker erfolgreich installiert: $DOCKER_VERSION"
else
    log_error "Docker Installation fehlgeschlagen!"
    exit 1
fi

# Überprüfe Docker Compose
if docker compose version > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version)
    log_info "Docker Compose erfolgreich installiert: $COMPOSE_VERSION"
fi

# Erstelle Docker Volume für Portainer
log_step "Erstelle Docker Volume für Portainer..."
docker volume create portainer_data || true

# Installiere Portainer Community Edition
log_step "Installiere Portainer Community Edition..."
docker run -d \
    --name=portainer \
    --restart=always \
    -p 8000:8000 \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

# Warte bis Portainer startet
sleep 5

# Überprüfe ob Portainer läuft
if docker ps | grep -q portainer; then
    log_info "Portainer wurde erfolgreich installiert!"
else
    log_error "Portainer Installation fehlgeschlagen!"
    exit 1
fi

# Ermittle Server-IP-Adresse
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
if [[ -z "$SERVER_IP" ]]; then
    SERVER_IP="localhost"
fi

# Abschlussbildschirm
echo ""
echo "============================================"
echo -e "${GRUEN}✅ Installation erfolgreich abgeschlossen!${NC}"
echo "============================================"
echo ""
echo -e "${BLAU}📦 Docker Informationen:${NC}"
echo "  Version: $(docker --version)"
echo "  Compose: $(docker compose version)"
echo "  Container Status:"
docker ps --format "  table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${BLAU}🌐 Portainer Zugang:${NC}"
echo "  HTTPS: https://${SERVER_IP}:9443"
echo "  HTTP:  http://${SERVER_IP}:9000"
echo "  Agent: http://${SERVER_IP}:8000"
echo ""
echo -e "${BLAU}📝 Wichtige Hinweise:${NC}"
if [[ "$ECHTER_BENUTZER" != "root" ]]; then
    echo "  1️⃣ Abmelden und erneut anmelden für Docker Gruppenrechte:"
    echo "     exit  # Ausloggen und neu verbinden"
    echo "     oder: newgrp docker"
fi
echo "  1️⃣ Portainer im Browser öffnen und Admin-Konto erstellen"
echo "  2️⃣ Firewall-Regeln wurden bei aktiver UFW konfiguriert"
echo ""
echo -e "${BLAU}🔧 Nützliche Befehle:${NC}"
echo "  docker ps                    # Laufende Container anzeigen"
echo "  docker logs portainer        # Portainer Logs anzeigen"
echo "  docker stop portainer        # Portainer stoppen"
echo "  docker start portainer       # Portainer starten"
echo ""
echo -e "${GELB}⚠️  Sicherheitshinweise:${NC}"
echo "  • Ändern Sie das Standard-Passwort für Portainer"
echo "  • Aktivieren Sie HTTPS für Produktivumgebungen"
echo "  • Konfigurieren Sie regelmäßige Backups"
echo ""
echo "============================================"
echo -e "${GRUEN}Viel Erfolg mit Docker und Portainer!${NC}"
echo "============================================"