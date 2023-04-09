#!/usr/bin/bash

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/22.08

# Configure MangoHud
mkdir -p ${HOME}/.config/MangoHud

tee ${HOME}/.config/MangoHud/MangoHud.conf << EOF
engine_version
vulkan_driver
EOF

# Allow Flatpaks to access MangoHud configs
sudo flatpak override --filesystem=xdg-config/MangoHud:ro

################################################
##### Platforms
################################################

# Steam
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# Heroic Games Launcher
sudo flatpak install -y flathub com.heroicgameslauncher.hgl

# Lutris
sudo flatpak install -y flathub net.lutris.Lutris

# ProtonUp-Qt
sudo flatpak install -y flathub net.davidotek.pupgui2