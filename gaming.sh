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
##### Sunshine (Flatpak)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://github.com/flathub/dev.lizardbyte.app.Sunshine/blob/master/dev.lizardbyte.app.Sunshine.metainfo.xml
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port

# Install Sunshine
flatpak install -y flathub dev.lizardbyte.app.Sunshine
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/dev.lizardbyte.app.Sunshine -o ${HOME}/.local/share/flatpak/overrides/dev.lizardbyte.app.Sunshine

# Allow Sunshine Virtual Input
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/85-sunshine-input.rules

# Create Sunshine alias
tee ${HOME}/.zshrc.d/sunshine << 'EOF'
alias sunshine="sudo -i PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run dev.lizardbyte.app.Sunshine"
EOF

# Import configs
mkdir -p ${HOME}/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/sunshine.conf -o ${HOME}/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} == "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-gnome.json -o ${HOME}/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} == "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-plasma.json -o ${HOME}/.var/app/dev.lizardbyte.app.Sunshine/config/sunshine/apps.json
fi

# Allow Sunshine in firewall
sudo firewall-cmd --zone=FedoraWorkstation --add-port=47984/tcp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=47989/tcp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=48010/tcp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=47998/udp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=47999/udp --permanent
sudo firewall-cmd --zone=FedoraWorkstation --add-port=48000/udp --permanent

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
  sudo firewall-cmd --zone=FedoraWorkstation --add-port=9943/tcp --permanent
  sudo firewall-cmd --zone=FedoraWorkstation --add-port=9944/tcp --permanent
  sudo firewall-cmd --zone=FedoraWorkstation --add-port=9943/udp --permanent
  sudo firewall-cmd --zone=FedoraWorkstation --add-port=9944/udp --permanent

  # Create ALVR dashboard alias
  echo 'alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"' > ${HOME}/.zshrc.d/alvr

  # Create ALVR dashboard desktop entry
  curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/alvr/com.valvesoftware.Steam.Utility.alvr.desktop -o ${HOME}/.local/share/applications/com.valvesoftware.Steam.Utility.alvr.desktop
fi