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

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
sudo flatpak install -y flathub com.heroicgameslauncher.hgl

################################################
##### Lutris
################################################

# Install GNOME Compat and GL32 extensions
sudo flatpak install -y flathub org.gnome.Platform.Compat.i386//22.08
sudo flatpak install -y flathub org.freedesktop.Platform.GL32.default//22.08
sudo flatpak install -y flathub org.freedesktop.Platform.GL.default//22.08

# Install Lutris
sudo flatpak install -y flathub net.lutris.Lutris