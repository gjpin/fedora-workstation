#!/usr/bin/bash

################################################
##### Set variables
################################################

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Gaming (yes / no): " GAMING
export GAMING

read -p "Desktop environment (gnome / plasma): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

################################################
##### Remove unneeded packages and services
################################################

# Mark applications as manually installed
sudo dnf mark install \
  flatpak \
  flatpak-selinux \
  flatpak-session-helper \
  ibus-gtk4

# Remove applications
sudo dnf remove -y \
    abrt \
    mediawriter

# Remove libreoffice
sudo dnf group remove -y libreoffice
sudo dnf remove -y *libreoffice*

# Disable mobile broadband modem management service
sudo systemctl mask ModemManager.service

# Disable PC/SC Smart Card service
sudo systemctl mask pcscd.service

# Disable location lookup service
sudo systemctl mask geoclue.service

################################################
##### General
################################################

# Set hostname
sudo hostnamectl set-hostname --pretty "${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --static "${NEW_HOSTNAME}"

# Configure DNF
sudo tee -a /etc/dnf/dnf.conf << EOF
fastestmirror=True
max_parallel_downloads=10
keepcache=True
EOF

# Update system
sudo dnf upgrade -y --refresh

# Install common packages
sudo dnf install -y \
  bind-utils \
  kernel-tools \
  unzip \
  p7zip \
  p7zip-plugins \
  htop

# Install fonts
sudo dnf install -y \
  source-foundry-hack-fonts
  
# Create common user directories
mkdir -p \
  ${HOME}/.local/share/applications \
  ${HOME}/.local/share/themes \
  ${HOME}/.local/share/fonts \
  ${HOME}/.bashrc.d \
  ${HOME}/.local/bin \
  ${HOME}/.config/autostart \
  ${HOME}/.config/systemd/user \
  ${HOME}/.ssh \
  ${HOME}/.config/environment.d \
  ${HOME}/src

chmod 700 ${HOME}/.ssh

################################################
##### systemd
################################################

# References:
# https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html

# Configure default timeout to stop system units
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

# Configure default timeout to stop user units
sudo mkdir -p /etc/systemd/user.conf.d
sudo tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

################################################
##### bash
################################################

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
update-all() {
  # Update system
  sudo dnf upgrade -y --refresh

  # Update Flatpak apps
  flatpak update -y
  flatpak uninstall -y --unused

  # Update firmware
  sudo fwupdmgr refresh
  sudo fwupdmgr update

  # Update Deno
  deno upgrade
}
EOF

# Create aliases
tee ${HOME}/.bashrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
EOF

# Configure bash prompt
tee ${HOME}/.bashrc.d/prompt << EOF
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

################################################
##### Firewalld
################################################

# Set default firewall zone
sudo firewall-cmd --set-default-zone=block

# Install firewalld GUI
sudo dnf install -y firewall-config

################################################
##### WireGuard
################################################

# Install wireguard-tools
sudo dnf install -y wireguard-tools

# Create WireGuard folder
sudo mkdir -p /etc/wireguard/
sudo chmod 700 /etc/wireguard/

################################################
##### Flatpak
################################################

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable

# Global override to deny all applications the permission to access certain directories
# sudo flatpak override --nofilesystem='home' --nofilesystem='host' --nofilesystem='xdg-cache' --nofilesystem='xdg-config' --nofilesystem='xdg-data'
# flatpak override --filesystem=xdg-download

# Allow read-only access to GTK configs
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro
sudo flatpak override --filesystem=${HOME}/.local/share/themes:ro

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
fi

# Install applications
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak install -y flathub org.keepassxc.KeePassXC
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.libreoffice.LibreOffice
flatpak install -y flathub rest.insomnia.Insomnia
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub org.chromium.Chromium
flatpak install -y flathub com.github.marhkb.Pods
flatpak install -y flathub com.usebottles.bottles

# Allow Bottles to create application shortcuts
sudo flatpak override --filesystem=xdg-data/applications com.usebottles.bottles

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Remove native firefox
sudo dnf remove -y firefox

# Install Firefox from Flathub
flatpak install -y flathub org.mozilla.firefox

