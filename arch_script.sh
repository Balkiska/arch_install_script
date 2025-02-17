#!/usr/bin/env bash
#
# Example Arch Linux installation script 
# This version is tuned for a French environment: 

set -euo pipefail

# ------------------------------------------------------------------------------
# 0. CUTE ASCII COFFEE ART + INITIAL MESSAGE
# ------------------------------------------------------------------------------
cat << "COFFEE"

__________________¶¶¶____¶¶¶____1¶¶1______________
___________________¶¶¶____¶¶¶____¶¶¶______________
___________________¶¶¶____¶¶¶____¶¶¶______________
__________________¶¶¶____1¶¶1___1¶¶1______________
________________1¶¶¶____¶¶¶____¶¶¶1_______________
______________1¶¶¶____¶¶¶1___¶¶¶1_________________
_____________¶¶¶1___1¶¶1___1¶¶1___________________
____________1¶¶1___1¶¶1___1¶¶1____________________
____________1¶¶1___1¶¶1___1¶¶¶____________________
_____________¶¶¶____¶¶¶1___¶¶¶1___________________
______________¶¶¶¶___1¶¶¶___1¶¶¶__________________
_______________1¶¶¶1___¶¶¶1___¶¶¶¶________________
_________________1¶¶1____¶¶¶____¶¶¶_______________
___________________¶¶1____¶¶1____¶¶1______________
___________________¶¶¶____¶¶¶____¶¶¶______________
__________________1¶¶1___1¶¶1____¶¶1______________
_________________¶¶¶____¶¶¶1___1¶¶1_______________
________________11_____111_____11_________________
__________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶¶¶¶¶¶¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶¶¶¶¶¶¶¶¶¶__1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶_______¶¶__1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶_______¶¶__1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶_______¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
1¶¶_______¶¶__1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
_¶¶¶¶¶¶¶¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
_¶¶¶¶¶¶¶¶¶¶¶__¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶________
__________¶¶___1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶1________
__________1¶¶___¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶_________
____________¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶11__________
11_____________________________________________111
1¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶1
__¶¶111111111¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶111111111¶__


echo -e "•*• Profitez d'un café pendant l'installation de votre Arch en français ! •*•"

COFFEE

# ------------------------------------------------------------------------------
# 1. USER-CONFIGURABLE VARIABLES
# ------------------------------------------------------------------------------
DISK="/dev/sda"           # Target disk
HOSTNAME="arch-cats-grub"

USERNAME1="user1"         # first user (the son of my college)
USERNAME2="user2"         # second user (my collegue)

PASSWORD="azerty123"      # Default password (hashed + forced change)
TIMEZONE="Europe/Paris"   
LANGUAGE="fr_FR.UTF-8"    
KEYMAP="fr"               

# LVM volume sizes
LV_ROOT_SIZE="20G"
LV_SWAP_SIZE="4G"
LV_HOME_SIZE="15G"
LV_VBOX_SIZE="10G"
LV_SHARED_SIZE="5G"
LV_SECRET_SIZE="10G"

# Path to the image for GRUB background
GRUB_BG_PATH="/root/cats-bg.png"
GRUB_BG_DEST="/boot/grub/cats-bg.png"

# ------------------------------------------------------------------------------
# 2. PRE-INSTALL CHECKS
# ------------------------------------------------------------------------------
function info() {
  echo -e "•*• $* •*•"
}

function error() {
  echo -e "•*• [ERROR] $* •*•"
  exit 1
}

info "Checking internet connectivity..."
if ! ping -c 1 archlinux.org &>/dev/null; then
  error "No internet connection detected. Aborting."
fi

info "Enabling NTP..."
timedatectl set-ntp true

# ------------------------------------------------------------------------------
# 3. PARTITIONING (GPT + EFI + LUKS)
# ------------------------------------------------------------------------------
info "Wiping and partitioning $DISK"
[ -b "$DISK" ] || error "Disk $DISK not found."

sgdisk --zap-all "$DISK"
parted -s "$DISK" mklabel gpt

# EFI partition 
parted -s "$DISK" mkpart ESP fat32 1MiB 551MiB
parted -s "$DISK" set 1 boot on

# LUKS partition
parted -s "$DISK" mkpart cryptlvm 551MiB 100%

EFI_PART="${DISK}1"
CRYPT_PART="${DISK}2"

info "Formatting EFI partition (FAT32)..."
mkfs.fat -F32 "$EFI_PART"

# ------------------------------------------------------------------------------
# 4. ENCRYPT THE MAIN PARTITION WITH LUKS
# ------------------------------------------------------------------------------
info "Encrypting the main partition..."
cryptsetup luksFormat "$CRYPT_PART" <<< "$PASSWORD"
cryptsetup open "$CRYPT_PART" cryptlvm <<< "$PASSWORD"

# ------------------------------------------------------------------------------
# 5. CREATE LVM INSIDE THE LUKS CONTAINER
# ------------------------------------------------------------------------------
info "Creating LVM volumes..."
pvcreate /dev/mapper/cryptlvm
vgcreate myvg /dev/mapper/cryptlvm

lvcreate -L $LV_ROOT_SIZE myvg -n lv_root
lvcreate -L $LV_SWAP_SIZE myvg -n lv_swap
lvcreate -L $LV_HOME_SIZE myvg -n lv_home
lvcreate -L $LV_VBOX_SIZE myvg -n lv_vbox
lvcreate -L $LV_SHARED_SIZE myvg -n lv_shared
lvcreate -L $LV_SECRET_SIZE myvg -n lv_secret

