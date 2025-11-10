#!/usr/bin/bash

################################################
##### RPM Fusion Configuration
################################################

print_section "RPM Fusion Configuration"

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

print_info "RPM Fusion configuration completed"