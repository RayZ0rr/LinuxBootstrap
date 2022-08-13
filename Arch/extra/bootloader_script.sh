#!/usr/bin/env bash

scriptFolder=$(dirname $(readlink -f $0))
progsfile="${scriptFolder}/progs.csv"
myName="$(whoami)"
repodir="$HOME/.local/src"
logFolder="$HOME/.local/src/logs"
mkdir -p $logFolder
aurhelper="yay"
repobranch="main"

[ -z "$myGitFolder" ] && myGitFolder="gFolder/RaZ0rr"
[ -z "$bootFolder" ] && bootFolder="${myGitFolder}/LinuxBoot"
[ -z "$bootrepo" ] && bootFolder="${scriptFolder}/LinuxBoot"

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
  current_path="$PWD"
  cd "/home/${myName}"
  dialog --infobox "Downloading and installing config files..." 4 60
  [ -z "$3" ] && branch="$repobranch" || branch="$3"
  dir=$(mktemp -d)
  [ ! -d "$2" ] && sudo -u "$myName" mkdir -p "$2" | tee -a "${logFolder}/putgitrepo.log"
  chown "$myName":"$myName" "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" >/dev/null 2>&1 | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" cp -rfT "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  cd "$current_path"
  }

putgitrepo "$bootrepo" "${myGitFolder}/LinuxBoot" "$repobranch"
bootloader_setup

[ -z "$fstype" ] && fstype="btrfs"
[ -z "$bootLoader" ] && bootLoader="refind"
[ -z "$esp_mount" ] && esp_mount="/efi"
[ -z "$boot_mount" ] && boot_mount="/boot"
[ -z "$boot_device" ] && boot_device=""
# -----------------------------------------------------
# For btrfs filesystems
# -----------------------------------------------------
[ -z "$root_device" ] && root_device="/dev/mapper/Cbtrfs"
# -----------------------------------------------------
# For ext4 filesystems
# -----------------------------------------------------
# [ -z "$root_device" ] && root_device="/dev/mapper/Croot"
# [ -z "$home_device" ] && home_device="/dev/mapper/Chome"
# [ -z "$root_name" ] && root_name="Croot"
# [ -z "$home_name" ] && root_name="Croot"
# [ -z "$crypt_device_root" ] && crypt_device_root="/dev/sda3"
# [ -z "$crypt_device_home" ] && crypt_device_home="/dev/sda4"
# -----------------------------------------------------
# Encryption
# -----------------------------------------------------
[ -z "$fsEncrypt" ] && fsEncrypt="yes"

