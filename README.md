# Fedora customization and setup scripts

## Per app dark mode
```
Install 'Dark Variant' extension: https://github.com/hardpixel/dark-variant
```

## Gamescope + MangoHUD + Steam
```
# Native 1440p + mangohud
gamescope -h 1440 -H 1440 -f -- mangohud %command%

# Upscale 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -- mangohud %command%
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
cp -r usr/bin/aseprite ~/.local/bin/
cp -r usr/share/* ~/.local/share/
```