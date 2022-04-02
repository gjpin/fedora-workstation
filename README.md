# Fedora customization and setup scripts

## Notes
gaming/gaming.sh installs Steam and sets controllers udev rules, but also underclocks and undervolts a Radeon RX 5700 XT to 1900MHz/1020mv.
The performance is comparable to stock, but reduces the junction temperature by ~15C in heavy load.

## Unlock LUKS with TPM2
```
sudo dnf install -y tpm2-tools
sudo systemd-cryptenroll /dev/nvme0n1p3 --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7+8
sudo sed -ie '/^luks-/s/$/ tpm2-device=auto/' /etc/crypttab
sudo dracut -f
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
