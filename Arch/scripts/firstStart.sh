#!/usr/bin/env bash

rm .zshrc
mv .zshenv_hold .zshenv
systemctl --user enable clipmenud
fc-cache -fv
pacman -Qtdq | sudo pacman -Rns -
