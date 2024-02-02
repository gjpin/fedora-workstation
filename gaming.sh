#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08

# Install Gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08

# Install Feral Gamemode
sudo dnf install -y gamemode

################################################
##### Steam
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.valvesoftware.Steam -o ${HOME}/.local/share/flatpak/overrides/com.valvesoftware.Steam

# Create directory for Steam games
mkdir -p ${HOME}/games/steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules

# Allow Steam to open other applications (eg. Heroic)
flatpak override --user --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam

# Configure MangoHud for Steam
mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud
tee ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf << EOF
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.heroicgameslauncher.hgl -o ${HOME}/.local/share/flatpak/overrides/com.heroicgameslauncher.hgl

# Create directory for Heroic games
mkdir -p ${HOME}/games/heroic

# Configure Heroic
mkdir -p ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/heroic
tee ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/heroic/config.json << EOF
{
  "defaultSettings": {
    "defaultInstallPath": "${HOME}/games/heroic",
    "defaultSteamPath": "${HOME}/.var/app/com.valvesoftware.Steam/.steam/steam/",
    "defaultWinePrefix": "${HOME}/games/heroic/prefixes",
    "winePrefix": "${HOME}/games/heroic/prefixes/default",
    "enviromentOptions": [
      {
        "key": "WINE_LARGE_ADDRESS_AWARE",
        "value": "0"
      }
    ],
  },
  "version": "v0"
}
EOF

################################################
##### Sunshine
################################################

# References:
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/installation.html#rpm-package
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/usage.html#linux
# https://github.com/LizardByte/Sunshine/blob/master/sunshine.service.in
# https://github.com/LizardByte/Sunshine

# Download Sunshine
curl https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -L -O

# Install Sunshine
sudo dnf install -y sunshine-fedora-$(rpm -E %fedora)-amd64.rpm

# Clean rpm
rm -f sunshine-fedora-$(rpm -E %fedora)-amd64.rpm

# Allow Sunshine Virtual Input
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/85-sunshine-input.rules

# Create Sunshine service
tee ${HOME}/.config/systemd/user/sunshine.service << EOF
[Unit]
Description=Sunshine self-hosted game stream host for Moonlight.
StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
ExecStart=/usr/bin/sunshine
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=graphical-session.target
EOF

# Fix Sunshine service in Gnome
if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
  sed -i '3 i After=gnome-session-wayland@gnome.target' ${HOME}/.config/systemd/user/sunshine.service
fi

# Enable Sunshine service
systemctl --user enable sunshine.service

# Allow Sunshine to use KMS
sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))

# Import configs
mkdir -p ${HOME}/.config/sunshine

curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/sunshine.conf -o ${HOME}/.config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} == "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-gnome.json -o ${HOME}/.config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} == "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-plasma.json -o ${HOME}/.config/sunshine/apps.json
fi

# Sunshine updater
tee ${HOME}/.local/bin/update-sunshine << 'EOF'
LATEST_VERSION=$(curl -s https://api.github.com/repos/LizardByte/Sunshine/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
INSTALLED_VERSION=$(sunshine --version)

if [[ "${INSTALLED_VERSION}" != *"${LATEST_VERSION}"* ]]; then
  curl https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -L -O
  sudo dnf install -y sunshine-fedora-$(rpm -E %fedora)-amd64.rpm
  rm -f sunshine-fedora-$(rpm -E %fedora)-amd64.rpm
  systemctl --user restart sunshine.service
fi
EOF

chmod +x ${HOME}/.local/bin/update-sunshine

# Add Sunshine updater to bash updater function
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-sunshine' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Sunshine' ${HOME}/.zshrc.d/update-all