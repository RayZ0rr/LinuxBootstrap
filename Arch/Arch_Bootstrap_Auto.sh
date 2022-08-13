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

doDotfilesSetup="no"
doNvimSetup="no"
doSucklessSetup="no"
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

error() { printf "%s\n" "$1" >&2; exit 1; }

welcomemsg() { \
  dialog --title "Welcome!" --msgbox "Welcome to Auto Bootstrapping Script!\\n\\nThis script will guide through installation of a fully-featured Arch Linux desktop system.\\n" 10 60

  dialog --colors --title "Extra Note" --msgbox "logs of various commands output are placed in \"${logFolder} and ~/bootstrapLogs after successful completion\".\\n" 10 60

  mkdir -p "${logFolder}"
  }

usercheck() { \
  ! { id -u "$myName" >/dev/null 2>&1; } ||
  dialog --colors --title "WARNING!" --yes-label "CONTINUE" --no-label "No wait..." --yesno "The user \`$myName\` already exists on this system. LARBS can install for a user already existing, but it will \\Zboverwrite\\Zn any conflicting settings/dotfiles on the user account.\\n\\nLARBS will \\Zbnot\\Zn overwrite your user files, documents, videos, etc., so don't worry about that, but only click <CONTINUE> if you don't mind your settings being overwritten.\\n\\nNote also that LARBS will change $myName's password to the one you just gave." 14 70
  }

preinstallmsg() { \
  dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit 1; }
  }

newperms() { # Set special sudoers settings for install (or after).
  sed -i "/#Arch_Boostrap_Auto(ABA) Script settings/d" /etc/sudoers
  echo "$* #ABA" >> /etc/sudoers ;}

sudo_perms()
{
  echo "#Arch_Boostrap_Auto(ABA) Script settings" >> /etc/sudoers.d/"$myName"
  echo "%wheel ALL=(AL:ALLL) ALL    # ABA" >> /etc/sudoers.d/"$myName"
  echo "%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syu --noconfirm,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/paru,/usr/bin/pacman -Syyuw --noconfirm   #ABA" >> /etc/sudoers.d/"$myName"
}

finalize(){ \
  dialog --infobox "Preparing welcome message..." 4 50
  dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the 'Arch_Boostrap_Auto' script completed successfully and all the programs and configuration files should be in place.\\nUnless manually edited or provided through -u and -k flags, the default username and password are luke and ermanno\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1) or a display/login manager ( eg: lightdm, sddm )." 12 80
  dialog --colors --title "Extra Note" --msgbox "logs of various commands output are placed in \"${logFolder} and ~/bootstrapLogs after successful completion\".\\n" 10 60
  sudo -u "$myName" cp -r "${logFolder}" /home/${myName}/bootstrapLogs
  }

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
pacman --noconfirm --needed -Sy dialog archlinux-keyring || error "Are you sure you're running this as the root user, are on an Arch-based distribution and have an internet connection?"

# Welcome user and pick dotfiles.
welcomemsg || error "User exited."

# Give warning if user already exists.
usercheck || error "User exited."

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

source "${bootstrapFolder}"/scripts/general_settings_setup.sh
source "${bootstrapFolder}"/scripts/installation_setup.sh

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL:ALL) NOPASSWD: ALL"

# Set and verify username and password.
adduserandpass || error "Error adding username and/or password."

data_locale

# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -i "s/^#ParallelDownloads = 8$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf

manualinstall yay-bin || error "Failed to install AUR helper(yay)."

[ "$aurhelper" = "yay" ] && yay -Y --devel --combinedupgrade --save

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's custom dotfiles directory
source "${bootstrapFolder}"/scripts/bootloader_auto.sh
putgitrepo "$bootrepo" "${myGitFolder}/LinuxBoot" "$repobranch"
bootloader_setup

# Install the dotfiles in the user's custom dotfiles directory
if [[ "$doDotfilesSetup" == "yes" ]] ; then
  source "${bootstrapFolder}"/scripts/dotfiles_setup.sh
  putgitrepo "$dotfilesrepo" "${myDots}" "$repobranch"
  setup_dotfiles_config
fi
if [[ "$doNvimSetup" == "yes" ]] ; then
  source "${bootstrapFolder}"/scripts/nvim_setup.sh
  putgitrepo "$nvimrepo" "${myGitFolder}/myNeovim" "$repobranch"
  setup_nvim_config

fi
if [[ "$doSucklessSetup" == "yes" ]] ; then
  source "${bootstrapFolder}"/scripts/suckless_setup.sh
  putgitrepo "$sucklessrepo" "${myGitFolder}/mySuckless" "$repobranch"
  setup_suckless_config
fi

systemd_units_enable

# Most important command! Get rid of the beep!
systembeepoff

# Make zsh the default shell for the user.
# chsh -s /bin/zsh "$myName" >/dev/null 2>&1
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

# Last message! Install complete!
finalize
clear
printf "\e[1;32mDone! Type exit, umount -a and reboot.\n\e[0m"
