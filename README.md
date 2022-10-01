# Fedora customization and setup scripts

## Gaming
```
###### STEAM
mkdir -p /mnt/data/games/steam
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/gjpin/fedora-gnome/main/configs/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules

# Reload udev rules
sudo udevadm control --reload && sudo udevadm trigger

# Enable uinput module
sudo tee /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

###### MangoHud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud

###### Heroic Games Launcher
mkdir -p /mnt/data/games/heroic
sudo flatpak install -y com.heroicgameslauncher.hgl
sudo flatpak override --filesystem=/mnt/data/games/heroic com.heroicgameslauncher.hgl
```

## Gamescope + MangoHud + Steam
```
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -e -- %command%

# gamescope native resolution + MangoHud
gamescope -f -e -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -e -- mangohud %command%
```

## Override systemd configurations
```
sudo mkdir -p /etc/systemd/system.conf.d/

sudo tee /etc/systemd/system.conf.d/99-default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF
```

## Disable turbo boost if on battery (laptops only)
```
# References:
# https://chrisdown.name/2017/10/29/adding-power-related-targets-to-systemd.html

# If device is a laptop
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then

# Create systemd AC / battery targets
sudo tee /etc/systemd/system/ac.target << EOF
[Unit]
Description=On AC power
DefaultDependencies=no
StopWhenUnneeded=yes
EOF

sudo tee /etc/systemd/system/battery.target << EOF
[Unit]
Description=On battery power
DefaultDependencies=no
StopWhenUnneeded=yes
EOF

# Tell udev to start AC / battery targets when relevant
sudo tee /etc/udev/rules.d/99-powertargets.rules << 'EOF'
SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="/usr/bin/systemctl start battery.target"
SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="/usr/bin/systemctl start ac.target"
EOF

# Reload and apply udev's new config
sudo udevadm control --reload-rules

# Disable turbo boost if on battery 
sudo tee /etc/systemd/system/disable-turbo-boost.service << EOF
[Unit]
Description=Disable turbo boost on battery

[Service]
Type=oneshot
ExecStart=-/usr/bin/echo 0 > /sys/devices/system/cpu/cpufreq/boost
ExecStart=-/usr/bin/echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo

[Install]
WantedBy=battery.target
EOF

# Enable turbo boost if on AC 
sudo tee /etc/systemd/system/enable-turbo-boost.service << EOF
[Unit]
Description=Enable turbo boost on AC

[Service]
Type=oneshot
ExecStart=-/usr/bin/echo 1 > /sys/devices/system/cpu/cpufreq/boost
ExecStart=-/usr/bin/echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo

[Install]
WantedBy=ac.target
EOF

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable disable-turbo-boost.service
sudo systemctl enable enable-turbo-boost.service

fi
```

## Enable amd-pstate CPU Performance Scaling Driver
```
# Check if CPU is AMD and current scaling driver is not amd-pstate
if cat /proc/cpuinfo | grep "AuthenticAMD" > /dev/null && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver | grep -v "amd-pstate" > /dev/null; then
  sudo grubby --update-kernel=ALL --args="amd_pstate.shared_mem=1"
  echo amd_pstate | sudo tee /etc/modules-load.d/amd-pstate.conf
fi
```

## Install Proton-GE manually
```
mkdir -p ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/

curl -sSL https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton7-30/GE-Proton7-30.tar.gz -O

tar -xf GE-Proton*.tar.gz -C ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/

rm GE-Proton*.tar.gz
```

## Connect to WireGuard server
```
# Install WireGuard tools
sudo dnf install -y wireguard-tools

# Generate key pairs
wg genkey | tee wg_home_private_key | wg pubkey > wg_home_public_key
sudo chown root:root wg_home_*
sudo mv wg_home_* /etc/wireguard/

# Configure WireGuard interface
WG_HOME_PRIVATE_KEY=$(sudo cat /etc/wireguard/wg_home_private_key)

sudo tee /etc/wireguard/wg_home.conf << EOF
[Interface]
Address = 10.0.0.2
SaveConfig = true
PrivateKey = ${WG_HOME_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
AllowedIPs = 10.0.0.0/24 # also add other LAN IPs if required. eg. 192.168.1.252 or 0.0.0.0/0 for all traffic
Endpoint = ${SERVER_PUBLIC_ADDRESS}:60001
PersistentKeepalive = 15
EOF

# Import interface profile into NetworkManager
sudo nmcli con import type wireguard file /etc/wireguard/wg_home.conf
nmcli connection up wg_home

# Set wg_home connection as trusted
sudo firewall-cmd --permanent --zone=trusted --add-interface=wg_home
-------

# Reset wireguard connections and configurations
nmcli connection down wg_home
nmcli connection delete wg_home
sudo nmcli con import type wireguard file /etc/wireguard/wg_home.conf
nmcli connection up wg_home
sudo firewall-cmd --permanent --zone=home --add-interface=wg_home
```

