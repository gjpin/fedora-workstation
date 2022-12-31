# Installation guide
1. Download setup script: `curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/setup.sh -O`
2. Make setup script executable: `chmod +x setup.sh`
3. Run setup.sh: `./setup.sh`
4. Reboot
5. Import WireGuard config to /etc/wireguard
6. Enable WireGuard connection: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
7. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-interface=wg0`

# Guides
## How to revert to a previous Flatpak commit
```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```

## How to use Gamescope + MangoHud in Steam
```bash
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -e -- %command%

# gamescope native resolution + MangoHud
gamescope -f -e -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -e -- mangohud %command%
```

## How to install .deb package (eg. Aseprite)
```bash
mkdir -p ${HOME}/aseprite
mv ${HOME}/Downloads/Aseprite*.deb ${HOME}/aseprite
ar -x ${HOME}/aseprite/Aseprite*.deb --output ${HOME}/aseprite
tar -xf ${HOME}/aseprite/data.tar.xz -C ${HOME}/aseprite
cp -r ${HOME}/aseprite/usr/bin/aseprite ${HOME}/.local/bin/
cp -r ${HOME}/aseprite/usr/share/* ${HOME}/.local/share/
rm -rf ${HOME}/aseprite
```