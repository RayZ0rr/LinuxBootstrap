#!/usr/bin/env bash

scriptFolder=$(dirname $(readlink -f $0))
progsfile="${scriptFolder}/progs.csv"
myName="$(whoami)"
repodir="$HOME/.local/src"
logFolder="$HOME/.local/src/logs"
mkdir -p $logFolder
aurhelper="yay"
repobranch="main"

pacman -S dialog

installpkg(){ pacman --noconfirm --needed -S "$1" ;}

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
  dialog --infobox "Downloading and installing config files..." 4 60
  [ -z "$3" ] && branch="$repobranch" || branch="$3"
  dir=$(mktemp -d)
  [ ! -d "$2" ] && sudo -u "$myName" mkdir -p "$2" | tee -a "${logFolder}/putgitrepo.log"
  chown "$myName":"$myName" "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" >/dev/null 2>&1 | tee -a "${logFolder}/putgitrepo.log"
  sudo -u "$myName" cp -rfT "$dir" "$2" | tee -a "${logFolder}/putgitrepo.log"
  cd "$current_path"
  }

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
  installpkg "$x" >/dev/null 2>&1 | tee -a "${logFolder}/essential_packages.log"
done

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
