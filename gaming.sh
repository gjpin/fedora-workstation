#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//22.08

# Configure MangoHud
mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf

tee ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf << EOF
control=mangohud
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
sudo flatpak override --filesystem=/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload-rules

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Allow Heroic to access external directory
sudo flatpak override --filesystem=/data/games/heroic com.heroicgameslauncher.hgl

################################################
##### Sunshine
################################################

# References:
# https://flathub.org/apps/dev.lizardbyte.app.Sunshine
# https://github.com/LizardByte/Sunshine/blob/master/sunshine.service.in

# Install Sunshine
flatpak install -y flathub dev.lizardbyte.app.Sunshine

# Allow Sunshine to start apps and games
sudo flatpak override --talk-name=org.freedesktop.Flatpak dev.lizardbyte.app.Sunshine

# Enable wayland support
sudo flatpak override --socket=wayland dev.lizardbyte.app.Sunshine

# Allow Sunshine Virtual Input
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/85-sunshine-input.rules

# Create Sunshine wrapper
sudo tee /usr/local/bin/sunshine << EOF
#!/usr/bin/bash

if [ -n "$1" ]; then
        /usr/bin/flatpak kill dev.lizardbyte.app.Sunshine
else
    PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run --socket=wayland dev.lizardbyte.app.Sunshine
    	sudo -i PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run dev.lizardbyte.app.Sunshine
fi
EOF

sudo chmod +x /usr/local/bin/sunshine

# Create Sunshine service
sudo tee /etc/systemd/system/sunshine.service << EOF
[Unit]
Description=Sunshine is a self-hosted game stream host for Moonlight.
StartLimitIntervalSec=500
StartLimitBurst=5
PartOf=graphical-session.target
Wants=xdg-desktop-autostart.target
After=xdg-desktop-autostart.target

[Service]
ExecStart=/usr/local/bin/sunshine
ExecStop=flatpak kill dev.lizardbyte.app.Sunshine
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=xdg-desktop-autostart.target
EOF

# Enable Sunshine service
sudo systemctl enable sunshine.service

# Import configs
sudo mkdir -p /root/.config/sunshine

sudo curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/sunshine.conf -o /root/.config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} == "gnome" ]; then
    sudo curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-gnome.json -o /root/.config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} == "plasma" ]; then
    sudo curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/sunshine/apps-plasma.json -o /root/.config/sunshine/apps.json
fi