#!/usr/bin/env bash

scriptFolder=$(dirname $(readlink -f $0))

case "${1}" in
  "make")
    rm -rf "${scriptFolder}"/refind-theme-regular_FINAL/*
    rsync -avz --delete "${scriptFolder}"/refind-theme-regular/ "${scriptFolder}"/refind-theme-regular_FINAL/
    rm -rf "${scriptFolder}"/refind-theme-regular_FINAL/{.git,LICENSE,install.sh,README.md,src}
    # sed -i "s/refind-theme-regular/refind-theme-regular_FINAL/" "${scriptFolder}"/refind-theme-regular_FINAL/theme.conf
    ;;
  "sync")
    rsync -avz --delete "${scriptFolder}"/refind-theme-regular/ "${scriptFolder}"/refind-theme-regular_FINAL/
    rm -rf "${scriptFolder}"/refind-theme-regular_FINAL/{.git,LICENSE,install.sh,README.md,src}
    # sed -i "s/refind-theme-regular/refind-theme-regular_FINAL/" "${scriptFolder}"/refind-theme-regular_FINAL/theme.conf
    sudo rsync -rltP --delete "${scriptFolder}"/refind-theme-regular_FINAL/ /boot/efi/EFI/refind/themes/refind-theme-regular
    sudo rsync -rltP --delete "${scriptFolder}"/bg.png /boot/efi/EFI/refind/themes/refind-theme-regular/
    ;;
  "rm")
    rm -rf "${scriptFolder}"/refind-theme-regular_FINAL/*
    ;;
  "up")
    git --git-dir="${scriptFolder}"/refind-theme-regular/.git --work-tree="${scriptFolder}"/refind-theme-regular pull
    rsync -avz --delete "${scriptFolder}"/refind-theme-regular/ "${scriptFolder}"/refind-theme-regular_FINAL/
    rm -rf "${scriptFolder}"/refind-theme-regular_FINAL/{.git,LICENSE,install.sh,README.md,src}
    # sed -i "s/refind-theme-regular/refind-theme-regular_FINAL/" "${scriptFolder}"/refind-theme-regular_FINAL/theme.conf
    ;;
  *)
    echo "No option or invalid option." ;
    echo "Try maketheme.sh {options}";
    printf "Options : sync (sync themes from here to /boot/efi/EFI/refind/themes/refind-theme-regular).\nmake (for copying themes from refind-theme-regular to refind-theme-regular_FINAL),\n rm (to remove), up ( to remove and then copy)";
    ;;
esac
