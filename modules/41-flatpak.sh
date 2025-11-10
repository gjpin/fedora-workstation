#!/usr/bin/bash

################################################
##### Flatpak Configuration
################################################

print_section "Flatpak Configuration"

################################################
##### Flatpak
################################################

print_info "Configuring Flatpak"

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable

# Remove Fedora flatpak's repo
flatpak install --reinstall flathub $(flatpak list --app-runtime=org.fedoraproject.Platform --columns=application | tail -n +1 )
sudo flatpak remote-delete fedora

# Import global Flatpak overrides
mkdir -p ${HOME}/.local/share/flatpak/overrides
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/global -o ${HOME}/.local/share/flatpak/overrides/global

# Install Flatpak runtimes
print_info "Installing Flatpak runtimes"
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full//24.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi//24.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//24.08-extra
flatpak install -y flathub org.freedesktop.Platform.GL32.default//24.08-extra

if has_intel_gpu; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel//24.08
fi

# Install Flatseal
print_info "Installing Flatseal"
flatpak install -y flathub com.github.tchx84.Flatseal

print_info "Flatpak configuration completed"