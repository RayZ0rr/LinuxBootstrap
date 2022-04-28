#!/usr/bin/env bash
# Author: RayZ0rr (github.com/RayZ0rr)
# Arch Bootstrap Automatic script (ABA)
# A fork of Luke's Auto Rice Boostrapping Script (LARBS)
# by Luke Smith <luke@lukesmith.xyz>
# and
# Ermanno Ferrari's Pulic Arch install script
# https://gitlab.com/eflinux/arch-basic
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

while getopts ":a:f:r:b:p:u:k:h" o; do case "${o}" in
  h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -p: Dependencies and programs csv (local file or url)\\n  -a: AUR helper (must have pacman-like syntax)\\n  -h: Show this message\\n" && exit 1 ;;
  r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit 1 ;;
  b) repobranch=${OPTARG} ;;
  p) progsfile=${OPTARG} ;;
  a) aurhelper=${OPTARG} ;;
  u) myName=${OPTARG} ;;
  k) myPass=${OPTARG} ;;
  f) fstype=${OPTARG} ;;
  l) bootLoader=${OPTARG} ;;
  *) printf "Invalid option: -%s\\n" "$OPTARG" && exit 1 ;;
esac done

# bootstrapFolder=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
bootstrapFolder=$(dirname $(readlink -f $0))
logFolder="/tmp/bootstrapLogs"
alias la="ls -al"

doDotfilesSetup="yes"
doNvimSetup="yes"
doSucklessSetup="yes"
[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/RayZ0rr/dotfiles.git"
[ -z "$bootrepo" ] && bootrepo="https://github.com/RayZ0rr/LinuxBoot.git"
[ -z "$nvimrepo" ] && nvimrepo="https://github.com/RayZ0rr/myNeovim.git"
[ -z "$sucklessrepo" ] && sucklessrepo="https://github.com/RayZ0rr/mySuckless.git"
[[ -z "$doDotfilesSetup" || -z "$dotfilesrepo" ]] && doDotfilesSetup="no"
[[ -z "$doNvimSetup" || -z "$nvimrepo" ]] && doNvimSetup="no"
[[ -z "$doSucklessSetup" || -z "$sucklessrepo" ]] && doSucklessSetup="no"
[ -z "$progsfile" ] && progsfile="${bootstrapFolder}/progs.csv"
[ -z "$progsURL" ] && progsURL="https://raw.githubusercontent.com/RayZ0rr/LinuxBootstrap/main/Arch/progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="main"
[ -z "$fstype" ] && fstype="btrfs"
[ -z "$bootLoader" ] && bootLoader="grub"
[ -z "$esp" ] && esp="/efi"
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
# -----------------------------------------------------
# User details
# -----------------------------------------------------
[ -z "$myName" ] && myName="luke"
[ -z "$myHostname" ] && myHostname="linuxsys"
[ -z "$myPass" ] && myPass="ermanno"
# -----------------------------------------------------
# Dotfiles path from home folder ( ~ or /home/<username>)
# -----------------------------------------------------
[ -z "$myDots" ] && myDots="gFolder/RaZ0rr/github/dotfiles"
[ -z "$myGitFolder" ] && myGitFolder="gFolder/RaZ0rr"
[ -z "$bootFolder" ] && bootFolder="${myGitFolder}/LinuxBoot"
[ -z "$bootrepo" ] && bootFolder="${bootstrapFolder}/LinuxBoot"

### FUNCTIONS ###

addBar(){
  printf "\n--------------------------------------\n" >> "$1"
}

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
# echo "$myName":"$myPass" | chpasswd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

# pacman -S refind networkmanager network-manager-applet dialog mtools dosfstools base-devel linux-headers linux-lts-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils bluez blueman pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync gufw ntfs-3g terminus-font

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

systemd_units_enable()
{
  systemctl enable sddm > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable bluetooth > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable NetworkManager > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable ufw > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
  systemctl enable docker > /dev/null 2>&1 | tee -a "${logFolder}/systemd_units.log"
}

user_and_pass()
{
  useradd -m "$myName" | tee -a "${logFolder}/etc_setup.log"
  echo "$myName":"$myPass" | chpasswd
  usermod -aG wheel,audio,video "$myName" | tee -a "${logFolder}/etc_setup.log"
  export repodir="/home/$myName/.local/src"; sudo -u "$myName" mkdir -p "$repodir" | tee -a "${logFolder}/etc_setup.log"; chown -R "$myName":"$myName" "$(dirname "$repodir")" | tee -a "${logFolder}/etc_setup.log"
}

newperms() { # Set special sudoers settings for install (or after).
  sed -i "/#Arch_Boostrap_Auto(ABA) Script settings/d" /etc/sudoers
  echo "$* #ABA" >> /etc/sudoers ;}

sudo_perms()
{
  echo "#Arch_Boostrap_Auto(ABA) Script settings" >> /etc/sudoers.d/"$myName"
  echo "%wheel ALL=(ALL) ALL    # ABA" >> /etc/sudoers.d/"$myName"
  echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syu --noconfirm,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/paru,/usr/bin/pacman -Syyuw --noconfirm,/usr/bin/yay   #ABA" >> /etc/sudoers.d/"$myName"
}

installpkg(){ pacman --noconfirm --needed -S "$1" ;}

error() { printf "%s\n" "$1" >&2; exit 1; }

welcomemsg() { \
  dialog --title "Welcome!" --msgbox "Welcome to Auto Bootstrapping Script!\\n\\nThis script will guide through installation of a fully-featured Arch Linux desktop system.\\n" 10 60

  dialog --colors --title "Extra Note" --msgbox "logs of various commands output are placed in \"${logFolder} and ~/bootstrapLogs after successful completion\".\\n" 10 60

  mkdir -p "${logFolder}"
  }

manualinstall() { # Installs $1 manually. Used only for AUR helper here.
  # Should be run after repodir is created and var is set.
  dialog --infobox "Installing \"$1\", an AUR helper..." 4 50
  sudo -u "$myName" mkdir -p "$repodir/$1" | tee -a "${logFolder}"/aurhelper.log
  sudo -u "$myName" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 | tee -a "${logFolder}"/aurhelper.log ||
    { cd "$repodir/$1" || return 1 ; sudo -u "$myName" git pull --force origin master | tee -a "${logFolder}"/aurhelper.log;}
  cd "$repodir/$1"
  sudo -u "$myName" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 | tee -a "${logFolder}"/aurhelper.log || return 1
}

maininstall() { # Installs all needed programs from main repo.
  dialog --title "ABM Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
  installpkg "$1" >/dev/null 2>&1 | tee -a "${logFolder}"/maininstall.log
  addBar "${logFolder}"/maininstall.log
  }

gitmakeinstall() {
  progname="$(basename "$1" .git)"
  dir="$repodir/$progname"
  dialog --title "ABM Installation" --infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
  sudo -u "$myName" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return 1 ; sudo -u "$myName" git pull --force origin master;}
  cd "$dir" || exit 1
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  cd /tmp || return 1 ;}

