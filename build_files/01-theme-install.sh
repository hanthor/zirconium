#!/bin/bash

set -xeuo pipefail

# Standard Packages (CentOS/EPEL/Fedora)
STANDARD_PACKAGES=(
    chezmoi
    ddcutil
    fastfetch
    flatpak
    fpaste
    fzf
    git-core
    gnome-keyring
    gnome-keyring-pam
    # greetd
    # greetd-selinux
    just
    iniparser
    libwayland-server
    nautilus
    orca
    pipewire
    steam-devices
    webp-pixbuf-loader
    wireplumber
    wl-clipboard
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    xdg-user-dirs

    # Fonts & Emoji
    default-fonts-core-emoji
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    glibc-all-langpacks
    default-fonts
)

dnf -y install \
    "${STANDARD_PACKAGES[@]}"
