#!/usr/bin/bash

################################################
##### Applications
################################################

print_section "Applications"

################################################
##### Common Applications
################################################

print_info "Installing common applications"

# Password managers and authentication
install_flatpak_app "com.bitwarden.desktop"
install_flatpak_app "com.belmoussaoui.Authenticator"
install_flatpak_app "org.keepassxc.KeePassXC"

# Media and entertainment
install_flatpak_app "com.spotify.Client"
install_flatpak_app "org.gimp.GIMP"
install_flatpak_app "org.blender.Blender"

# Browsers
install_flatpak_app "com.brave.Browser"

# Note-taking
install_flatpak_app "md.obsidian.Obsidian"

################################################
##### Development Applications
################################################

print_info "Installing development applications"

# API testing and database tools
install_flatpak_app "com.usebruno.Bruno"
install_flatpak_app "com.github.marhkb.Pods"
install_flatpak_app "dev.skynomads.Seabird"
install_flatpak_app "org.sqlitebrowser.sqlitebrowser"
install_flatpak_app "io.beekeeperstudio.Studio"

################################################
##### Office and Documents
################################################

print_info "Installing office and document applications"

# Remove LibreOffice (native)
sudo dnf group remove -y libreoffice
sudo dnf remove -y *libreoffice*

# Install LibreOffice (Flatpak)
install_flatpak_app "org.libreoffice.LibreOffice"

# Install diagram and note-taking tools
install_flatpak_app "org.gaphor.Gaphor"
install_flatpak_app "com.github.flxzt.rnote"

################################################
##### Bottles (Windows compatibility)
################################################

print_info "Installing Bottles"

# Install Bottles
install_flatpak_app "com.usebottles.bottles"

# Configure MangoHud for Bottles
mkdir -p ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud/MangoHud.conf

print_info "Applications installation completed"