## Recovery: chroot into system (nvme drive + encrypted /)
Go into live mode and then run:
```
su

# open encrypted partition
cryptsetup open --type luks /dev/nvme0n1p3 crypto_LUKS

# mount root
mount /dev/mapper/crypto_LUKS /mnt/ -t btrfs -o subvol=root

# mount home
mount /dev/mapper/crypto_LUKS /mnt/home -t btrfs -o subvol=home

# mount boot
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/efi

# mount special system folders
mount --bind /dev /mnt/dev
mount -t proc /proc /mnt/proc
mount -t sysfs /sys /mnt/sys
mount -t tmpfs tmpfs /mnt/run

# set nameserver
mkdir -p /mnt/run/systemd/resolve/
echo 'nameserver 1.1.1.1' > /mnt/run/systemd/resolve/stub-resolv.conf

# chroot
chroot /mnt
```

## tlp
```
sudo systemctl disable --now power-profiles-daemon.service
sudo systemctl mask power-profiles-daemon.service
sudo dnf install -y tlp
sudo curl -sSL https://raw.githubusercontent.com/gjpin/fedora-gnome/main/configs/tlp -o /etc/tlp.conf
sudo systemctl enable --now tlp.service
```

## auto-cpufreq
```
# https://github.com/AdnanHodzic/auto-cpufreq
cd ~/src
git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq && sudo ./auto-cpufreq-installer
sudo auto-cpufreq --install
```

## amgpu undervolt example
```
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
```

## To install .deb packages (eg. Aseprite)
```
ar -x Aseprite*
tar xf data.tar.xz
cp -r usr/bin/aseprite ~/.local/bin/
cp -r usr/share/* ~/.local/share/
rm -rf usr/ debian-binary data.tar.xz control.tar.xz Aseprite_1.3-beta21-1_amd64.deb
```

## blender / godot
```
mkdir -p ${HOME}/apps/{blender,godot}

# Blender
rm ${HOME}/apps/blender/blender
curl -sSL https://mirrors.dotsrc.org/blender/release/Blender3.3/blender-3.3.0-linux-x64.tar.xz -o ${HOME}/apps/blender/blender.tar.xz
tar -xf ${HOME}/apps/blender/blender.tar.xz -C ${HOME}/apps/blender
rm ${HOME}/apps/blender/blender.tar.xz

tee /home/$USER/.local/share/applications/blender.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
NoDisplay=false
Terminal=false
Exec=/home/${USER}/apps/blender/blender-3.3.0-linux-x64/blender
Icon=/home/${USER}/apps/blender/blender-3.3.0-linux-x64/blender.svg
Name=Blender
Comment=
Categories=
EOF

# Godot
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/assets/Godot_icon.svg -o ${HOME}/apps/godot/Godot_icon.svg
rm ${HOME}/apps/godot/godot
curl -sSL https://downloads.tuxfamily.org/godotengine/4.0/beta1/Godot_v4.0-beta1_linux.x86_64.zip -o ${HOME}/apps/godot/godot.zip
unzip ${HOME}/apps/godot/godot.zip -d ${HOME}/apps/godot
mv ${HOME}/apps/godot/Godot_v* ${HOME}/apps/godot/godot
rm ${HOME}/apps/godot/godot.zip

tee /home/$USER/.local/share/applications/godot.desktop << EOF
[Desktop Entry]
Encoding=UTF-8
Type=Application
NoDisplay=false
Terminal=false
Exec=/home/${USER}/apps/godot/godot
Icon=/home/${USER}/apps/godot/Godot_icon.svg
Name=Godot
Comment=
Categories=
EOF
```