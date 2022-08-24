# Fedora customization and setup scripts

## Gnome extensions
```
Per app titlebar dark mode: [Dark Variant](https://github.com/hardpixel/dark-variant)
KStatusNotifierItem support: [Appindicator and kstatusnotifieritem support](https://github.com/ubuntu/gnome-shell-extension-appindicator)
```

## Gaming
```
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
sudo tee /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

###### MangoHud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud

###### Heroic Games Launcher
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
dnf install -y wireguard-tools

# Generate key pairs
wg genkey | tee wg_home_private_key | wg pubkey > wg_home_public_key
mv wg_home_* /etc/wireguard

# Configure WireGuard interface
WG_HOME_PRIVATE_KEY=$(cat /etc/wireguard/wg_home_private_key)

tee /etc/wireguard/wg_home.conf << EOF
[Interface]
Address = 10.0.0.2
SaveConfig = true
PrivateKey = ${WG_HOME_PRIVATE_KEY}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
AllowedIPs = 10.0.0.0/24 # or 0.0.0.0/0 for all traffic
Endpoint = ${WG_PUBLIC_ADDRESS}:60001
PersistentKeepalive = 15
EOF

# Import interface profile into NetworkManager
nmcli con import type wireguard file /etc/wireguard/wg_home.conf
nmcli connection up wg_home
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

## To install .deb packages (eg. Aseprite)
```
ar -x Aseprite*
tar xf data.tar.xz
cp -r usr/bin/aseprite ~/.local/bin/
cp -r usr/share/* ~/.local/share/
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