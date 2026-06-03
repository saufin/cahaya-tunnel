#!/bin/bash
# CAHAYA TUNNEL - Auto Installer

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

clear
echo "=========================================="
echo "     INSTALLER CAHAYA TUNNEL"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Harap jalankan sebagai root${NC}"
    exit 1
fi

apt update && apt install dropbear python3 nginx curl wget git -y

cat > /etc/default/dropbear << 'DROPEOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 109"
DROPEOF

curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/ws.py -o /usr/bin/ws.py
curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/ws.service -o /etc/systemd/system/ws.service
curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/menu -o /usr/local/bin/menu

systemctl restart dropbear
systemctl daemon-reload
systemctl enable ws
systemctl restart ws
chmod +x /usr/local/bin/menu

echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
echo "Jalankan dengan perintah: menu"
