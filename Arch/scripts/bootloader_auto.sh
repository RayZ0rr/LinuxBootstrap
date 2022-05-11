#!/usr/bin/env bash

refind_setup()
{
  current_path="$PWD"
  cd "/home/${myName}"
  esp_device=$(mount | grep 'efi ' | cut -d' ' -f 1)
  [ -z "${esp_mount}" ] && esp_mount=$(lsblk -no MOUNTPOINT $esp_device | tee -a "${logFolder}/refind.log")
  dialog --title "Bootloader setup" --infobox "Installing rEFInd which is required to boot the system." 5 70
  refind-install >/dev/null 2>&1 | tee -a "${logFolder}/refind.log"
  dialog --title "Bootloader setup" --infobox "Setting up rEFInd which is required to boot the system." 5 70
  cp ${esp_mount}/EFI/refind/refind.conf ${esp_mount}/EFI/refind/refind_sample.conf | tee -a "${logFolder}/refind.log"
  cp -r "${bootFolder}/refind/themes/refind.conf" ${esp_mount}/EFI/refind | tee -a "${logFolder}/refind.log"
  rsync -avz --delete "${bootFolder}/refind/themes/refind-theme-regular_FINAL/" ${esp_mount}/EFI/refind/themes/refind-theme-regular | tee -a "${logFolder}/refind.log"
  rsync -avz --delete "${bootFolder}/refind/themes/bg.png" ${esp_mount}/EFI/refind/themes/refind-theme-regular/bg.png | tee -a "${logFolder}/refind.log"
  [[ -z "$root_device" ]] && root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  # [[ -z "$root_device" ]] && root_device=$(findmnt -n -o SOURCE / | cut -d '[' -f 1)
  # [[ -z "$root_device" ]] && root_device=$(mount | grep ' / ' | cut -d' ' -f 1)
  root_uuid=$(lsblk -no UUID $root_device | tee -a "${logFolder}/refind.log")
  # root_uuid=$(blkid -s UUID -o value $root_device | tee -a "${logFolder}/grub.log")
  # root_uuid=$(blkid | grep "$root_device" | awk '{for(i=1;i<=NF;++i) if($i~/^UUID=/) print $i}' | cut -d "\"" -f 2)
  [[ -z "$home_device" ]] && home_device=$(df -P /home | cut -d '[' -f 1 | awk 'END{print $1}')
  [[ -z "$fstype" ]] && fstype=$(df -T | grep $root_device | awk '{print $2}')
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
    [[ -z "${root_name}" ]] && root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    [[ -z "${crypt_root_device}" ]] && crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    # [[ -z "${crypt_root_device}" ]] && crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_uuid=$(blkid -s UUID -o value $crypt_root_device | tee -a "${logFolder}/refind.log")
    sed -i "s/luks_uuid_number/$crypt_root_uuid/" /boot/refind_linux.conf | tee -a "${logFolder}/refind.log"
    sed -i 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    sed -i '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed -i "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf | tee -a "${logFolder}/refind.log"
    if [[ "$fstype" == "ext4" ]] ; then
      [[ -z "${home_name}" ]] && home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      [[ -z "${crypt_home_device}" ]] && crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device | tee -a "${logFolder}/refind.log")
      cp "${bootFolder}"/crypt/crypttab /etc/crypttab
      # sed -i "/home_luks_uuid_number/ s/^Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab | tee -a "${logFolder}/refind.log"
      sed -i "s/Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/refind.log"
    fi
  fi
  dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  mkinitcpio -P >/dev/null 2>&1  | tee -a "${logFolder}/grub.log"

  bootType=$(findmnt -n -o FSTYPE $boot_mount)
  if [[ -n "$bootType" ]] ; then
    [[ "$fstype" == "ext4" ]] && sed -i 's/\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    [[ "$fstype" == "btrfs" ]] && sed -i 's/@\\boot\\//g' /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
    [ -z "$boot_device" ] && boot_device=$(findmnt -n -o SOURCE $boot_mount | cut -d '[' -f 1 | tee -a "${logFolder}/grub.log")
    # boot_device=$(df -P /boot | awk 'END{print $1}')
    boot_uuid=$(blkid -s UUID -o value $boot_device | tee -a "${logFolder}/grub.log")
    sed -i "s/boot_uuid_number/$boot_uuid/" /boot/refind_linux.conf | tee -a "${logfolder}/refind.log"
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
  esp_device=$(mount | grep 'efi ' | cut -d' ' -f 1)
  [ -z "${esp_mount}" ] && esp_mount=$(lsblk -no MOUNTPOINT ${esp_device} | tee -a "${logFolder}/grub.log")
  dialog --title "Bootloader setup" --infobox "Installing GRUB which is required to boot the system." 5 70
  grub-install --target=x86_64-efi --efi-directory=${esp_mount} --bootloader-id=Arch > /dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  dialog --title "Bootloader setup" --infobox "Setting up GRUB which is required to boot the system." 5 70
  rsync -avz "${bootFolder}"/grub/themes/dedsec-grub2-theme_FINAL/ /boot/grub/themes/dedsec-grub2-theme/ >/dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  sed -i "s/^#GRUB_THEME=.*/#GRUB_THEME=\"\"\nGRUB_THEME=\"\/boot\/grub\/themes\/dedsec-grub2-theme\/theme.txt\"/" /etc/default/grub | tee -a "${logFolder}/grub.log"
  grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1 | tee -a "${logFolder}/grub.log"
  [[ -z "$root_device" ]] && root_device=$(df -P /etc/fstab | cut -d '[' -f 1 | awk 'END{print $1}')
  # [[ -z "$root_device" ]] && root_device=$(findmnt -n -o SOURCE / | cut -d '[' -f 1)
  # [[ -z "$root_device" ]] && root_device=$(mount | grep ' / ' | cut -d' ' -f 1)
  root_uuid=$(lsblk -no UUID $root_device | tee -a "${logFolder}/refind.log")
  # root_uuid=$(blkid -s UUID -o value $root_device | tee -a "${logFolder}/grub.log")
  # root_uuid=$(blkid | grep "$root_device" | awk '{for(i=1;i<=NF;++i) if($i~/^UUID=/) print $i}' | cut -d "\"" -f 2)
  [[ -z "$home_device" ]] && home_device=$(df -P /home | cut -d '[' -f 1 | awk 'END{print $1}')
  [[ -z "$fstype" ]] && fstype=$(df -T | grep $root_device | awk '{print $2}')
  if [[ "$fstype" == "ext4" ]] ; then
    cp "${bootFolder}"/grub/boot/custom_ext4.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp "${bootFolder}"/grub/boot/custom_ext4_luks.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  elif [[ "$fstype" == "btrfs" ]] ; then
    cp "${bootFolder}"/grub/boot/custom_btrfs.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    [[ "${fsEncrypt}" == "yes" ]] && cp "${bootFolder}"/grub/boot/custom_btrfs_luks.cfg /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  fi
  if [[ "${fsEncrypt}" == "yes" ]] ; then
    [[ -z "${root_name}" ]] && root_name=$(echo "${root_device}" | sed 's#/dev/mapper/##')
    [[ -z "${crypt_root_device}" ]] && crypt_root_device="/dev/$(lsblk -frn | grep "${root_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
    # [[ -z "${crypt_root_device}" ]] && crypt_root_device=$(blkid | grep -i "crypt*" | awk '{print $1}' | cut -d ":" -f 1)
    crypt_root_uuid=$(blkid -s UUID -o value $crypt_root_device | tee -a "${logFolder}/grub.log")
    sed -i "s/luks_uuid_number/$crypt_root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    sed -i 's/^HOOK.*/&\n&/' /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    sed -i '0,/^HOOK.*/s/^HOOK/#HOOK/' /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    hooks="HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)"
    sed -i "s/^HOOK.*/$hooks/" /etc/mkinitcpio.conf | tee -a "${logFolder}/grub.log"
    if [[ "$fstype" == "ext4" ]] ; then
      [[ -z "${home_name}" ]] && home_name=$(echo "${home_device}" | sed 's#/dev/mapper/##')
      [[ -z "${crypt_home_device}" ]] && crypt_home_device="/dev/$(lsblk -frn | grep "${home_name}" -B1 | head -1 | awk '{print $1}' | cut -d '-' -f2)"
      crypt_home_uuid=$(blkid -s UUID -o value $crypt_home_device | tee -a "${logFolder}/grub.log")
      cp "${bootFolder}"/crypt/crypttab /etc/crypttab
      # sed -i "/home_luks_uuid_number/ s/^Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/grub.log"
      sed -i "s/home_luks_uuid_number/$crypt_home_uuid/" /etc/crypttab | tee -a "${logFolder}/grub.log"
      sed -i "s/Chome/$home_name/" /etc/crypttab | tee -a "${logFolder}/grub.log"
    fi
  fi
  dialog --title "Initramfs setup" --infobox "Setting up all initramfs with 'mkinitcpio -P." 5 70
  mkinitcpio -P >/dev/null 2>&1  | tee -a "${logFolder}/grub.log"

  bootType=$(findmnt -n -o FSTYPE $boot_mount)
  if [[ -n "$bootType" ]] ; then
    sed -i 's/\/boot//g' /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
    [ -z "$boot_device" ] && boot_device=$(findmnt -n -o SOURCE $boot_mount | cut -d '[' -f 1 | tee -a "${logFolder}/grub.log")
    # boot_device=$(df -P /boot | awk 'END{print $1}')
    boot_uuid=$(blkid -s UUID -o value $boot_device | tee -a "${logFolder}/grub.log")
    sed -i "s/boot_uuid_number/$boot_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  else
    sed -i "s/boot_uuid_number/$root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  fi

  # sed -i "s/=root.*/=root $root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  # sed -i "s/UUID=.* r/UUID=$root_uuid r/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  sed -i "s/root_uuid_number/$root_uuid/" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"
  [[ "${fsEncrypt}" == "yes" ]] && sed -i "s/Cbtrfs/$root_name/g" /boot/grub/custom.cfg | tee -a "${logFolder}/grub.log"

  cd "$current_path"
}

bootloader_setup()
{
  if [[ "$bootLoader" == "grub" ]] ; then
    grub_setup
  elif [[ "$bootLoader" == "refind" ]] ; then
    refind_setup
  elif [[ "$bootLoader" == "none" ]] ; then
    echo "No bootloader setup during bootstrap."
  fi
}
