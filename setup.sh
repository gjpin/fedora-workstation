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

# Remove libreoffice
sudo dnf group remove -y libreoffice
sudo dnf remove -y *libreoffice*

# Disable ABRT service
sudo systemctl mask abrtd.service

# Disable mobile broadband modem management service
sudo systemctl mask ModemManager.service

# Disable PC/SC Smart Card service
sudo systemctl mask pcscd.service

# Disable location lookup service
sudo systemctl mask geoclue.service

# Disable speech dispatcher
sudo sed -i "s|^# DisableAutoSpawn|DisableAutoSpawn|g" /etc/speech-dispatcher/speechd.conf

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
  unrar \
  zstd \
  htop \
  xq \
  jq

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
##### RPM Fusion
################################################

# References:
# https://rpmfusion.org/Configuration/
# https://rpmfusion.org/Howto/Multimedia

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
if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo dnf install -y intel-media-driver
fi

# Install AMD hardware accelerated codecs
if lspci | grep VGA | grep "AMD" > /dev/null; then
  sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
  sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
fi

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

# References:
# https://docs.flatpak.org/en/latest/sandbox-permissions.html
# https://docs.flatpak.org/en/latest/sandbox-permissions-reference.html#filesystem-permissions

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable

# Restrict filesystem access
flatpak override --user --nofilesystem=home
flatpak override --user --nofilesystem=home/.ssh
flatpak override --user --nofilesystem=home/.bashrc
flatpak override --user --nofilesystem=home/.bashrc.d
flatpak override --user --nofilesystem=home/.config
flatpak override --user --nofilesystem=home/Sync
flatpak override --user --nofilesystem=host
flatpak override --user --nofilesystem=host-os
flatpak override --user --nofilesystem=host-etc
flatpak override --user --nofilesystem=xdg-config
flatpak override --user --nofilesystem=xdg-cache
flatpak override --user --nofilesystem=xdg-data
flatpak override --user --nofilesystem=xdg-data/flatpak
flatpak override --user --nofilesystem=xdg-documents
flatpak override --user --nofilesystem=xdg-videos
flatpak override --user --nofilesystem=xdg-music
flatpak override --user --nofilesystem=xdg-pictures
flatpak override --user --nofilesystem=xdg-desktop

# Restrict talk
flatpak override --user --no-talk-name=org.freedesktop.Flatpak

# Filesystem access exemptions
flatpak override --user --filesystem=xdg-download
flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
flatpak override --user --filesystem=xdg-config/gtk-4.0:ro

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
fi

# Install support for additional languages in Flatpak
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.openjdk/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.openjdk17/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.node18/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.typescript/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.golang/x86_64/22.08

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

# Allow Obsidian to access vault folder
flatpak override --user --filesystem=home/.obsidian md.obsidian.Obsidian

################################################
##### Bottles
################################################

# Install Bottles
flatpak install -y flathub com.usebottles.bottles

# Allow Bottles to create application shortcuts
flatpak override --user --filesystem=xdg-data/applications com.usebottles.bottles

# Allow Bottles to access Steam folder
flatpak override --user --filesystem=home/.var/app/com.valvesoftware.Steam/data/Steam com.usebottles.bottles

# Configure MangoHud
mkdir -p ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud
tee ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud/MangoHud.conf << EOF
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Remove native firefox
sudo dnf remove -y firefox
rm -rf ${HOME}/.mozilla

# Install Firefox from Flathub
flatpak install -y flathub org.mozilla.firefox

# Enable wayland support
flatpak override --user --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

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
##### Virtualization
################################################

# References:
# https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_virtualization/optimizing-virtual-machine-performance-in-rhel_configuring-and-managing-virtualization

# Install virtualization group
sudo dnf install -y @virtualization

# Enable libvirtd service
sudo systemctl enable libvirtd

################################################
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/python/python-installation.html
# https://developer.fedoraproject.org/tech/languages/rust/rust-installation.html
# # https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

# Set git configurations
git config --global init.defaultBranch main

# Set podman alias
tee ${HOME}/.bashrc.d/podman << EOF
alias docker="podman"
EOF

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

# Node and NPM
tee ${HOME}/.bashrc.d/node << 'EOF'
node_image='docker.io/node:slim'
node_ports='-p 3000:3000 -p 8080:8080 -p 8000:8000'

