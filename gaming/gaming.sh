##### GNOME EXTENSIONS
# Appindicator and kstatusnotifieritem support

###### STEAM
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/gjpin/fedora-gnome/main/configs/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules

# Reload udev rules
sudo udevadm control --reload && sudo udevadm trigger

# Enable uinput module
sudo tee -a /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

###### mangohud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud

###### mangohud
sudo flatpak install -y com.heroicgameslauncher.hgl
sudo flatpak override --filesystem=/mnt/data/games/heroic com.heroicgameslauncher.hgl

###### AMDGPU-CLOCKS (only if 5700 XT is detected)
if lspci | grep VGA | grep "5700 XT" > /dev/null; then

# Full AMD GPU controls
sudo grubby --update-kernel=ALL --args=amdgpu.ppfeaturemask=0xffffffff

# Download amdgpu-clocks
sudo curl -sSL https://raw.githubusercontent.com/gjpin/amdgpu-clocks/master/amdgpu-clocks -o /usr/local/bin/amdgpu-clocks
sudo chmod +x /usr/local/bin/amdgpu-clocks

# Systemd unit for amdgpu-clocks
sudo curl -sSL https://raw.githubusercontent.com/gjpin/amdgpu-clocks/master/amdgpu-clocks.service -o /lib/systemd/system/amdgpu-clocks.service
sudo curl -sSL https://raw.githubusercontent.com/gjpin/amdgpu-clocks/master/amdgpu-clocks-resume -o /usr/lib/systemd/system-sleep/amdgpu-clocks-resume
sudo chmod +x /usr/lib/systemd/system-sleep/amdgpu-clocks-resume

# Import custom profile
sudo tee /etc/default/amdgpu-custom-state.card0 << EOF
OD_SCLK:
0: 800Mhz
1: 2000Mhz
OD_MCLK:
1: 875MHz
OD_VDDC_CURVE:
1: 1422MHz 808mV
2: 2000MHz 1100mV
FORCE_POWER_CAP: 270000000
FORCE_PERF_LEVEL: manual
FORCE_POWER_PROFILE: 1
EOF

# Enable amdgpu-clocks service
sudo systemctl enable --now amdgpu-clocks

fi
