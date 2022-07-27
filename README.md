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
