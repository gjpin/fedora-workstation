#!/usr/bin/bash

################################################
##### Runtimes Configuration
################################################

print_section "Runtimes Configuration"

################################################
##### RPM Fusion
################################################

if should_install RPM_FUSION; then
    print_info "Installing RPM Fusion"
    
    # Enable free and nonfree repositories
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Switch to full ffmpeg
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

    # Install additional codecs
    sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    sudo dnf groupupdate -y sound-and-video

    # Install Intel hardware accelerated codecs
    if has_intel_gpu; then
        print_info "Installing Intel hardware acceleration"
        sudo dnf install -y intel-media-driver
    fi

    # Install AMD hardware accelerated codecs
    if has_amd_gpu; then
        print_info "Installing AMD hardware acceleration"
        sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
        sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
    fi
else
    print_info "Skipping RPM Fusion installation"
fi

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

print_info "Runtimes configuration completed"