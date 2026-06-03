#!/bin/bash
# CAHAYA TUNNEL - Auto Installer (Update)

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

if ! command -v openssl &> /dev/null; then
    apt update && apt install openssl -y
fi

EXPIRED_DATE=$(date -d "+30 days" +%Y%m%d)

echo "$EXPIRED_DATE" | openssl enc -aes-256-cbc -e -base64 -pass pass:Askt2021@ 2>/dev/null > /etc/cahaya_license

rm -f /usr/local/bin/menu
echo "[+] Memasang binary CAHAYA TUNNEL..."

BASE64_BINARY="$(cat /root/cahaya-tunnel/cahaya_tunnel.b64)"

echo "$BASE64_BINARY" | base64 -d > /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo -e "${GREEN}[✓] Instalasi selesai!${NC}"
echo "Jalankan dengan perintah: menu"
echo "=========================================="
