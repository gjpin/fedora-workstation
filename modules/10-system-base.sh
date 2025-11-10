#!/usr/bin/bash

################################################
##### System Base Configuration
################################################

print_section "System Base Configuration"

# Disable speech dispatcher
print_info "Disabling speech dispatcher"
sudo sed -i "s|^# DisableAutoSpawn|DisableAutoSpawn|g" /etc/speech-dispatcher/speechd.conf

# Mask NetworkManager-wait-online service
print_info "Masking NetworkManager-wait-online service"
sudo systemctl mask NetworkManager-wait-online.service

# Set hostname
print_info "Setting hostname to ${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --pretty "${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --static "${NEW_HOSTNAME}"

# Create common user directories
print_info "Creating user directories"
mkdir -p \
  ${HOME}/.local/share/applications \
  ${HOME}/.local/share/icons \
  ${HOME}/.local/share/themes \
  ${HOME}/.local/share/fonts \
  ${HOME}/.zshrc.d \
  ${HOME}/.local/bin \
  ${HOME}/.config/autostart \
  ${HOME}/.config/systemd/user \
  ${HOME}/.ssh \
  ${HOME}/.config/environment.d \
  ${HOME}/.devtools \
  ${HOME}/src

# Set SSH folder permissions
chmod 700 ${HOME}/.ssh

# Configure DNF
print_info "Configuring DNF"
sudo tee -a /etc/dnf/dnf.conf << EOF
fastestmirror=True
max_parallel_downloads=10
keepcache=True
clean_requirements_on_remove=True
EOF

# Update system
print_info "Updating system packages"
sudo dnf upgrade -y --refresh

# Install DNF plugins
sudo dnf install -y dnf-plugins-core

# Install common packages
print_info "Installing common packages"
sudo dnf install -y \
  bind-utils \
  kernel-tools \
  unzip \
  p7zip \
  p7zip-plugins \
  unrar \
  zstd \
  htop \
  xq \
  jq \
  fuse-sshfs \
  fd-find \
  fzf \
  libva \
  libva-utils \
  bc \
  ripgrep \
  yq \
  procps-ng \
  gawk \
  coreutils \
  pulseaudio-utils

# Install fonts
print_info "Installing fonts"
sudo dnf install -y source-foundry-hack-fonts

# Install Nerd fonts
print_info "Installing Nerd Fonts"
LATEST_NERDFONTS_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')

curl https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_NERDFONTS_VERSION}/FiraCode.tar.xz -L -O
tar -xf FiraCode.tar.xz -C ${HOME}/.local/share/fonts
rm -f FiraCode.tar.xz

curl https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_NERDFONTS_VERSION}/Noto.tar.xz -L -O
tar -xf Noto.tar.xz -C ${HOME}/.local/share/fonts
rm -f Noto.tar.xz

fc-cache -f

# Initialize update-all script
print_info "Creating update-all script"
tee ${HOME}/.local/bin/update-all << 'EOF'
#!/usr/bin/bash

################################################
##### System and firmware
################################################

# Update system
sudo dnf upgrade -y --refresh

# Update firmware
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update

################################################
##### Flatpaks
################################################

# Update Flatpak apps
flatpak update -y
flatpak uninstall -y --unused
EOF

chmod +x ${HOME}/.local/bin/update-all

print_info "System base configuration completed"