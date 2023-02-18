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

################################################
##### Emulators
################################################

sudo flatpak install -y flathub org.duckstation.DuckStation # psx
sudo flatpak install -y flathub net.pcsx2.PCSX2 # ps2
sudo flatpak install -y flathub org.ppsspp.PPSSPP # psp
sudo flatpak install -y flathub org.DolphinEmu.dolphin-emu # gamecube / wii
sudo flatpak install -y flathub org.yuzu_emu.yuzu # switch
sudo flatpak install -y flathub org.citra_emu.citra # 3ds
sudo flatpak install -y flathub org.flycast.Flycast # dreamcast
sudo flatpak install -y flathub app.xemu.xemu # xbox
sudo flatpak install -y flathub com.snes9x.Snes9x # snes
sudo flatpak install -y flathub net.kuribo64.melonDS # ds