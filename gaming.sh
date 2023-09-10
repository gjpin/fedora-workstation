#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2

################################################
##### MangoHud (Flatpak)
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//22.08

# Configure MangoHud
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
##### Steam
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope

# Allow Steam to access external directory
flatpak override --user --filesystem=/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules

# Allow Steam to open other applications (eg. Lutris or Heroic)
flatpak override --user --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Allow Heroic to access external directory and steam folder
flatpak override --user --filesystem=/data/games/heroic com.heroicgameslauncher.hgl
flatpak override --user --filesystem=home/.var/app/com.valvesoftware.Steam/data/Steam com.heroicgameslauncher.hgl

# Deny Heroic access to 'Games' diretory
flatpak override --user --nofilesystem=home/Games/Heroic com.heroicgameslauncher.hgl

################################################
##### Lutris
################################################

# Install Lutris
flatpak install -y flathub net.lutris.Lutris

# Allow Lutris to create application shortcuts
flatpak override --user --filesystem=xdg-data/applications net.lutris.Lutris

# Allow Lutris access to its folder
flatpak override --user --filesystem=/data/lutris net.lutris.Lutris

# Allow Lutris access to Steam (Lutris expects to find Steam at ~/.steam)
ln -s ${HOME}/.var/app/com.valvesoftware.Steam/.steam ${HOME}/.steam
flatpak override --user --filesystem=home/.var/app/com.valvesoftware.Steam/data/Steam net.lutris.Lutris

# Deny Lutris talk
flatpak override --user --no-talk-name=org.freedesktop.Flatpak net.lutris.Lutris

# Configure MangoHud
mkdir -p ${HOME}/.var/app/net.lutris.Lutris/config/MangoHud
tee ${HOME}/.var/app/net.lutris.Lutris/config/MangoHud/MangoHud.conf << EOF
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
fi
EOF

chmod +x ${HOME}/.local/bin/update-sunshine

# Add Sunshine updater to bash updater function
sed -i '2 i \ ' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ update-sunshine' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ # Update Sunshine' ${HOME}/.bashrc.d/update-all