aurinstall() { \
  dialog --title "Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 5 70
  echo "$aurinstalled" | grep -q "^$1$" && return 1
  sudo -u "$myName" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1 | tee -a "${logFolder}/aurhelper.log"
  }

pipinstall() { \
  dialog --title "LARBS Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
  [ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
  yes | pip install "$1" >/dev/null 2>&1 | tee -a "${logFolder}/pipInstall.log"
  }

installationloop() { \
  ([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsURL" | sed '/^#/d' > /tmp/progs.csv
  sed -i '/^#/d' /tmp/progs.csv
  total=$(wc -l < /tmp/progs.csv)
  aurinstalled=$(pacman -Qqm)
  while IFS=, read -r tag program comment; do
    n=$((n+1))
    echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
    case "$tag" in
      "A") aurinstall "$program" "$comment" ;;
      "G") gitmakeinstall "$program" "$comment" ;;
      "P") pipinstall "$program" "$comment" ;;
      *) maininstall "$program" "$comment" ;;
    esac
  done < /tmp/progs.csv ;}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
  current_path="$PWD"
  cd "/home/${myName}"
  dialog --infobox "Downloading config files..." 4 60
  [ -z "$3" ] && branch="$repobranch" || branch="$3"
  dir=$(mktemp -d)
  [ ! -d "$2" ] && sudo -u "$myName" mkdir -p "$2" | tee -a "${logFolder}/putgitrepo.log"
  chown "$myName":"$myName" "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" >/dev/null 2>&1 | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" cp -rfT "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  cd "$current_path"
  }