alias npm='podman run -it --rm --name=npm --init -v "$PWD":/usr/src/app:Z -w /usr/src/app $node_image npm'
alias node='podman run -it --rm --name=node --init -v "$PWD":/usr/src/app:Z -w /usr/src/app $node_ports $node_image node'
EOF

# mitmproxy
mkdir -p ${HOME}/.mitmproxy

tee ${HOME}/.bashrc.d/mitmproxy << 'EOF'
alias mitmproxy='podman run -it --rm --name=mitmproxy -v "$HOME"/.mitmproxy:/home/mitmproxy/.mitmproxy:Z -p 8080:8080 docker.io/mitmproxy/mitmproxy:latest'
alias mitmdump='podman run -it --rm --name=mitmdump -v "$HOME"/.mitmproxy:/home/mitmproxy/.mitmproxy:Z -p 8080:8080 docker.io/mitmproxy/mitmproxy:latest mitmdump'
alias mitmweb='podman run -it --rm --name=mitmweb -v "$HOME"/.mitmproxy:/home/mitmproxy/.mitmproxy:Z -p 8080:8080 -p 127.0.0.1:8081:8081 docker.io/mitmproxy/mitmproxy:latest mitmweb --web-host 0.0.0.0'
EOF

# Install OpenJDK
sudo dnf install -y \
  java-latest-openjdk \
  java-latest-openjdk-devel

################################################
##### IntelliJ IDEA Community
################################################

# Install IntelliJ IDEA Community
flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community

# Create required folders
mkdir -p \
  .java \
  .gradle

# Allow IntelliJ access to required folders
flatpak override --user --filesystem=home/.java com.jetbrains.IntelliJ-IDEA-Community
flatpak override --user --filesystem=home/.gradle com.jetbrains.IntelliJ-IDEA-Community

# Allow IntelliJ access to src folder
flatpak override --user --filesystem=home/src com.jetbrains.IntelliJ-IDEA-Community

# Allow IntelliJ access to .ssh folder
flatpak override --user --filesystem=home/.ssh:ro com.jetbrains.IntelliJ-IDEA-Community

# Allow IntelliJ access to .gitconfig file
flatpak override --user --filesystem=home/.gitconfig:ro com.jetbrains.IntelliJ-IDEA-Community

# Allow IntelliJ to read /etc (/etc/shells is required)
flatpak override --user --filesystem=host-etc:ro com.jetbrains.IntelliJ-IDEA-Community

# Enable support for additional languages
flatpak override --user --env='FLATPAK_ENABLE_SDK_EXT=openjdk,openjdk17' com.jetbrains.IntelliJ-IDEA-Community

################################################
##### Android Studio
################################################

# References:
# https://github.com/flathub/com.google.AndroidStudio/issues/81
# https://issuetracker.google.com/issues/117641628

# Install Android Studio
flatpak install -y flathub com.google.AndroidStudio

# Create required folders
mkdir -p \
  Android \
  .android \
  .m2 \
  .java \
  .gradle

# Allow Android Studio access to required folders
flatpak override --user --filesystem=home/Android com.google.AndroidStudio
flatpak override --user --filesystem=home/AndroidStudioProjects com.google.AndroidStudio
flatpak override --user --filesystem=home/.android com.google.AndroidStudio
flatpak override --user --filesystem=home/.m2 com.google.AndroidStudio
flatpak override --user --filesystem=home/.java com.google.AndroidStudio
flatpak override --user --filesystem=home/.gradle com.google.AndroidStudio

# Allow Android Studio access to src folder
flatpak override --user --filesystem=home/src com.google.AndroidStudio

# Allow Android Studio access to .ssh folder
flatpak override --user --filesystem=home/.ssh:ro com.google.AndroidStudio

# Allow Android Studio access to .gitconfig file
flatpak override --user --filesystem=home/.gitconfig:ro com.google.AndroidStudio

# Allow Android Studio to read /etc (/etc/shells is required)
flatpak override --user --filesystem=host-etc:ro com.google.AndroidStudio

# Workaround for incompatibility with BTRFS copy-on-write (see issue in references)
tee ${HOME}/.android/advancedFeatures.ini << EOF
QuickbootFileBacked = off
EOF

