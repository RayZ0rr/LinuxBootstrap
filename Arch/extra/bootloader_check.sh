#!/usr/bin/env bash

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

myGitFolder="gFolder/RaZ0rr"
bootFolder="${myGitFolder}/LinuxBoot"

addBar(){
  printf "\n--------------------------------------\n"
}

refind_setup()
{
  current_path="$PWD"
  addBar
  echo "$current_path"
  addBar
  esp_device=$(mount | grep 'efi ' | cut -d' ' -f 1)
  echo "esp_device : $esp_device "
  addBar
  [ -z "${esp_mount}" ] && esp_mount=$(lsblk -no MOUNTPOINT $esp_device | tee -a "${logFolder}/refind.log")
  echo "esp_mount : $esp_mount "
  addBar
  refind_path="${esp_mount}/EFI/refind"
  echo "refind_path : $refind_path "
  addBar
  # dialog --title "Bootloader setup" --infobox "Installing rEFInd which is required to boot the system." 5 70
  echo "refind-install >/dev/null 2>&1"
  # dialog --title "Bootloader setup" --infobox "Setting up rEFInd which is required to boot the system." 5 70
  addBar
  echo "cp ${esp_mount}/EFI/refind/refind.conf ${esp_mount}/EFI/refind/refind_sample.conf"
  # cp -r "${bootFolder}/refind/themes/refind.conf" ${esp_mount}/EFI/refind | tee -a "${logFolder}/refind.log"
  ! [[ -d "${esp_mount}/EFI/refind/themes" ]] && echo "mkdir -p ${esp_mount}/EFI/refind/themes"
  addBar
  grep -qxF 'include themes/refind-theme-regular/theme.conf' ${refind_path}/refind.conf || echo "include themes/refind-theme-regular/theme.conf to ${refind_path}/refind.conf"
  grep -qxF '#BACKGROUND IMAGE' ${refind_path}/refind.conf || echo "#BACKGROUND IMAGE ${refind_path}/refind.conf"
  grep -qxF 'banner themes/refind-theme-regular/bg.png' ${refind_path}/refind.conf || echo "banner themes/refind-theme-regular/bg.png ${refind_path}/refind.conf"
  grep -qxF 'banner_scale fillscreen' ${refind_path}/refind.conf || echo "banner_scale fillscreen ${refind_path}/refind.conf"
  addBar
  echo "rsync -avz --delete ${bootFolder}/refind/themes/refind-theme-regular_FINAL/ ${esp_mount}/EFI/refind/themes/refind-theme-regular"
  echo "rsync -avz --delete ${bootFolder}/refind/themes/bg.png ${esp_mount}/EFI/refind/themes/refind-theme-regular/bg.png"
  addBar
  [[ -z "$root_device" ]] && root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  echo "root_device : $root_device "
  root_uuid=$(lsblk -no UUID $root_device)
  echo "root_uuid : $root_uuid "
  addBar
  [[ -z "$home_device" ]] && home_device=$(df -P /home | cut -d '[' -f 1 | awk 'END{print $1}')
  [[ -z "$fstype" ]] && fstype=$(df -T | grep $root_device | awk '{print $2}')
  echo "home_device : $home_device "
  echo "fstype : $fstype "
  addBar
  if [[ "$fstype" == "ext4" ]] ; then
    echo "cp /usr/share/refind/drivers_x64/ext4_x64.efi ${esp_mount}/EFI/refind/drivers_x64/ext4_x64.efi"
    echo "cp -r ${bootFolder}/refind/boot/refind_linux_ext4.conf /boot/refind_linux.conf"
    [[ "${fsEncrypt}" == "yes" ]] && echo "cp -r ${bootFolder}/refind/boot/refind_linux_ext4_luks.conf /boot/refind_linux.conf"
    echo "fsEncrypt : $fsEncrypt "
    addBar
  elif [[ "$fstype" == "btrfs" ]] ; then
    echo "cp /usr/share/refind/drivers_x64/btrfs_x64.efi ${esp_mount}/EFI/refind/drivers_x64/btrfs_x64.efi"
    echo "cp -r ${bootFolder}/refind/boot/refind_linux_btrfs.conf /boot/refind_linux.conf"
    [[ "${fsEncrypt}" == "yes" ]] && echo "cp -r ${bootFolder}/refind/boot/refind_linux_btrfs_luks.conf /boot/refind_linux.conf"
    echo "fsEncrypt : $fsEncrypt "
    addBar
  fi
  if [[ "${fsEncrypt}" == "yes" ]] ; then
    [[ -z "${root_name}" ]] && root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    echo "root_name : $root_name "
    addBar
    [[ -z "${crypt_root_device}" ]] && crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    echo "crypt_root_device : $crypt_root_device "
    addBar
    # [[ -z "${crypt_root_device}" ]] && crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_uuid=$(sudo blkid -s UUID -o value $crypt_root_device)
    echo "crypt_root_uuid : $crypt_root_uuid "
    addBar
    sed "s/luks_uuid_number/$crypt_root_uuid/" /boot/refind_linux.conf
    addBar
    sed 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf
    addBar
    sed '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf
    addBar
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf
    addBar
    if [[ "$fstype" == "ext4" ]] ; then
      [[ -z "${home_name}" ]] && home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      echo "home_name : $home_name "
      addBar
      [[ -z "${crypt_home_device}" ]] && crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      echo "crypt_home_device : $crypt_home_device "
      addBar
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device)
      echo "crypt_home_uuid : $crypt_home_uuid "
      addBar
      echo "cp ${bootFolder}/crypt/crypttab /etc/crypttab"
      sed "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab
      sed "s/Chome/$home_name/" /etc/crypttab
      addBar
      addBar
    fi
  fi

  boot_separate=$(findmnt -n -o FSTYPE $boot_mount)
  echo "boot_separate : $boot_separate "
  addBar
  if [[ -n "$boot_separate" ]] ; then
    [[ "$fstype" == "ext4" ]] && sed 's/\\boot\\//g' /boot/refind_linux.conf
    [[ "$fstype" == "btrfs" ]] && sed 's/@\\boot\\//g' /boot/refind_linux.conf
    [ -z "$boot_device" ] && boot_device=$(findmnt -n -o SOURCE $boot_mount | cut -d '[' -f 1)
    echo "boot_device : $boot_device "
    # boot_device=$(df -P /boot | awk 'END{print $1}')
    boot_uuid=$(blkid -s UUID -o value $boot_device)
    boot_fstype=$(findmnt -n -o FSTYPE $boot_mount)
    echo "boot_fstype : $boot_fstype "
    echo "boot_uuid : $boot_uuid "
    addBar
    if [[ "$boot_fstype" == "ext4" ]] ; then
      echo "cp /usr/share/refind/drivers_x64/ext4_x64.efi ${esp_mount}/EFI/refind/drivers_x64/ext4_x64.efi"
    elif [[ "$boot_fstype" == "btrfs" ]] ; then
      echo "cp /usr/share/refind/drivers_x64/btrfs_x64.efi ${esp_mount}/EFI/refind/drivers_x64/btrfs_x64.efi"
    fi
  fi
  addBar

  addBar
  sed "s/root_uuid_number/$root_uuid/" /boot/refind_linux.conf
  [[ "${fsEncrypt}" == "yes" ]] && sed "s/Cbtrfs/$root_name/" /boot/refind_linux.conf

  echo "rsync -avz --delete ${bootFolder}/refind/themes/refind-theme-regular_FINAL/icons/256-96/os_arch.png ${boot_mount}/vmlinuz-linux-lts.png"

  addBar
  # dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  echo "mkinitcpio -P >/dev/null 2>&1"

  cd "$current_path"
  addBar
}

refind_setup
