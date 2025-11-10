#!/usr/bin/bash

################################################
##### Containers and Virtualization
################################################

print_section "Containers and Virtualization"

################################################
##### Virtualization
################################################

print_info "Installing virtualization tools"

# Install virtualization group
sudo dnf install -y @virtualization

# Enable libvirtd service
sudo systemctl enable libvirtd

# Add user to libvirt group
sudo usermod -a -G libvirt ${USER}

################################################
##### Podman
################################################

print_info "Configuring Podman"

# Set podman alias
create_zsh_config "podman" 'alias docker="podman"'

# Enable Podman socket
systemctl --user enable podman.socket

################################################
##### Toolbx
################################################

print_info "Configuring Toolbox"

# Install toolbox
sudo dnf install -y toolbox

# Create archlinux toolbox
toolbox create -y --distro arch

# Update arch packages
toolbox run sudo pacman -Syu

# Install packages
toolbox run sudo pacman -S --noconfirm bind talosctl k9s

# Toolbox updater
append_to_updater '
################################################
##### Toolbx
################################################

# Update toolbox packages
toolbox run sudo pacman -Syu --noconfirm
'

print_info "Containers and virtualization configuration completed"