################################################
##### Android SDK tools
################################################

# References:
# https://developer.android.com/tools
# https://developer.android.com/studio/emulator_archive
# https://dl.google.com/android/repository/repository2-1.xml

# Set Android SDK directory
ANDROID_SDK_PATH=${HOME}/.android-sdk

# Create Android SDK directory
mkdir -p ${ANDROID_SDK_PATH}

# Download and install Android SDK command line tools
LATEST_CMDLINE_TOOLS_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r .version)
wget https://dl.google.com/android/repository/commandlinetools-linux-${LATEST_CMDLINE_TOOLS_VERSION}_latest.zip

unzip commandlinetools-linux-*_latest.zip -d ${ANDROID_SDK_PATH}/cmdline-tools
mv ${ANDROID_SDK_PATH}/cmdline-tools/* ${ANDROID_SDK_PATH}/cmdline-tools/latest
rm -f commandlinetools-linux-*.zip

# Android SDK build tools
LATEST_BUILD_TOOLS_VERSION=$(curl -s https://aur.archlinux.org/rpc/v5/info/android-sdk-build-tools | jq -r .results[0].Version | awk -F[.] '{print $1}')
wget https://dl.google.com/android/repository/build-tools_${LATEST_BUILD_TOOLS_VERSION}-linux.zip

unzip build-tools_r*-linux.zip -d ${ANDROID_SDK_PATH}/build-tools
mv ${ANDROID_SDK_PATH}/build-tools/* ${ANDROID_SDK_PATH}/build-tools/latest
rm -f build-tools_r*-linux.zip

# Android SDK platform tools
LATEST_PLATFORM_TOOLS_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-platform-tools.json | jq -r .version)
wget https://dl.google.com/android/repository/platform-tools_r${LATEST_PLATFORM_TOOLS_VERSION}-linux.zip

unzip platform-tools_r*-linux.zip -d ${ANDROID_SDK_PATH}
rm -f build-tools_r*-linux.zip

# Android emulator
wget https://dl.google.com/android/repository/emulator-linux_x64-10696886.zip

unzip emulator-linux_x64-*.zip -d ${ANDROID_SDK_PATH}
rm -f emulator-linux_x64-*.zip

# Set env vars
tee ${HOME}/.bashrc.d/android << EOF
export ANDROID_HOME='${ANDROID_SDK_PATH}'
export PATH="\${PATH}:\${ANDROID_HOME}/build-tools/latest"
export PATH="\${PATH}:\${ANDROID_HOME}/cmdline-tools/latest/bin"
export PATH="\${PATH}:\${ANDROID_HOME}/platform-tools"
export PATH="\${PATH}:\${ANDROID_HOME}/emulator"
EOF

################################################
##### VSCode (Flatpak)
################################################

# Install VSCode
flatpak install -y flathub com.visualstudio.code

# Allow VSCode access to src folder
flatpak override --user --filesystem=home/src com.visualstudio.code

# Allow VSCode access to .ssh folder
flatpak override --user --filesystem=home/.ssh:ro com.visualstudio.code

# Allow VSCode access to .gitconfig file
flatpak override --user --filesystem=home/.gitconfig:ro com.visualstudio.code

# Allow VSCode to read /etc (/etc/shells is required)
flatpak override --user --filesystem=host-etc:ro com.visualstudio.code

# Install extensions
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension ms-python.python
flatpak run com.visualstudio.code --install-extension redhat.vscode-yaml
flatpak run com.visualstudio.code --install-extension esbenp.prettier-vscode
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint

# Enable support for additional languages
flatpak override --user --env='FLATPAK_ENABLE_SDK_EXT=node18,typescript,golang' com.visualstudio.code

# Configure VSCode
mkdir -p ${HOME}/.var/app/com.visualstudio.code/config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json

# Add Flatpak specific configurations
sed -i '2 i \ \ \ \ "terminal.integrated.env.linux": {\
        "LD_PRELOAD": null,\
    },\
    "terminal.integrated.defaultProfile.linux": "bash",\
    "terminal.integrated.profiles.linux": {\
        "bash": {\
          "path": "/usr/bin/bash",\
          "icon": "terminal-bash",\
          "overrideName": true\
        }\
      },' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json

# Create alias
tee ${HOME}/.bashrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

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