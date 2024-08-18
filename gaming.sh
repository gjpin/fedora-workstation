#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install MangoHud and Gamescope (native)
if [ ${STEAM_VERSION} = "native" ]; then
  sudo dnf install -y mangohud gamescope
  mkdir -p ${HOME}/.config/MangoHud
  curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.config/MangoHud/MangoHud.conf
fi

# Install MangoHud and Gamescope (Flatpak)
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08

################################################
##### Steam
################################################

# Create directory for Steam games
mkdir -p ${HOME}/Games/Steam

if [ ${STEAM_VERSION} = "native" ]; then
  # Install Steam
  sudo dnf install -y steam
elif [ ${STEAM_VERSION} = "flatpak" ]; then
  # Install Steam
  flatpak install -y flathub com.valvesoftware.Steam
  curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.valvesoftware.Steam -o ${HOME}/.local/share/flatpak/overrides/com.valvesoftware.Steam

  # Steam devices udev rules
  sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
  sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-vr.rules -o /etc/udev/rules.d/60-steam-vr.rules

  # Configure MangoHud for Steam
  mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud
  curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf
fi

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.heroicgameslauncher.hgl -o ${HOME}/.local/share/flatpak/overrides/com.heroicgameslauncher.hgl

# Create directory for Heroic games
mkdir -p ${HOME}/Games/Heroic/{Epic,GOG}

# Create directory for Heroic Prefixes
mkdir -p ${HOME}/Games/Heroic/Prefixes/{Epic,GOG}

# Configure MangoHud for Heroic
mkdir -p ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud/MangoHud.conf

################################################
##### Sunshine
################################################

# References:
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/installation.html#rpm-package
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/usage.html#linux
# https://github.com/LizardByte/Sunshine/blob/master/sunshine.service.in
# https://github.com/LizardByte/Sunshine

# Download Sunshine
curl https://github.com/LizardByte/Sunshine/releases/download/nightly-dev/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -L -O

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
  if [ ${STEAM_VERSION} = "native" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-gnome.json -o ${HOME}/.config/sunshine/apps.json
  elif [ ${STEAM_VERSION} = "flatpak" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-gnome-flatpak.json -o ${HOME}/.config/sunshine/apps.json
  fi
elif [ ${DESKTOP_ENVIRONMENT} == "plasma" ]; then
  if [ ${STEAM_VERSION} = "native" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-plasma.json -o ${HOME}/.config/sunshine/apps.json
  elif [ ${STEAM_VERSION} = "flatpak" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-plasma-flatpak.json -o ${HOME}/.config/sunshine/apps.json
  fi
fi

# Sunshine updater
tee -a ${HOME}/.local/bin/update-all << 'EOF'

# Update Sunshine
curl https://github.com/LizardByte/Sunshine/releases/download/nightly-dev/sunshine-fedora-$(rpm -E %fedora)-amd64.rpm -L -O
sudo dnf reinstall -y sunshine-fedora-$(rpm -E %fedora)-amd64.rpm
rm -f sunshine-fedora-$(rpm -E %fedora)-amd64.rpm
systemctl --user restart sunshine.service
EOF

################################################
##### ALVR
################################################

# References:
# https://github.com/alvr-org/ALVR/wiki/Flatpak

if [ ${STEAM_VERSION} = "flatpak" ]; then
  # Download ALVR
  curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

  # Install ALVR
  flatpak install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

  # Remove ALVR flatpak file
  rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

  # Allow ALVR in firewall
  sudo firewall-cmd --zone=block --add-service=alvr
  sudo firewall-cmd --zone=FedoraWorkstation --add-service=alvr

  sudo firewall-cmd --permanent --zone=block --add-service=alvr
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=alvr

  # Create ALVR dashboard alias
  echo 'alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"' > ${HOME}/.zshrc.d/alvr

  # Create ALVR dashboard desktop entry
  curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/alvr/com.valvesoftware.Steam.Utility.alvr.desktop -o ${HOME}/.local/share/applications/com.valvesoftware.Steam.Utility.alvr.desktop
fi