#!/usr/bin/env bash

setup_suckless_config(){
  current_path="$PWD"
  cd "/home/${myName}"
  # Build and setup suckless tools ( st and dmenu ).
  dialog --title "Suckless tools Setup" --infobox "Setting up st and dmenu from ~/${myGitFolder}/mySuckless." 5 70
  cd "${myGitFolder}"/mySuckless
  sudo -u "$myName" git submodule update --init --recursive
  sudo -u "$myName" git submodule foreach --recursive git checkout current
  sudo -u "$myName" git submodule update --remote
  cd tools/mySt
  make clean install
  cd tools/myDmenu
  make clean install
  cd "$current_path"
}
