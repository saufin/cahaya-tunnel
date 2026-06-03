#!/bin/bash

# =============================================
#          CAHAYA TUNNEL
#     SSH ACCOUNT MANAGEMENT MENU
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

# Fungsi dapatkan daftar user SSH
get_user_list() {
    cat /etc/passwd | grep -E ":/home/.*:/bin/false|:/home/.*:/bin/bash" | cut -d: -f1
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
    
    user_list=($(get_user_list))
    if [ ${#user_list[@]} -eq 0 ]; then
        echo -e "${RED}Tidak ada akun SSH yang tersedia!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    
    echo -e "${YELLOW}Daftar Akun SSH:${NC}"
    echo "----------------------------------------"
    for i in "${!user_list[@]}"; do
        echo "$((i+1)). ${user_list[$i]}"
    done
    echo "----------------------------------------"
    read -p "Masukkan nomor urut atau username: " input
    
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        if [ "$input" -ge 1 ] && [ "$input" -le "${#user_list[@]}" ]; then
            username="${user_list[$((input-1))]}"
        else
            echo -e "${RED}Nomor tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    else
        username="$input"
    fi
    
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
    echo -e "${YELLOW}No | Username    | Expired     | Status${NC}"
    echo "----------------------------------------"
    user_list=($(get_user_list))
    if [ ${#user_list[@]} -eq 0 ]; then
        echo "Tidak ada akun SSH."
    else
        for i in "${!user_list[@]}"; do
            user="${user_list[$i]}"
            expired=$(grep "^$user:" /etc/ssh-expired/users 2>/dev/null | cut -d: -f2)
            if [[ -z "$expired" ]]; then
                expired="Tidak terbatas"
                status="${GREEN}aktif${NC}"
            else
                today=$(date +%s)
                exp_date=$(date -d "$expired" +%s 2>/dev/null)
                if [[ $today -gt $exp_date ]]; then
                    status="${RED}expired${NC}"
                else
                    status="${GREEN}aktif${NC}"
                fi
            fi
            printf "%-3s | %-10s | %-10s | %b\n" "$((i+1))" "$user" "$expired" "$status"
        done
    fi
    echo "========================================"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi cek user online
user_online() {
    clear
    echo "========================================"
    echo "       USER SSH ONLINE"
    echo "========================================"
    echo -e "${YELLOW}User      | Login dari${NC}"
    echo "----------------------------------------"
    who | grep -E "\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)" | awk '{print $1"      | "$5}' || echo "Tidak ada user online"
    echo "========================================"
    read -p "Tekan Enter untuk kembali..."
}

# Fungsi cek semua user & expired
cek_semua() {
    clear
    echo "========================================"
    echo "    SEMUA USER & STATUS EXPIRED"
    echo "========================================"
    echo -e "${YELLOW}Username    | Expired     | Sisa hari${NC}"
    echo "----------------------------------------"
    if [ ! -f /etc/ssh-expired/users ]; then
        echo "Tidak ada data expired."
    else
        cat /etc/ssh-expired/users | while IFS=: read user exp; do
            today=$(date +%s)
            exp_date=$(date -d "$exp" +%s 2>/dev/null)
            diff=$(( ($exp_date - $today) / 86400 ))
            if [[ $diff -lt 0 ]]; then
                sisa="${RED}expired${NC}"
            else
                sisa="${GREEN}$diff hari${NC}"
            fi
            printf "%-10s | %-10s | %b\n" "$user" "$exp" "$sisa"
        done
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
    user_list=($(get_user_list))
    if [ ${#user_list[@]} -eq 0 ]; then
        echo -e "${RED}Tidak ada akun SSH!${NC}"
        read -p "Tekan Enter untuk kembali..."
        return
    fi
    echo -e "${YELLOW}Daftar Akun:${NC}"
    for i in "${!user_list[@]}"; do
        echo "$((i+1)). ${user_list[$i]}"
    done
    read -p "Masukkan nomor urut atau username: " input
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        if [ "$input" -ge 1 ] && [ "$input" -le "${#user_list[@]}" ]; then
            username="${user_list[$((input-1))]}"
        else
            echo -e "${RED}Nomor tidak valid!${NC}"
            read -p "Tekan Enter untuk kembali..."
            return
        fi
    else
        username="$input"
    fi
    if id "$username" &>/dev/null; then
        passwd "$username"
        echo -e "${GREEN}[✓] Password berhasil diubah!${NC}"
    else
        echo -e "${RED}[!] Username tidak ditemukan!${NC}"
    fi
    read -p "Tekan Enter untuk kembali..."
}

# SSH ke root
ssh_root() {
    clear
    su -
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
    echo "4. Cek User SSH Online"
    echo "5. Cek Semua User & Expired"
    echo "6. SSH ke Server (Root)"
    echo "7. Ganti Password User SSH"
    echo "0. Keluar"
    echo "========================================"
    echo -e "   ${YELLOW}NO WA ADMIN : 087758826172${NC}"
    echo "========================================"
    read -p "Pilih menu [0-7]: " pilihan

    case $pilihan in
        1) buat_akun ;;
        2) hapus_akun ;;
        3) daftar_akun ;;
        4) user_online ;;
        5) cek_semua ;;
        6) ssh_root ;;
        7) ganti_password ;;
        0) echo -e "${GREEN}Terima kasih telah menggunakan CAHAYA TUNNEL!${NC}"; exit 0 ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