# ------------------------------------------------------------------------------
# 6. FORMAT THE LVs (except the 'secret' one)
# ------------------------------------------------------------------------------
info "Formatting LVM volumes..."
mkfs.ext4 /dev/myvg/lv_root
mkswap /dev/myvg/lv_swap
mkfs.ext4 /dev/myvg/lv_home
mkfs.ext4 /dev/myvg/lv_vbox
mkfs.ext4 /dev/myvg/lv_shared

# ------------------------------------------------------------------------------
# 7. MOUNT FILESYSTEMS
# ------------------------------------------------------------------------------
info "Mounting filesystems..."
mount /dev/myvg/lv_root /mnt

mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mkdir -p /mnt/var/vbox
mkdir -p /mnt/shared

mount "$EFI_PART" /mnt/boot/efi
mount /dev/myvg/lv_home /mnt/home
mount /dev/myvg/lv_vbox /mnt/var/vbox
mount /dev/myvg/lv_shared /mnt/shared

swapon /dev/myvg/lv_swap

# ------------------------------------------------------------------------------
# 8. INSTALL BASE PACKAGES
# ------------------------------------------------------------------------------
info "Installing base system (pacstrap)..."
pacman -Sy --noconfirm
pacstrap /mnt base base-devel linux linux-firmware linux-headers vim nano sudo git \
  grub efibootmgr networkmanager wget curl openssl

# ------------------------------------------------------------------------------
# 9. GENERATE FSTAB & CHROOT CONFIG
# ------------------------------------------------------------------------------
info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

info "Preparing chroot script..."
cat << EOF > /mnt/tmp/chroot-setup.sh
#!/usr/bin/env bash
set -e

# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "$LANGUAGE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LANGUAGE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat << HST > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HST

# mkinitcpio: add encrypt + lvm2
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block keymap encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# GRUB installation (UEFI)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
# Add cryptdevice argument
sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX="cryptdevice=UUID=$(blkid -s UUID -o value $CRYPT_PART):cryptlvm root=/dev/myvg/lv_root"|g' /etc/default/grub

# If the cat image is present, set it as GRUB background
if [ -f "$GRUB_BG_DEST" ]; then
  echo "GRUB_BACKGROUND=\"$GRUB_BG_DEST\"" >> /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager
systemctl enable NetworkManager

# ------------------------------------------------------------------------------
# Add environment variables (COLORTHERM, THERM)
# ------------------------------------------------------------------------------
echo "export COLORTHERM=1" >> /etc/profile
echo "export THERM=1" >> /etc/profile

# ------------------------------------------------------------------------------
# Install additional packages: mail, VirtualBox, etc.
# ------------------------------------------------------------------------------
pacman -S --noconfirm \
  mailutils \
  gcc make gdb \
  firefox \
  htop neofetch parted gparted ncdu man-db man-pages \
  virtualbox virtualbox-host-dkms

# ------------------------------------------------------------------------------
# Create hashed password for users
# ------------------------------------------------------------------------------
HASHED_PWD=\$(openssl passwd -1 "$PASSWORD")

useradd -m -p "\$HASHED_PWD" -s /bin/bash $USERNAME1
chage -d 0 $USERNAME1

useradd -m -p "\$HASHED_PWD" -s /bin/bash $USERNAME2
chage -d 0 $USERNAME2

echo "root:\$HASHED_PWD" | chpasswd
chage -d 0 root

# Allow sudo for wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
usermod -aG wheel $USERNAME1
usermod -aG wheel $USERNAME2

# ------------------------------------------------------------------------------
# Custom HISTFILE for user1
# ------------------------------------------------------------------------------
echo 'export HISTFILE=~/.bash_history_C' >> /home/$USERNAME1/.bashrc

# ------------------------------------------------------------------------------
# Simple Hyprland config for user2 (example)
# ------------------------------------------------------------------------------
mkdir -p /home/$USERNAME2/.config/hypr
cat << HYPRCFG > /home/$USERNAME2/.config/hypr/hyprland.conf
# Minimal Hyprland config example
monitor=,1920x1080,0x0,1
exec=waybar
HYPRCFG
chown -R $USERNAME2:$USERNAME2 /home/$USERNAME2/.config

EOF

chmod +x /mnt/tmp/chroot-setup.sh

# Copy the image into the new system if present
if [ -f "$GRUB_BG_PATH" ]; then
  info "Copying cat image to /mnt/boot/grub/cats-bg.png"
  mkdir -p /mnt/boot/grub
  cp "$GRUB_BG_PATH" /mnt/boot/grub/cats-bg.png
fi

# ------------------------------------------------------------------------------
# 10. CHROOT & RUN SETUP
# ------------------------------------------------------------------------------
info "Entering chroot to finalize configuration..."
arch-chroot /mnt /tmp/chroot-setup.sh
rm /mnt/tmp/chroot-setup.sh || true

# ------------------------------------------------------------------------------
# 11. CREATE SECONDARY LUKS (10 GB) FOR MANUAL MOUNT
# ------------------------------------------------------------------------------
info "Creating secondary LUKS on lv_secret..."
echo "$PASSWORD" | cryptsetup luksFormat /dev/myvg/lv_secret -
# This container remains manual; not auto-mounted.

# ------------------------------------------------------------------------------
# DONE
# ------------------------------------------------------------------------------
info "Installation complete! Unmount, reboot, and enjoy your environment."
