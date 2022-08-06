# Fedora customization and setup scripts

## Unlock LUKS with TPM2
```
sudo dnf install -y tpm2-tools

sudo systemd-cryptenroll /dev/nvme0n1p3 --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7

sudo sed -ie '/^luks-/s/$/ tpm2-device=auto/' /etc/crypttab

sudo dracut -f
```

## Per app dark mode
```
sudo dnf install -y xprop

Install 'Dark Variant' extension: https://github.com/hardpixel/dark-variant
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
sudo cp -r usr/bin/* /usr/bin/
sudo cp -r usr/share/* /usr/share/
sudo sed -i "s|Icon=aseprite|Icon=/usr/share/icons/hicolor/64x64/apps/aseprite.png|" /usr/share/applications/aseprite.desktop
```

## Download and install godot
```
# Download and install Godot
GODOT_VERSION=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/godotengine/godot/tags | jq -j -r .[0].name)
curl -sSL https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_x11.64.zip -O
unzip Godot*
rm Godot*.zip
mv Godot* ${HOME}/.local/bin/godot

# Download icon
mkdir -p ${HOME}/.local/share/godot
curl -sSL https://upload.wikimedia.org/wikipedia/commons/6/6a/Godot_icon.svg -o ${HOME}/.local/share/godot/icon.svg

# Create desktop entry
tee ${HOME}/.local/share/applications/godot.desktop << EOF
[Desktop Entry]
Name=Godot
Exec=/home/$USER/.local/bin/godot
Icon=/home/$USER/.local/share/godot/icon.svg
Type=Application
Categories=Graphics;2DGraphics
EOF
```