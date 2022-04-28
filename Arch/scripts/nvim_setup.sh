#!/usr/bin/env bash

setup_nvim_config(){
  current_path="$PWD"
  cd "/home/${myName}"
  # Requires the software stow (GNU/stow)
  # Symlink and setup .config for nvim folder from myNeovim repo ($mynvim)
  ! [[ -d "/home/${myName}/.config/nvim" ]] && sudo -u "$myName" mkdir -p "/home/${myName}/.config/nvim" | tee -a "${logFolder}/nvim.log"
  dialog --title "Dotfiles Setup" --infobox "Setting up Neovim at ~/.config/nvim from ~/${myGitFolder}/myNeovim." 5 70
  sudo -u "$myName" stow -v --no-folding -t ".config/nvim" -d "${myGitFolder}/myNeovim" -S "nvim" | tee -a "${logFolder}/nvim.log"
  cd "$current_path"
}
