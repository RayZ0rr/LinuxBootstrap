#!/usr/bin/env bash

scriptFolder=$(dirname $(readlink -f $0))

case "${1}" in
  "make")
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/*
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/icons/*
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/background.png
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/dedsec/* "${scriptFolder}"/dedsec-grub2-theme_FINAL/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/icons/ "${scriptFolder}"/dedsec-grub2-theme_FINAL/icons/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/backgrounds/wrench.png "${scriptFolder}"/dedsec-grub2-theme_FINAL/background.png
    ;;
  "sync")
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/dedsec/* "${scriptFolder}"/dedsec-grub2-theme_FINAL/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/icons/ "${scriptFolder}"/dedsec-grub2-theme_FINAL/icons/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/backgrounds/wrench.png "${scriptFolder}"/dedsec-grub2-theme_FINAL/background.png
    sudo rsync -rltP --delete "${scriptFolder}"/dedsec-grub2-theme_FINAL/* /boot/grub/themes/dedsec-grub2-theme/
    ;;
  "rm")
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/*
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/icons/*
    rm -rf "${scriptFolder}"/dedsec-grub2-theme_FINAL/background.png
    ;;
  "up")
    git --git-dir="${scriptFolder}"/dedsec-grub2-theme/.git --work-tree="${scriptFolder}"/dedsec-grub2-theme pull
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/dedsec/* "${scriptFolder}"/dedsec-grub2-theme_FINAL/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/icons/ "${scriptFolder}"/dedsec-grub2-theme_FINAL/icons/
    rsync -avzP --delete "${scriptFolder}"/dedsec-grub2-theme/assets/backgrounds/wrench.png "${scriptFolder}"/dedsec-grub2-theme_FINAL/background.png
    ;;
  *)
    echo "No option or invalid option." ;
    echo "Try maketheme.sh {options}";
    printf "Options : sync (sync themes from here to /boot/grub/themes/dedsec-grub2-theme).\nmake (for copying themes from dedsec-grub2-themes to dedsec-grub2-theme_FINAL),\n rm (to remove), up ( to remove and then copy)";
    ;;
esac
