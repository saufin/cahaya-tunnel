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

# Install dependencies
apt update && apt install dropbear python3 nginx curl wget git openssl -y

# Konfigurasi dropbear
cat > /etc/default/dropbear << 'DROPEOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 109"
DROPEOF

# Download ws.py dan ws.service
curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/ws.py -o /usr/bin/ws.py
curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/ws.service -o /etc/systemd/system/ws.service

# Start service
systemctl restart dropbear
systemctl daemon-reload
systemctl enable ws
systemctl restart ws

# ========== LISENSI ==========
# GANTI ANGKA DI BAWAH INI (contoh: +1 day, +30 days, +365 days)
EXPIRED_TIMESTAMP=$(date -d "+5 minutes" +%s)
echo "$EXPIRED_DATE" | openssl enc -aes-256-cbc -e -base64 -pass pass:Askt2021@ 2>/dev/null > /etc/cahaya_license
# ==============================

# Download menu binary
curl -sL https://raw.githubusercontent.com/saufin/cahaya-tunnel/main/menu -o /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
echo "Jalankan dengan perintah: menu"
echo "Masa berlaku lisensi: $(date -d "$(echo $EXPIRED_DATE)" +%Y-%m-%d)"
echo "=========================================="
