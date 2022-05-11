#!/usr/bin/env bash

data_locale()
{
  ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime | tee -a "${logFolder}/etc_setup.log"
  hwclock --systohc | tee -a "${logFolder}/etc_setup.log"
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  echo "en_IN UTF-8  " >> /etc/locale.gen
  # sed -i '177s/.//' /etc/locale.gen
  # sed -i '168s/.//' /etc/locale.gen
  locale-gen > /dev/null 2>&1 | tee -a "${logFolder}/etc_setup.log"
  echo "LANG=en_US.UTF-8" >> /etc/locale.conf
  echo "KEYMAP=us" >> /etc/vconsole.conf
  echo "${myHostname}" >> /etc/hostname
  echo "127.0.0.1 localhost" >> /etc/hosts
  echo "::1       localhost" >> /etc/hosts
  echo "127.0.1.1 ${myHostname}.localdomain ${myHostname}" >> /etc/hosts
  addBar
}

systemd_units_enable()
{
  systemctl enable sddm > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable bluetooth > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable NetworkManager > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable ufw > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  # systemctl enable docker > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
}

adduserandpass() { \
  # Adds user `$myName` with password $pass1.
  dialog --infobox "Adding user \"$myName\"..." 4 50
  useradd -m -G wheel,audio,video "$myName" >/dev/null 2>&1 | tee -a "${logFolder}/etc_setup.log"
  export repodir="/home/$myName/.local/src"; sudo -u "$myName" mkdir -p "$repodir" | tee -a "${logFolder}/etc_setup.log"; chown -R "$myName":"$myName" "$(dirname "$repodir")" | tee -a "${logFolder}/etc_setup.log"
  echo "$myName:$pass1" | chpasswd
  unset pass1 pass2 ;}

systembeepoff() { dialog --infobox "Getting rid of that retarded error beep sound..." 10 50
  rmmod pcspkr
  echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

refreshkeys() { \
  case "$(readlink -f /sbin/init)" in
    *systemd* )
      dialog --infobox "Refreshing Arch Keyring..." 4 40
      pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
      ;;
    *)
      dialog --infobox "Enabling Arch Repositories..." 4 40
      pacman --noconfirm --needed -S artix-keyring artix-archlinux-support >/dev/null 2>&1
      for repo in extra community; do
        grep -q "^\[$repo\]" /etc/pacman.conf ||
          echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
      done
      pacman -Sy >/dev/null 2>&1
      pacman-key --populate archlinux
      ;;
  esac ;}
