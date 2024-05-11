# Installation guide

1. Clone project: `git clone https://github.com/gjpin/fedora-workstation.git`
2. Run setup.sh: `fedora-workstation/setup.sh`
3. Choose between Gnome and Plasma configurations
4. Reboot
5. Copy wireguard config to /etc/wireguard/wg0.conf
6. Import wireguard connection to networkmanager: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
7. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-interface=wg0`
8. Install SteamVR, run `sudo setcap CAP_SYS_NICE+eip ~/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher` and then launch and close SteamVR

# Guides

## How to install Fedora with Btrfs RAID0

```bash
# References:
# https://discussion.fedoraproject.org/t/what-is-the-procedure-to-install-fedora-37-in-raid0/79347/5

# Boot into Fedora live ISO

# Wipe partition tables
sudo parted /dev/nvme0n1 mklabel gpt
sudo parted /dev/nvme1n1 mklabel gpt

# Reboot into Fedora live ISO

# Installation destination
- Device Selection > Select all disks
- Storage Configuration > Custom
- Done

# Manual Partitioning > New Fedora Installation
- New mount points will use the following partitioning scheme: Btrfs
- Encrypt my data
- Click here to create them automatically
- SYSTEM > root > Volume > Modify…
    - Select all volumes
    - RAID level: RAID0
    - Size policy: As large as possible
    - Save
- Done > Accept Changes
```

## Re-enroll TPM2 as LUKS' decryption factor

`sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto --tpm2-pcrs "0+1+2+3+4+5+7+9" /dev/nvme0n1p3`

## How to revert to a previous Flatpak commit

```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```

### How to use Gamescope + MangoHud in Steam

```bash
# MangoHud
mangohud %command%

# gamescope in 1440p
gamescope -W 2560 -H 1440 -f -- %command%

# gamescope in 1440p + MangoHud
gamescope -W 2560 -H 1440 -f -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -- mangohud %command%
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

## Auto-mount extra drive

```bash
# Delete old partition layout and re-read partition table
sudo wipefs -af /dev/nvme1n1
sudo sgdisk --zap-all --clear /dev/nvme1n1
sudo partprobe /dev/nvme1n1

# Partition disk and re-read partition table
sudo sgdisk -n 1:0:0 -t 1:8309 -c 1:LUKSDATA /dev/nvme1n1
sudo partprobe /dev/nvme1n1

# Encrypt and open LUKS partition
sudo cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/disk/by-partlabel/LUKSDATA
sudo cryptsetup luksOpen /dev/disk/by-partlabel/LUKSDATA data

# Format partition to EXT4
sudo mkfs.ext4 -L data /dev/mapper/data

# Mount root device
sudo mkdir -p /data
sudo mount -t ext4 LABEL=data /data

# Auto-mount
sudo tee -a /etc/fstab << EOF

# data disk
/dev/mapper/data /data ext4 defaults 0 0
EOF

sudo tee -a /etc/crypttab << EOF

data UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1p1) none
EOF

sudo systemctl daemon-reload

# Change ownership to user
sudo chown -R $USER:$USER /data

# Auto unlock
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/nvme1n1p1
```

## Wake-on-LAN quirks

```bash
# References:
# https://wiki.archlinux.org/title/Wake-on-LAN#Fix_by_Kernel_quirks

# Use if WoL has been enabled and the computer does not shutdown

# Add kernel boot parameters to enable quirks
sudo grubby --update-kernel=ALL --args=xhci_hcd.quirks=270336
```