# Enable wayland support
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Set Firefox Flatpak as default browser and handler for https(s)
xdg-settings set default-web-browser org.mozilla.firefox.desktop
xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/http
xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/https

# Temporarily open Firefox to create profiles
timeout 5 flatpak run org.mozilla.firefox --headless

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)

# Import extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

# Import Firefox configs
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/firefox/user.js -o ${FIREFOX_PROFILE_PATH}/user.js

################################################
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/python/python-installation.html
# https://developer.fedoraproject.org/tech/languages/rust/rust-installation.html
# https://www.hashicorp.com/official-packaging-guide

# Set git configurations
git config --global init.defaultBranch main

# Set podman alias
tee ${HOME}/.bashrc.d/podman << EOF
alias docker="podman"
EOF

# Create python sandbox virtualenv and alias
mkdir -p ${HOME}/.python

python -m venv ${HOME}/.python/play

tee ${HOME}/.bashrc.d/python << 'EOF'
alias pythonplay="source ${HOME}/.python/play/bin/activate"
EOF

# Install go
sudo dnf install -y golang

mkdir -p ${HOME}/.go

tee ${HOME}/.bashrc.d/go << 'EOF'
export GOPATH="$HOME/.go"
EOF

# Install nodejs
sudo dnf install -y nodejs npm

# Install deno
mkdir -p ${HOME}/.deno/bin
curl https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -L -O
unzip -o deno-x86_64-unknown-linux-gnu.zip -d ${HOME}/.deno/bin
rm -f deno-x86_64-unknown-linux-gnu.zip
tee ${HOME}/.bashrc.d/deno << 'EOF'
export DENO_INSTALL=${HOME}/.deno
export PATH="$PATH:$DENO_INSTALL/bin"
EOF

# Install cfssl
sudo dnf install -y golang-github-cloudflare-cfssl

# Install make
sudo dnf install -y make

# Install butane
sudo dnf install -y butane

# Install Kubernetes client tools
sudo dnf install -y kubernetes-client

# Install Neovim and set as default editor
sudo dnf install -y neovim

tee ${HOME}/.bashrc.d/neovim << 'EOF'
alias vi=nvim
alias vim=nvim
EOF

################################################
##### VSCode
################################################

# References:
# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions

# Import Microsoft key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Add VSCode repository
sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Install VSCode
dnf check-update
sudo dnf install -y code

# Install extensions
code --install-extension golang.Go
code --install-extension ms-python.python
code --install-extension redhat.vscode-yaml
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension denoland.vscode-deno

# Configure VSCode
mkdir -p ${HOME}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.config/Code/User/settings.json

################################################
##### Utilities
################################################

# Install syncthing and enable service
sudo dnf install -y syncthing
systemctl --user enable syncthing.service

################################################
##### Unlock LUKS2 with TPM2 token
################################################

# References:
# https://fedoramagazine.org/use-systemd-cryptenroll-with-fido-u2f-or-tpm2-to-decrypt-your-disk/
# https://www.freedesktop.org/software/systemd/man/systemd-cryptenroll.html

# Add tpm2-tss module to dracut
echo 'add_dracutmodules+=" tpm2-tss "' | sudo tee /etc/dracut.conf.d/tpm2.conf

# Enroll TPM2 as LUKS' decryption factor
sudo systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs "0+1+2+3+4+5+7+9" /dev/nvme0n1p3

# Update crypttab
sudo sed -i "s|discard|&,tpm2-device=auto,tpm2-pcrs=0+1+2+3+4+5+7+9|" /etc/crypttab

# Regenerate initramfs
sudo dracut --regenerate-all --force

################################################
##### Desktop Environment
################################################

# Install and configure desktop environment
if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/gnome.sh -O
    chmod +x ./gnome.sh
    ./gnome.sh
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/plasma.sh -O
    chmod +x ./plasma.sh
    ./plasma.sh
fi

################################################
##### Gaming
################################################

# Install and configure gaming with Flatpak
if [ ${GAMING} = "yes" ]; then
  curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/gaming.sh -O
  chmod +x ./gaming.sh
  ./gaming.sh
fi

################################################
##### Cleanup
################################################

# Delete downloaded scripts
rm -f {gnome,plasma,gaming}.sh