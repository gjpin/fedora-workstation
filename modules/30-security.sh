#!/usr/bin/bash

################################################
##### Security Configuration
################################################

print_section "Security Configuration"

################################################
##### SELinux
################################################

print_info "Configuring SELinux"

# Create aliases
tee ${HOME}/.zshrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
EOF

# Install setroubleshoot
sudo dnf install -y setroubleshoot

################################################
##### systemd
################################################

print_info "Configuring systemd timeouts"

# Configure default timeout to stop system units
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

# Configure default timeout to stop user units
sudo mkdir -p /etc/systemd/user.conf.d
sudo tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

################################################
##### WireGuard
################################################

print_info "Installing WireGuard"

# Install wireguard-tools
sudo dnf install -y wireguard-tools

# Create WireGuard folder
sudo mkdir -p /etc/wireguard/
sudo chmod 700 /etc/wireguard/

################################################
##### Power management
################################################

print_info "Configuring power management"

# Apply power managament configurations according to device type
if is_laptop; then
    print_info "Laptop detected - enabling power saving features"
    
    # Enable audio power saving features
    echo 'options snd_hda_intel power_save=1' | sudo tee /etc/modprobe.d/audio_powersave.conf

    # Enable wifi (iwlwifi) power saving features
    echo 'options iwlwifi power_save=1' | sudo tee /etc/modprobe.d/iwlwifi.conf
else
    print_info "Desktop detected"
    
    if has_amd_gpu; then
        print_info "AMD GPU detected - configuring performance settings"
        
        # AMD scaling driver
        sudo grubby --update-kernel=ALL --args=amd_pstate=active

        # Set AMD GPU performance level to High
        echo 'SUBSYSTEM=="pci", DRIVER=="amdgpu", ATTR{power_dpm_force_performance_level}="high"' | sudo tee /etc/udev/rules.d/30-amdgpu-high-power.rules
    fi
fi

################################################
##### Unlock LUKS2 with TPM2 token
################################################

print_info "Configuring LUKS2 TPM2 unlock"

# Add tpm2-tss module to dracut
echo 'add_dracutmodules+=" tpm2-tss "' | sudo tee /etc/dracut.conf.d/tpm2.conf

# Enroll TPM2 as LUKS' decryption factor
if sudo btrfs filesystem usage / | grep RAID0 > /dev/null; then
  print_info "RAID0 detected - enrolling both drives"
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme0n1p3
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme1n1p1
else
  print_info "Single drive detected"
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme0n1p3
fi

# Update crypttab
sudo sed -i "s|discard|&,tpm2-device=auto|" /etc/crypttab

# Regenerate initramfs
print_info "Regenerating initramfs"
sudo dracut --regenerate-all --force

print_info "Security configuration completed"

################################################
##### Firewall
################################################

# Install firewalld GUI
print_info "Installing firewalld GUI"
sudo dnf install -y firewall-config