#!/usr/bin/env bash

refind_setup()
{
  current_path="$PWD"
  cd "/home/${myName}"
  esp_mount=$(dialog --no-cancel --inputbox "Enter the mount point for EFI system partition (esp) [eg : /boot/efi , /efi]" 10 60 3>&1 1>&2 2>&3 3>&1)
  dialog --title "Bootloader setup" --infobox "Installing rEFInd which is required to boot the system." 5 70
  refind-install >/dev/null 2>&1 | tee -a "${logFolder}/refind.log"
  dialog --title "Bootloader setup" --infobox "Setting up rEFInd which is required to boot the system." 5 70
  cp ${esp_mount}/EFI/refind/refind.conf ${esp_mount}/EFI/refind/refind_sample.conf | tee -a "${logFolder}/refind.log"
  cp -r "${bootFolder}/refind/themes/refind.conf" ${esp_mount}/EFI/refind | tee -a "${logFolder}/refind.log"
  rsync -avz --delete "${bootFolder}/refind/themes/refind-theme-regular_FINAL/" ${esp_mount}/EFI/refind/themes/refind-theme-regular | tee -a "${logFolder}/refind.log"
  rsync -avz --delete "${bootFolder}/refind/themes/bg.png" ${esp_mount}/EFI/refind/themes/refind-theme-regular/bg.png | tee -a "${logFolder}/refind.log"
  root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  # root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name :- ( eg : /dev/sda2, /dev/nvme0n1p3, /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  root_check=$(dialog --no-cancel --inputbox "Is $root_device your root partition name ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
  while ! [[ $root_check == "yes" || $root_check == "no" ]]; do
    root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $root_device your root partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
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
    cp /usr/share/refind/drivers_x64/ext4_x64.efi ${esp_mount}/EFI/refind/drivers_x64/ext4_x64.efi | tee -a "${logFolder}/refind.log"
    cp -r "${bootFolder}/refind/boot/refind_linux_ext4.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp -r "${bootFolder}/refind/boot/refind_linux_ext4_luks.conf" /boot/refind_linux.conf | tee -a "${logFolder}/grub.log"
  elif [[ "$fstype" == "btrfs" ]] ; then
    cp /usr/share/refind/drivers_x64/btrfs_x64.efi ${esp_mount}/EFI/refind/drivers_x64/btrfs_x64.efi | tee -a "${logFolder}/refind.log"
    cp -r "${bootFolder}/refind/boot/refind_linux_btrfs.conf" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp -r "${bootFolder}/refind/boot/refind_linux_btrfs_luks.conf" /boot/refind_linux.conf | tee -a "${logFolder}/grub.log"
  fi
  if [[ "${fsEncrypt}" == "yes" ]] ; then
    root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    # crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_check=$(dialog --no-cancel --inputbox "Is $crypt_root_device your root partition name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    while ! [[ $crypt_root_check == "yes" || $crypt_root_check == "no" ]]; do
      crypt_root_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_root_device your root partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    done
    [[ $crypt_root_check == "no" ]] && crypt_root_device=$(dialog --no-cancel --inputbox "Enter the root partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    crypt_root_uuid=$(blkid -s UUID -o value $crypt_root_device | tee -a "${logFolder}/grub.log")
    sed -i "s/luks_uuid_number/$crypt_root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    sed -i 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    sed -i '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed -i "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    if [[ "$fstype" == "ext4" ]] ; then
      home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      crypt_home_check=$(dialog --no-cancel --inputbox "Is $crypt_home_device your home partition name used for encryption ? (yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      while ! [[ $crypt_home_check == "yes" || $crypt_home_check == "no" ]]; do
	crypt_home_check=$(dialog --no-cancel --inputbox "Invalid option:-\nIs $crypt_home_device your home partition name ? (Enter yes or no)" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      done
      [[ $crypt_home_check == "no" ]] && crypt_home_device=$(dialog --no-cancel --inputbox "Enter the root partition device name used for luks encryption:- ( eg : /dev/sda2, /dev/nvme0n1p3, not /dev/mapper/root )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device | tee -a "${logFolder}/refind.log")
      cp "${bootFolder}"/crypt/crypttab /etc/crypttab
      # sed -i "/home_luks_uuid_number/ s/^Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/grub.log"
    fi
  fi
  dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  mkinitcpio -P >/dev/null 2>&1  | tee -a "${logFolder}/refind.log"

  bootType=$(dialog --no-cancel --inputbox "Is boot on separate partition :- ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $bootType == "yes" || $bootType == "no" ]]; do
    bootType=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$bootType" == "yes" ]] ; then
    [[ "$fstype" == "ext4" ]] && sed -i 's/\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    [[ "$fstype" == "btrfs" ]] && sed -i 's/@\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    boot_mount=$(dialog --no-cancel --inputbox "Enter the mount point for boot partition (eg : /boot , /boot/efi)" 10 60 3>&1 1>&2 2>&3 3>&1)
    boot_device=$(findmnt -n -o SOURCE $boot_mount | tee -a "${logfolder}/refind.log")
    # boot_device=$(dialog --no-cancel --inputbox "Enter the boot partition device name:- ( eg : /dev/sda2, /dev/nvme0n1p3 )" 10 60 3>&1 1>&2 2>&3 3>&1 | tee -a "${logFolder}/grub.log")
    boot_uuid=$(blkid -s UUID -o value $boot_device | tee -a "${logfolder}/refind.log")
    sed -i "s/boot_uuid_number/$boot_uuid/" /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    # sed -i "s/=root.*/=root $boot_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  else
    sed -i "s/boot_uuid_number/$root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
  fi

  sed -i "s/root_uuid_number/$root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
  [[ "${fsEncrypt}" == "yes" ]] && sed -i "s/Cbtrfs/$root_name/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"

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

  bootType=$(dialog --no-cancel --inputbox "Is boot on separate partition :- ( yes or no )?" 10 60 3>&1 1>&2 2>&3 3>&1)
  while ! [[ $bootType == "yes" || $bootType == "no" ]]; do
    bootType=$(dialog --no-cancel --inputbox "Invalid option:-\nPlease type 'yes' or 'no'" 10 60 3>&1 1>&2 2>&3 3>&1)
  done
  if [[ "$bootType" == "yes" ]] ; then
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
