#!/bin/bash
# =============================================
# CAHAYA TUNNEL
# SSH ACCOUNT MANAGEMENT MENU
# =============================================

PASSWORD_RAHASIA="Askt2021@"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fungsi cek lisensi
check_license() {
    if [ ! -f /etc/cahaya_license ]; then
        echo -e "${RED}[!] Lisensi tidak ditemukan. Hubungi WA 087758826172${NC}"
        exit 1
    fi
    EXPIRED=$(openssl enc -aes-256-cbc -d -base64 -in /etc/cahaya_license -pass pass:$PASSWORD_RAHASIA 2>/dev/null)
    if [ -z "$EXPIRED" ]; then
        echo -e "${RED}[!] Lisensi rusak atau tidak valid${NC}"
        exit 1
    fi
    TODAY=$(date +%Y%m%d)
    if [ $TODAY -gt $EXPIRED ]; then
        echo -e "${RED}[!] Masa berlaku script telah habis. Hubungi WA 087758826172${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Lisensi valid sampai: $EXPIRED${NC}"
    echo ""
}

# Fungsi buat akun baru
buat_akun() {
    clear
    echo "========================================"
    echo "         BUAT AKUN SSH BARU"
    echo "========================================"
    read -p "Username : " username
    read -p "Password : " password
    read -p "Masa Aktif (hari) : " expired_days

    if id "$username" &>/dev/null; then
        echo -e "${RED}[!] Username sudah ada!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi

    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd

    expired_date=$(date -d "+$expired_days days" +"%Y-%m-%d")
    mkdir -p /etc/ssh-expired
    echo "$username:$expired_date" >> /etc/ssh-expired/users

    echo -e "${GREEN}[✓] Akun berhasil dibuat!${NC}"
    echo "Username : $username"
    echo "Password : $password"
    echo "Expired  : $expired_date"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi hapus akun
hapus_akun() {
    clear
    echo "========================================"
    echo "          HAPUS AKUN SSH"
    echo "========================================"
    
    echo -e "${YELLOW}Daftar Akun SSH:${NC}"
    echo "----------------------------------------"
    ls /home/ | cat -n
    echo "----------------------------------------"
    read -p "Masukkan username yang akan dihapus: " username

    if id "$username" &>/dev/null; then
        read -p "Yakin hapus $username? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            userdel -r "$username"
            sed -i "/^$username:/d" /etc/ssh-expired/users 2>/dev/null
            echo -e "${GREEN}[✓] Akun $username berhasil dihapus!${NC}"
        else
            echo -e "${YELLOW}Penghapusan dibatalkan.${NC}"
        fi
    else
        echo -e "${RED}[!] Username tidak ditemukan!${NC}"
    fi
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi daftar semua akun
daftar_akun() {
    clear
    echo "========================================"
    echo "       DAFTAR SEMUA AKUN SSH"
    echo "========================================"
    echo -e "${YELLOW}No | Username${NC}"
    echo "----------------------------------------"
    ls /home/ | cat -n
    echo "========================================"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi cek user login dari Dropbear (PALING AKURAT UNTUK HTTP CUSTOM)
# INI ADALAH MENU 4 YANG BARU
user_dari_dropbear() {
    clear
    echo "========================================"
    echo "       USER LOGIN "
    echo "========================================"
    echo -e "${YELLOW}User yang berhasil login :${NC}"
    echo "----------------------------------------"
    
    # Ambil user login dalam 1 menit terakhir
    journalctl -u dropbear --since "1 minute ago" --no-pager | grep "Password auth succeeded" | awk -F"for '" '{print $2}' | cut -d"'" -f1 | sort -u | while read user; do
        echo "  - $user"
    done
    
    if [ -z "$(journalctl -u dropbear --since "1 minute ago" --no-pager | grep "Password auth succeeded")" ]; then
        echo "  Belum ada user login dalam 1 menit terakhir."
    fi
    
    echo ""
    echo -e "${YELLOW}Detail login terbaru:${NC}"
    echo "----------------------------------------"
    journalctl -u dropbear --since "1 minute ago" --no-pager | grep "Password auth succeeded" | tail -5 | awk '{print "  User: " $9 " | IP: " $11 " | Waktu: " $1 " " $2 " " $3}'
    
    echo "========================================"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi cek semua user & expired
cek_semua() {
    clear
    echo "========================================"
    echo "    SEMUA USER & STATUS EXPIRED"
    echo "========================================"
    if [ ! -f /etc/ssh-expired/users ]; then
        echo "Tidak ada data expired."
    else
        cat /etc/ssh-expired/users
    fi
    echo "========================================"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi ganti password
ganti_password() {
    clear
    echo "========================================"
    echo "     GANTI PASSWORD USER SSH"
    echo "========================================"
    echo -e "${YELLOW}Daftar Akun:${NC}"
    echo "----------------------------------------"
    ls /home/ | cat -n
    echo "----------------------------------------"
    read -p "Masukkan username: " username

    if id "$username" &>/dev/null; then
        passwd "$username"
        echo -e "${GREEN}[✓] Password berhasil diubah!${NC}"
    else
        echo -e "${RED}[!] Username tidak ditemukan!${NC}"
    fi
    read -p "Tekan Enter untuk kembali..."
}

# Menu utama
while true; do
    clear
    echo "========================================"
    echo "          CAHAYA TUNNEL"
    echo "========================================"
    check_license
    echo "       SSH ACCOUNT MANAGEMENT"
    echo "========================================"
    echo "1. Buat Akun SSH Baru"
    echo "2. Hapus Akun SSH"
    echo "3. Daftar Semua Akun SSH"
    echo "4. Cek User Login (Dropbear)"
    echo "5. Cek Semua User & Expired"
    echo "6. Ganti Password User SSH"
    echo "0. Keluar"
    echo "========================================"
    echo -e "   ${YELLOW}NO WA ADMIN : 087758826172${NC}"
    echo "========================================"
    read -p "Pilih menu [0-6]: " pilihan

    case $pilihan in
        1) buat_akun ;;
        2) hapus_akun ;;
        3) daftar_akun ;;
        4) user_dari_dropbear ;;
        5) cek_semua ;;
        6) ganti_password ;;
        0) echo -e "${GREEN}Terima kasih telah menggunakan CAHAYA TUNNEL!${NC}"; exit 0 ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
