#!/bin/bash

################################################
##### Mesa-git
################################################

# References:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git

# Install Mesa git
sudo flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git//22.08
sudo flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git//22.08

# Set default Flatpak GL drivers to mesa-git
sudo flatpak override --env=FLATPAK_GL_DRIVERS=mesa-git

sudo tee -a /etc/environment << EOF

# Flatpak
FLATPAK_GL_DRIVERS=mesa-git
EOF

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//22.08

# Configure MangoHud
mkdir -p ${HOME}/.config/MangoHud

tee ${HOME}/.config/MangoHud/MangoHud.conf << EOF
engine_version
vulkan_driver
EOF

# Allow Flatpaks to access MangoHud configs
sudo flatpak override --filesystem=xdg-config/MangoHud:ro

################################################
##### Steam
################################################

# Install Steam
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# Allow Steam to access external directory
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -O
sudo mv 60-steam-input.rules /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload
sudo udevadm trigger
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
sudo flatpak install -y flathub com.heroicgameslauncher.hgl

# Allow Heroic to access external directory
sudo flatpak override --filesystem=/mnt/data/games/heroic com.heroicgameslauncher.hgl