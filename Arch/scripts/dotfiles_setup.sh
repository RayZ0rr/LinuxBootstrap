#!/usr/bin/env bash

setup_dotfiles_config(){
  current_path="$PWD"
  cd "/home/${myName}"
  # Requires the software stow (GNU/stow)
  # Symlink and setup .config files from dotfiles repo ($HOME/$myDots)
  dialog --title "Dotfiles Setup" --infobox "Setting ~/.config files and folders from ~/$myDots/.config." 5 70
  ! [[ -d "/home/${myName}/.config" ]] && sudo -u "$myName" mkdir -p "/home/${myName}/.config" | tee -a "${logFolder}/setupLocalConfig.log"
  for i in "bash" "zsh" "herbstluftwm" "i3" "polybar" "sxhkd" "rofi" "alacritty" "vifm" "picom" "conky" "dunst" "tmux" "jgmenu" "zathura" "myCronJobs" "bottom" "bat" "starshipPrompt" "neofetch"
  do
    ! [[ -d ".config/${i}" ]] && sudo -u "$myName" mkdir -p ".config/${i}" | tee -a "${logFolder}/setupLocalConfig.log"
    sudo -u "$myName" stow -v --no-folding -t ".config/$i" -d "${myDots}/.config" -S "$i" > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
    addBar "${logFolder}/setupLocalConfig.log"
  done
  cd .config
  sudo -u "$myName" ln -sf ../"${myDots}/.config/stalonetrayrc" stalonetrayrc > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  cd ..
  # rm ~/.config/i3/scripts/spawnClients.sh
  cp "${myDots}/ROOT/etc/zsh/zshrc" /etc/zsh/ > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  # Symlink and setup .local files, mainly ".local/bin", from dotfiles repo ($HOME/$myDots)
  dialog --title "Dotfiles Setup" --infobox "Setting up ~/.local directory with files and folders from ~/$myDots/.local." 5 70
  ! [[ -d "/home/${myName}/.local/bin" ]] && sudo -u "$myName" mkdir -p "/home/${myName}/.local/bin" | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" stow -v --no-folding -t ".local/bin" -d "${myDots}/.local" -S "bin" > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" cp -r "${myDots}/.local/src"/*.png .local/src/ > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" rsync -avz "${myDots}/.local/share/rofi/themes" .local/src/rofi/ > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  dialog --title "Dotfiles Setup" --infobox "Setting up fonts in ~/.local/share/fonts directory.\nUse 'fc-cache -fv' after login to load fonts." 5 70
  sudo -u "$myName" "${bootstrapFolder}"/scripts/myfonts get > /dev/null 2>&1 | tee -a "${logFolder}/myfonts.log"
  dialog --title "Dotfiles Setup" --infobox "Setting up dotfiles in home directory like .bashrc from ~/$myDots/HOME." 5 70
  sudo -u "$myName" ln -sf "${myDots}/HOME/.bashrc" .bashrc > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" ln -sf "${myDots}/HOME/.zshenv" .zshenv_hold > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" touch .zshrc > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" ln -sf "${myDots}/HOME/.profile" .profile > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" ln -sf "${myDots}/HOME/.ignore" .ignore > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" ln -sf "${myDots}/HOME/.tmux.conf" .tmux.conf > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  sudo -u "$myName" ln -sf "${myDots}/HOME/.Xresources" .Xresources > /dev/null 2>&1 | tee -a "${logFolder}/setupLocalConfig.log"
  printf "[General]\nNumlock=on\n[Theme]\nCurrent=astronaut" >> /etc/sddm.conf | tee -a "${logFolder}/setupLocalConfig.log"
  cp "${bootstrapFolder}"/scripts/firstStart.sh ./firstStart.sh
  cd "$current_path"
}