refind_setup()
{
  current_path="$PWD"
  cd "/home/${myName}"
  esp_mount=$(dialog --no-cancel --inputbox "Enter the mount point for EFI system partition (esp) [eg : /boot/efi , /efi]" 10 60 3>&1 1>&2 2>&3 3>&1)
  refind_path="${esp_mount}/EFI/refind"
  dialog --title "Bootloader setup" --infobox "Installing rEFInd which is required to boot the system." 5 70
  refind-install >/dev/null 2>&1 | tee -a "${logFolder}/refind.log"
  dialog --title "Bootloader setup" --infobox "Setting up rEFInd which is required to boot the system." 5 70
  cp ${esp_mount}/EFI/refind/refind.conf ${esp_mount}/EFI/refind/refind_sample.conf | tee -a "${logFolder}/refind.log"
  # cp -r "${bootFolder}/refind/themes/refind.conf" ${esp_mount}/EFI/refind | tee -a "${logFolder}/refind.log"
  ! [[ -d "${esp_mount}/EFI/refind/themes" ]] && mkdir -p ${esp_mount}/EFI/refind/themes
  grep -qxF 'include themes/refind-theme-regular/theme.conf' ${refind_path}/refind.conf || echo 'include themes/refind-theme-regular/theme.conf' >> ${refind_path}/refind.conf
  grep -qxF '#BACKGROUND IMAGE' ${refind_path}/refind.conf || echo '#BACKGROUND IMAGE' >> ${refind_path}/refind.conf
  grep -qxF 'banner themes/refind-theme-regular/bg.png' ${refind_path}/refind.conf || echo 'banner themes/refind-theme-regular/bg.png' >> ${refind_path}/refind.conf
  grep -qxF 'banner_scale fillscreen' ${refind_path}/refind.conf || echo 'banner_scale fillscreen' >> ${refind_path}/refind.conf
  rsync -avz --delete "${bootFolder}/refind/themes/refind-theme-regular_FINAL/" ${esp_mount}/EFI/refind/themes/refind-theme-regular | tee -a "${logFolder}/refind.log"
  rsync -avz --delete "${bootFolder}/refind/themes/bg.png" ${esp_mount}/EFI/refind/themes/refind-theme-regular/bg.png | tee -a "${logFolder}/refind.log"
  root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  # root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name :- ( eg : /dev/sda2, /dev/nvme0n1p3, /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
  root_check=$(dialog --no-cancel --inputbox "Is $root_device your root partition name ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
  while ! [[ $root_check == "yes" || $root_check == "no" ]]; do
    root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $root_device your root partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
  done
  [[ $root_check == "no" ]] && root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name :- ( eg : /dev/sda2, /dev/nvme0n1p3, /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
  root_uuid=$(lsblk -no UUID $root_device | tee -a "${logFolder}/refind.log")
  home_device=$(df -P /home | cut -d '[' -f 1 | awk 'END{print $1}')
  fstype=$(dialog --no-cancel --inputbox "Enter the root partition filesystem type :- ( eg : ext4, btrfs)" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $fstype == "ext4" || $fstype == "btrfs" ]]; do
    fstype=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'ext4' or 'btrfs'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  fsEncrypt=$(dialog --no-cancel --inputbox "Is filesystem encrypted ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $fsEncrypt == "yes" || $fsEncrypt == "no" ]]; do
    fsEncrypt=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$fstype" == "ext4" ]] ; then
    cp /usr/share/refind/drivers_x64/ext4_x64.efi ${esp_mount}/EFI/refind/drivers_x64/ext4_x64.efi | tee -a "${logFolder}/refind.log"
    cp -r "${bootFolder}/refind/boot/refind_linux_ext4.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp -r "${bootFolder}/refind/boot/refind_linux_ext4_luks.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
  elif [[ "$fstype" == "btrfs" ]] ; then
    cp /usr/share/refind/drivers_x64/btrfs_x64.efi ${esp_mount}/EFI/refind/drivers_x64/btrfs_x64.efi | tee -a "${logFolder}/refind.log"
    cp -r "${bootFolder}/refind/boot/refind_linux_btrfs.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp -r "${bootFolder}/refind/boot/refind_linux_btrfs_luks.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
  fi
  if [[ "${fsEncrypt}" == "yes" ]] ; then
    root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    # crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_check=$(dialog --no-cancel --inputbox "Is $crypt_root_device your root partition name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    while ! [[ $crypt_root_check == "yes" || $crypt_root_check == "no" ]]; do
      crypt_root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_root_device your root partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    done
    [[ $crypt_root_check == "no" ]] && crypt_root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    crypt_root_uuid=$(blkid -s UUID -o value $crypt_root_device | tee -a "${logFolder}/refind.log")
    sed -i "s/luks_uuid_number/$crypt_root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    sed -i 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    sed -i '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed -i "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    if [[ "$fstype" == "ext4" ]] ; then
      home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      crypt_home_check=$(dialog --no-cancel --inputbox "Is $crypt_home_device your home partition name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
      while ! [[ $crypt_home_check == "yes" || $crypt_home_check == "no" ]]; do
	crypt_home_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_home_device your home partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
      done
      [[ $crypt_home_check == "no" ]] && crypt_home_device=$(dialog --no-cancel --inputbox "Enter the root partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device | tee -a "${logFolder}/refind.log")
      cp "${bootFolder}"/crypt/crypttab /etc/crypttab
      # sed -i "/home_luks_uuid_number/ s/^Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/refind.log"
    fi
  fi

  boot_separate=$(dialog --no-cancel --inputbox "Is boot on separate partition :- ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $boot_separate == "yes" || $boot_separate == "no" ]]; do
    boot_separate=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$boot_separate" == "yes" ]] ; then
    [[ "$fstype" == "ext4" ]] && sed -i 's/\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    [[ "$fstype" == "btrfs" ]] && sed -i 's/@\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    boot_mount=$(dialog --no-cancel --inputbox "Enter the mount point for boot partition (eg : /boot , /boot/efi)" 10 60 3>&1 1>&2 2>&3 3>&1)
    boot_device=$(findmnt -n -o SOURCE $boot_mount | tee -a "${logfolder}/refind.log")
    # boot_device=$(dialog --no-cancel --inputbox "Enter the boot partition device name:- ( eg : /dev/sda2, /dev/nvme0n1p3 )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    boot_uuid=$(blkid -s UUID -o value $boot_device | tee -a "${logfolder}/refind.log")
    boot_fstype=$(findmnt -n -o FSTYPE $boot_mount)
    boot_fstype_check=$(dialog --no-cancel --inputbox "Is $boot_fstype your boot partition filetype? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    while ! [[ $boot_fstype_check == "yes" || $boot_fstype_check == "no" ]]; do
      boot_fstype_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $boot_fstype your boot partition filetype? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/refind.log")
    done
    if [[ "$boot_fstype" == "ext4" ]] ; then
      cp /usr/share/refind/drivers_x64/ext4_x64.efi ${esp_mount}/EFI/refind/drivers_x64/ext4_x64.efi | tee -a "${logFolder}/refind.log"
    elif [[ "$boot_fstype" == "btrfs" ]] ; then
      cp /usr/share/refind/drivers_x64/btrfs_x64.efi ${esp_mount}/EFI/refind/drivers_x64/btrfs_x64.efi | tee -a "${logFolder}/refind.log"
    fi
  fi

  sed -i "s/root_uuid_number/$root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
  [[ "${fsEncrypt}" == "yes" ]] && sed -i "s/Cbtrfs/$root_name/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"

  rsync -avz --delete "${bootFolder}/refind/themes/refind-theme-regular_FINAL/icons/256-96/os_arch.png" ${boot_mount}/vmlinuz-linux-lts.png | tee -a "${logFolder}/refind.log"


  dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  mkinitcpio -P >/dev/null 2>&1  | tee -a "${logFolder}/refind.log"

  cd "$current_path"
}

grub_setup()
{
  current_path="$PWD"
  cd "/home/${myName}"
  esp_mount=$(dialog --no-cancel --inputbox "Enter the mount point for EFI system partition (esp) [eg : /boot/efi , /efi]" 10 60 3>&1 1>&2 2>&3 3>&1)
  dialog --title "Bootloader setup" --infobox "Installing GRUB which is required to boot the system." 5 70
  grub-install --target=x86_64-efi --efi-directory=${esp_mount} --bootloader-id=Arch > /dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  dialog --title "Bootloader setup" --infobox "Setting up GRUB which is required to boot the system." 5 70
  rsync -avz "${bootFolder}"/grub/themes/dedsec-grub2-theme_FINAL/ /boot/grub/themes/dedsec-grub2-theme/ >/dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  sed -i "s/^#GRUB_THEME=.*/#GRUB_THEME=\"\"\nGRUB_THEME=\"\/boot\/grub\/themes\/dedsec-grub2-theme\/theme.txt\"/" /etc/default/grub | tee -a "${logFolder}/grub.log"
  grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  # root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name :- ( eg : /dev/sda2, /dev/nvme0n1p3, /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  root_check=$(dialog --no-cancel --inputbox "Is $root_device your root partition device name ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  while ! [[ $root_check == "yes" || $root_check == "no" ]]; do
    root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $root_device your root partition device name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  done
  [[ $root_check == "no" ]] && root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name :- ( eg : /dev/sda2, /dev/nvme0n1p3, /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  root_uuid=$(lsblk -no UUID $root_device | tee -a "${logFolder}/refind.log")
  home_device=$(df -P /home | cut -d '[' -f 1 | awk 'END{print $1}')
  fstype=$(dialog --no-cancel --inputbox "Enter the root partition filesystem type :- ( eg : ext4, btrfs)" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $fstype == "ext4" || $fstype == "btrfs" ]]; do
    fstype=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'ext4' or 'btrfs'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  fsEncrypt=$(dialog --no-cancel --inputbox "Is filesystem encrypted ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $fsEncrypt == "yes" || $fsEncrypt == "no" ]]; do
    fsEncrypt=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$fstype" == "ext4" ]] ; then
    cp "${bootFolder}"/grub/boot/custom_ext4.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp "${bootFolder}"/grub/boot/custom_ext4_luks.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  elif [[ "$fstype" == "btrfs" ]] ; then
    cp "${bootFolder}"/grub/boot/custom_btrfs.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp "${bootFolder}"/grub/boot/custom_btrfs_luks.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  fi
  if [[ "${fsEncrypt}" == "yes" ]] ; then
    root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    # crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_check=$(dialog --no-cancel --inputbox "Is $crypt_root_device your root partition device name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    while ! [[ $crypt_root_check == "yes" || $crypt_root_check == "no" ]]; do
      crypt_root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_root_device your root partition device name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    done
    [[ $crypt_root_check == "no" ]] && crypt_root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    crypt_root_uuid=$(blkid -s UUID -o value $crypt_root_device | tee -a "${logFolder}/grub.log")
    sed -i "s/luks_uuid_number/$crypt_root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    sed -i 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    sed -i '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed -i "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    if [[ "$fstype" == "ext4" ]] ; then
      home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      # crypt_home_device="/dev/$(lsblk -f | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      crypt_home_check=$(dialog --no-cancel --inputbox "Is $crypt_home_device your home partition device name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      while ! [[ $crypt_home_check == "yes" || $crypt_home_check == "no" ]]; do
	crypt_home_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_home_device your home partition device name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      done
      [[ $crypt_home_check == "no" ]] && crypt_home_device=$(dialog --no-cancel --inputbox "Enter the home partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device | tee -a "${logFolder}/grub.log")
      cp "${bootFolder}"/crypt/crypttab /etc/crypttab
      # sed -i "/home_luks_uuid_number/ s/^Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/grub.log"
      sed -i "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab | tee -a "${logFolder}/grub.log"
      sed -i "s/Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/grub.log"
    fi
  fi
  dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  mkinitcpio -P >/dev/null 2>&1  | tee -a "${logFolder}/grub.log"

  boot_separate=$(dialog --no-cancel --inputbox "Is boot on separate partition :- ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $boot_separate == "yes" || $boot_separate == "no" ]]; do
    boot_separate=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$boot_separate" == "yes" ]] ; then
    sed -i 's/\/boot//g' /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    boot_mount=$(dialog --no-cancel --inputbox "Enter the mount point for boot partition (eg : /boot , /boot/efi)" 10 60 3>&1 1>&2 2>&3 3>&1)
    boot_device=$(findmnt -n -o SOURCE $boot_mount | tee -a "${logFolder}/grub.log")
    # boot_device=$(dialog --no-cancel --inputbox "Enter the boot partition device name:- ( eg : /dev/sda2, /dev/nvme0n1p3 )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    boot_uuid=$(blkid -s UUID -o value $boot_device | tee -a "${logFolder}/grub.log")
    sed -i "s/boot_uuid_number/$boot_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    # sed -i "s/=root.*/=root $boot_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  else
    sed -i "s/boot_uuid_number/$root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  fi

  sed -i "s/root_uuid_number/$root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  [[ "${fsEncrypt}" == "yes" ]] && sed -i "s/Cbtrfs/$root_name/g" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"

  cd "$current_path"
}

bootloader_setup()
{
  bootLoader=$(dialog --no-cancel --inputbox "Enter the bootloader required :- ( grub or refind or none )" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $bootLoader == "refind" || $bootLoader == "grub" ]]; do
    bootLoader=$(dialog --no-cancel --inputbox "Please choose from the options in the parenthesis :- ( grub or refind or none )" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$bootLoader" == "grub" ]] ; then
    grub_setup
  elif [[ "$bootLoader" == "refind" ]] ; then
    refind_setup
  elif [[ "$bootLoader" == "none" ]] ; then
    echo "No bootloader setup during bootstrap."
  fi
}

refind_setup