source "${bootstrapFolder}"/scripts/bootloader_auto.sh

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

source "${bootstrapFolder}"/scripts/dotfiles_setup.sh
source "${bootstrapFolder}"/scripts/nvim_setup.sh
source "${bootstrapFolder}"/scripts/suckless_setup.sh

systembeepoff() { dialog --infobox "Getting rid of that retarded error beep sound..." 10 50
  rmmod pcspkr
  echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

finalize(){ \
  dialog --infobox "Preparing welcome message..." 4 50
  dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the 'Arch_Boostrap_Auto' script completed successfully and all the programs and configuration files should be in place.\\nUnless manually edited or provided through -u and -k flags, the default username and password are luke and ermanno\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1) or a display/login manager ( eg: lightdm, sddm )." 12 80
  dialog --colors --title "Extra Note" --msgbox "logs of various commands output are placed in \"${logFolder} and ~/bootstrapLogs after successful completion\".\\n" 10 60
  sudo -u "$myName" cp -r "${logFolder}" /home/${myName}/bootstrapLogs
  }

# Check if user is root on Arch distro. Install dialog.
pacman --noconfirm --needed -Sy dialog archlinux-keyring || error "Are you sure you're running this as the root user, are on an Arch-based distribution and have an internet connection?"

# Welcome user and pick dotfiles.
welcomemsg || error "User exited."

for x in curl git wget python-pip ca-certificates rsync base-devel python-wheel zsh stow efibootmgr; do
  # dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to install and configure other programs." 5 70
  if [[ "$x" == "stow" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to symlink configuration files." 5 70
  elif [[ "$x" == "rsync" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to copy configuration files." 5 70
  elif [[ "$x" == "efibootmgr" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required for bootloader." 5 70
  elif [[ "$x" == "base-devel" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to install from aur." 5 70
  elif [[ "$x" == "python-pip" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to install with python." 5 70
  elif [[ "$x" == "python-wheel" ]] ; then
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to install with python pip." 5 70
  else
    dialog --title "Essential package installation" --infobox "Installing \`$x\` which is required to install and configure other programs." 5 70
  fi
  installpkg "$x" | tee -a "${logFolder}/essential_packages.log"
done

user_and_pass || error "Error adding username and/or password."

data_locale

# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -i "s/^#ParallelDownloads = 8$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

manualinstall yay-bin || error "Failed to install AUR helper(yay)."

[ "$aurhelper" = "yay" ] && yay -Y --devel --combinedupgrade --save

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's custom dotfiles directory
putgitrepo "$bootrepo" "${myGitFolder}/LinuxBoot" "$repobranch"
bootloader_setup

[ "$doDotfilesSetup" == "yes" ] && putgitrepo "$dotfilesrepo" "${myDots}" "$repobranch"
[ "$doDotfilesSetup" == "yes" ] && setup_dotfiles_config

[ "$doNvimSetup" == "yes" ] && putgitrepo "$nvimrepo" "${myGitFolder}/myNeovim" "$repobranch"
[ "$doNvimSetup" == "yes" ] && setup_nvim_config

[ "$doSucklessSetup" == "yes" ] && putgitrepo "$sucklessrepo" "${myGitFolder}/mySuckless" "$repobranch"
[ "$doSucklessSetup" == "yes" ] && setup_suckless_config

systemd_units_enable

# Most important command! Get rid of the beep!
systembeepoff

sudo -u "$myName" mkdir -p "/home/$myName/.cache"

# Tap to click
[ ! -f /etc/X11/xorg.conf.d/30-touchpad.conf ] && printf 'Section "InputClass"
  Identifier "libinput touchpad catchall"
  Driver "libinput"
  MatchIsTouchpad "on"
  MatchDevicePath "/dev/input/event*"
  # Enable left mouse button by tapping
  Option "Tapping" "on"
  Option "NaturalScrolling" "true"
  Option "TappingButtonMap" "lrm"
EndSection' > /etc/X11/xorg.conf.d/30-touchpad.conf

# Reset user permissions.
newperms "#%wheel ALL=(ALL) ALL"

sudo_perms

finalize
clear
printf "\e[1;32mDone! Type exit, umount -a and reboot.\n\e[0m"
