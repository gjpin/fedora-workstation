#!/usr/bin/bash

################################################
##### Set variables
################################################

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Desktop environment (gnome / plasma): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

read -p "Gaming (yes / no): " GAMING
export GAMING

read -p "Steam (native / flatpak): " STEAM_VERSION
export STEAM_VERSION

################################################
##### Remove unneeded packages and services
################################################

# Disable speech dispatcher
sudo sed -i "s|^# DisableAutoSpawn|DisableAutoSpawn|g" /etc/speech-dispatcher/speechd.conf

# Mask NetworkManager-wait-online service
sudo systemctl mask NetworkManager-wait-online.service

################################################
##### General
################################################

# Set hostname
sudo hostnamectl set-hostname --pretty "${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --static "${NEW_HOSTNAME}"

# Create common user directories
mkdir -p \
  ${HOME}/.local/share/applications \
  ${HOME}/.local/share/icons \
  ${HOME}/.local/share/themes \
  ${HOME}/.local/share/fonts \
  ${HOME}/.bashrc.d \
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
sudo tee -a /etc/dnf/dnf.conf << EOF
fastestmirror=True
max_parallel_downloads=10
keepcache=True
clean_requirements_on_remove=True
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
sudo dnf install -y \
  source-foundry-hack-fonts

# Install Nerd fonts
LATEST_NERDFONTS_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')

curl https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_NERDFONTS_VERSION}/FiraCode.tar.xz -L -O
tar -xf FiraCode.tar.xz -C ${HOME}/.local/share/fonts
rm -f FiraCode.tar.xz

curl https://github.com/ryanoasis/nerd-fonts/releases/download/${LATEST_NERDFONTS_VERSION}/Noto.tar.xz -L -O
tar -xf Noto.tar.xz -C ${HOME}/.local/share/fonts
rm -f Noto.tar.xz

fc-cache -f

# Updater helper
tee ${HOME}/.local/bin/update-all << EOF
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

################################################
##### SELinux
################################################

# Create aliases
tee ${HOME}/.bashrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
EOF

# Install setroubleshoot
sudo dnf install -y setroubleshoot

################################################
##### Toolbx
################################################

# References:
# https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/#toolbox-commands

# Install toolbox
sudo dnf install -y toolbox

# Create toolbox
toolbox create -y

# Update toolbox packages
toolbox run sudo dnf upgrade -y --refresh

# Install bind-utils (dig, etc)
toolbox run sudo dnf install -y bind-utils

# Install DNF plugins
toolbox run sudo dnf install -y dnf-plugins-core

# Android udev rules updater
tee -a ${HOME}/.local/bin/update-all << 'EOF'

################################################
##### Toolbx
################################################

# Update toolbox packages
toolbox run sudo dnf upgrade -y --refresh
EOF

################################################
##### RPM Fusion
################################################

# References:
# https://rpmfusion.org/Configuration/
# https://rpmfusion.org/Howto/Multimedia

if [ ${STEAM_VERSION} = "native" ]; then
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
DefaultTimeoutStopSec=5s
EOF

# Configure default timeout to stop user units
sudo mkdir -p /etc/systemd/user.conf.d
sudo tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
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

# Import global Flatpak overrides
mkdir -p ${HOME}/.local/share/flatpak/overrides
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/global -o ${HOME}/.local/share/flatpak/overrides/global

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full//23.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi//23.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//23.08-extra
flatpak install -y flathub org.freedesktop.Platform.GL32.default//23.08-extra

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel//23.08
fi

# Install Flatpak development runtimes
flatpak install -y flathub org.freedesktop.Sdk//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.golang//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.node20//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.typescript//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.llvm18//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.rust-stable//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.openjdk17//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.openjdk21//23.08

# Install applications
flatpak install -y flathub com.github.tchx84.Flatseal

flatpak install -y flathub com.bitwarden.desktop
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.bitwarden.desktop -o ${HOME}/.local/share/flatpak/overrides/com.bitwarden.desktop

flatpak install -y flathub com.belmoussaoui.Authenticator
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.belmoussaoui.Authenticator -o ${HOME}/.local/share/flatpak/overrides/com.belmoussaoui.Authenticator

flatpak install -y flathub org.keepassxc.KeePassXC
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.keepassxc.KeePassXC -o ${HOME}/.local/share/flatpak/overrides/org.keepassxc.KeePassXC

flatpak install -y flathub com.spotify.Client
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.spotify.Client -o ${HOME}/.local/share/flatpak/overrides/com.spotify.Client

flatpak install -y flathub org.gimp.GIMP
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.gimp.GIMP -o ${HOME}/.local/share/flatpak/overrides/org.gimp.GIMP

flatpak install -y flathub org.blender.Blender
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.blender.Blender -o ${HOME}/.local/share/flatpak/overrides/org.blender.Blender

flatpak install -y flathub com.brave.Browser
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.brave.Browser -o ${HOME}/.local/share/flatpak/overrides/com.brave.Browser

flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/md.obsidian.Obsidian -o ${HOME}/.local/share/flatpak/overrides/md.obsidian.Obsidian

# Development
flatpak install -y flathub com.usebruno.Bruno
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.usebruno.Bruno -o ${HOME}/.local/share/flatpak/overrides/com.usebruno.Bruno

flatpak install -y flathub com.github.marhkb.Pods
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.github.marhkb.Pods -o ${HOME}/.local/share/flatpak/overrides/com.github.marhkb.Pods

flatpak install -y flathub dev.skynomads.Seabird
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/dev.skynomads.Seabird -o ${HOME}/.local/share/flatpak/overrides/dev.skynomads.Seabird

################################################
##### Android udev rules
################################################

# References:
# https://github.com/M0Rf30/android-udev-rules

# Create Android SDK directory
mkdir -p ${HOME}/.devtools/android

# Android udev rules
git clone https://github.com/M0Rf30/android-udev-rules.git ${HOME}/.devtools/android/udev-rules

# Install udev rules
sudo ln -sf ${HOME}/.devtools/android/udev-rules/51-android.rules /etc/udev/rules.d/51-android.rules
sudo chmod a+r /etc/udev/rules.d/51-android.rules

# Create adbusers group
sudo groupadd adbusers

# Add user to the adbusers group
sudo gpasswd -a ${USER} adbusers

# Android udev rules updater
tee -a ${HOME}/.local/bin/update-all << 'EOF'

################################################
##### Android udev rules
################################################

# Update Android udev rules
git -C ${HOME}/.devtools/android/udev-rules pull
EOF

################################################
##### Android SDK tools
################################################

# https://developer.android.com/tools/variables
# https://developer.android.com/tools
# https://developer.android.com/studio/emulator_archive
# https://dl.google.com/android/repository/repository2-1.xml

# Create Android SDK directory
mkdir -p ${HOME}/.devtools/android

# Install Android SDK command line tools
CMDLINE_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r .version)
curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_LATEST_VERSION}_latest.zip -O
unzip commandlinetools-linux-*_latest.zip -d ${HOME}/.devtools/android
rm -f commandlinetools-linux-*.zip
echo ${CMDLINE_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/cmdline_tools_installed_version

# Accept sdkmanager licenses
yes | ${HOME}/.devtools/android/cmdline-tools/bin/sdkmanager --sdk_root=${HOME}/.devtools/android --licenses

# Install Android SDK platform tools
PLATFORM_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-platform-tools.json | jq -r .version)
curl -sSL https://dl.google.com/android/repository/platform-tools_r${PLATFORM_TOOLS_LATEST_VERSION}-linux.zip -O
unzip platform-tools_r*-linux.zip -d ${HOME}/.devtools/android
rm -f platform-tools_r*-linux.zip
echo ${PLATFORM_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/platform_tools_installed_version

# Set env vars and paths
tee ${HOME}/.bashrc.d/android << EOF
# Android env vars
export ANDROID_HOME='${HOME}/.devtools/android'
export ANDROID_SDK_ROOT='${HOME}/.devtools/android'

# Add tools to path
export PATH="\${PATH}:\${ANDROID_HOME}/platform-tools"
export PATH="\${PATH}:\${ANDROID_HOME}/cmdline-tools/bin"
EOF

# Android tools updater
tee -a ${HOME}/.local/bin/update-all << 'EOF'

################################################
##### Android SDK tools
################################################

# cmdline tools versions
INSTALLED_CMDLINE_TOOLS_VERSION=$(cat ${HOME}/.devtools/android/cmdline_tools_installed_version)
CMDLINE_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r .version)

# platform tools versions
INSTALLED_PLATFORM_TOOLS_VERSION=$(cat ${HOME}/.devtools/android/platform_tools_installed_version)
PLATFORM_TOOLS_LATEST_VERSION=$(curl -s https://formulae.brew.sh/api/cask/android-platform-tools.json | jq -r .version)

# Update cmdline tools
if [[ "${INSTALLED_CMDLINE_TOOLS_VERSION}" != "${CMDLINE_TOOLS_LATEST_VERSION}" ]]; then
  curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_LATEST_VERSION}_latest.zip -O
  rm -rf ${HOME}/.devtools/android/cmdline-tools
  unzip commandlinetools-linux-*_latest.zip -d ${HOME}/.devtools/android
  rm -f commandlinetools-linux-*.zip
  echo ${CMDLINE_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/cmdline_tools_installed_version
fi

# Update platform tools
if [[ "${INSTALLED_PLATFORM_TOOLS_VERSION}" != "${PLATFORM_TOOLS_LATEST_VERSION}" ]]; then
  curl -sSL https://dl.google.com/android/repository/platform-tools_r${PLATFORM_TOOLS_LATEST_VERSION}-linux.zip -O
  rm -rf ${HOME}/.devtools/android/platform-tools
  unzip platform-tools_r*-linux.zip -d ${HOME}/.devtools/android
  rm -f platform-tools_r*-linux.zip
  echo ${PLATFORM_TOOLS_LATEST_VERSION} > ${HOME}/.devtools/android/platform_tools_installed_version
fi
EOF

################################################
##### Java - OpenJDK
################################################

# References:
# https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

# Install OpenJDK 17
sudo dnf install -y \
  java-17-openjdk \
  java-17-openjdk-devel

# Install OpenJDK 21
sudo dnf install -y \
  java-21-openjdk \
  java-21-openjdk-devel

# Set default Java version to 21
sudo alternatives --set java java-21-openjdk.x86_64

################################################
##### Bottles
################################################

# Install Bottles
flatpak install -y flathub com.usebottles.bottles
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.usebottles.bottles -o ${HOME}/.local/share/flatpak/overrides/com.usebottles.bottles

# Configure MangoHud
mkdir -p ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud

################################################
##### Cloud / Kubernetes
################################################

# References:
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
# https://github.com/ahmetb/kubectx
# https://github.com/kvaps/kubectl-node-shell

# Install OpenTofu
sudo dnf install -y opentofu

# Install kubectl and helm
sudo dnf install -y kubernetes-client

# Install helm
sudo dnf install -y helm

# Install Krew
mkdir -p /tmp/krew
curl -sSL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -o /tmp/krew/krew.tar.gz
tar zxvf /tmp/krew/krew.tar.gz -C /tmp/krew
./tmp/krew/krew-linux_amd64 install krew
rm -rf /tmp/krew

# Add Kubectl Krew updater to main updater
tee -a ${HOME}/.local/bin/update-all << EOF

################################################
##### Kubectl Krew plugins
################################################

# Update Kubectl Krew plugins
kubectl krew upgrade
EOF

# Source krew temporarily
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install krew plugins
kubectl krew install ctx
kubectl krew install ns
kubectl krew install node-shell

# Kubernetes aliases and autocompletion
tee ${HOME}/.bashrc.d/kubernetes << 'EOF'
# Kubectl alias
alias k="kubectl"
alias kx="kubectl ctx"
alias kn="kubectl ns"
alias ks="kubectl node-shell"

# Autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion bash)

# Krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
EOF

# k9s
tee -a ${HOME}/.bashrc.d/kubernetes << 'EOF'

# k9s
alias k9s="podman run --rm -it -v ~/.kube/config:/root/.kube/config quay.io/derailed/k9s"
EOF

################################################
##### Office / Documents
################################################

# Remove LibreOffice (native)
sudo dnf group remove -y libreoffice
sudo dnf remove -y *libreoffice*

# Install LibreOffice (Flatpak)
flatpak install -y flathub org.libreoffice.LibreOffice
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.libreoffice.LibreOffice -o ${HOME}/.local/share/flatpak/overrides/org.libreoffice.LibreOffice

# Install Gaphor
flatpak install -y flathub org.gaphor.Gaphor
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.gaphor.Gaphor -o ${HOME}/.local/share/flatpak/overrides/org.gaphor.Gaphor

# Install Rnote
flatpak install -y flathub com.github.flxzt.rnote
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.github.flxzt.rnote -o ${HOME}/.local/share/flatpak/overrides/com.github.flxzt.rnote

################################################
##### Firefox
################################################

# Remove native firefox
sudo dnf remove -y firefox
rm -rf ${HOME}/.mozilla

# Install Firefox from Flathub
flatpak install -y flathub org.mozilla.firefox
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.mozilla.firefox -o ${HOME}/.local/share/flatpak/overrides/org.mozilla.firefox

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

# Add user to libvirt group
sudo usermod -a -G libvirt ${USER}

################################################
##### Podman
################################################

# Set podman alias
tee ${HOME}/.bashrc.d/podman << EOF
alias docker="podman"
EOF

# Enable Podman socket
systemctl --user enable podman.socket

################################################
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/python/python-installation.html
# https://fedoraproject.org/wiki/SIGs/HC
# https://developer.fedoraproject.org/tech/languages/c/cpp_installation.html
# https://pytorch.org/get-started/locally/

# Install gitg
flatpak install -y flathub org.gnome.gitg
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.gnome.gitg -o ${HOME}/.local/share/flatpak/overrides/org.gnome.gitg

# Set git configurations
git config --global init.defaultBranch main

# Install nodejs
sudo dnf install -y nodejs npm

# Install cfssl
sudo dnf install -y golang-github-cloudflare-cfssl

# Install make
sudo dnf install -y make

# Install go
sudo dnf install -y golang

mkdir -p ${HOME}/.devtools/go

tee ${HOME}/.bashrc.d/go << 'EOF'
export GOPATH="$HOME/.devtools/go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Create python dev sandbox virtualenv and alias
mkdir -p ${HOME}/.devtools/python

python -m venv ${HOME}/.devtools/python/dev

tee ${HOME}/.bashrc.d/python << 'EOF'
alias pydev="source ${HOME}/.devtools/python/dev/bin/activate"
EOF

# Install C++ compilers
sudo dnf install -y gcc-c++ clang clang-tools-extra llvm

################################################
##### Neovim
################################################

# Install Neovim and set as default editor
sudo dnf install -y neovim

tee ${HOME}/.bashrc.d/neovim << 'EOF'
# Set neovim alias
alias vi=nvim
alias vim=nvim

# Set preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi
EOF

################################################
##### VSCode (Flatpak)
################################################

# References:
# https://github.com/David-VTUK/turing-pi-ansible/blob/main/.devcontainer/devcontainer.json#L19

# Install VSCode
flatpak install -y flathub com.visualstudio.code
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.visualstudio.code -o ${HOME}/.local/share/flatpak/overrides/com.visualstudio.code

# Install extensions
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension ms-python.python
flatpak run com.visualstudio.code --install-extension redhat.vscode-yaml
flatpak run com.visualstudio.code --install-extension esbenp.prettier-vscode
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint
flatpak run com.visualstudio.code --install-extension hashicorp.terraform

# Configure VSCode
mkdir -p ${HOME}/.var/app/com.visualstudio.code/config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json

# Create alias
tee ${HOME}/.bashrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

################################################
##### Godot (Flatpak)
################################################

# References:
# https://github.com/flathub/org.godotengine.Godot

# Install Godot
flatpak install -y flathub org.godotengine.Godot
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/org.godotengine.Godot -o ${HOME}/.local/share/flatpak/overrides/org.godotengine.Godot

# Blender wrapper
tee ${HOME}/.local/bin/blender-flatpak-wrapper << 'EOF'
#!/usr/bin/bash

flatpak-spawn --host flatpak run org.blender.Blender "$@"
EOF

chmod +x ${HOME}/.local/bin/blender-flatpak-wrapper

# Pin Godot version
flatpak mask org.godotengine.Godot

################################################
##### Syncthing
################################################

# Install syncthing and enable service
sudo dnf install -y syncthing
systemctl --user enable syncthing.service

################################################
##### Power management
################################################

# References:
# https://wiki.archlinux.org/title/Power_management
# https://wiki.archlinux.org/title/CPU_frequency_scaling#cpupower
# https://gitlab.com/corectrl/corectrl/-/wikis/Setup
# https://wiki.archlinux.org/title/AMDGPU#Performance_levels

# Apply power managament configurations according to device type
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]; then
    # Enable audio power saving features
    echo 'options snd_hda_intel power_save=1' | sudo tee /etc/modprobe.d/audio_powersave.conf

    # Enable wifi (iwlwifi) power saving features
    echo 'options iwlwifi power_save=1' | sudo tee /etc/modprobe.d/iwlwifi.conf
else
    if lspci | grep "VGA" | grep "AMD" > /dev/null; then
        # AMD scaling driver
        sudo grubby --update-kernel=ALL --args=amd_pstate=active

        # Set AMD GPU performance level to High
        echo 'SUBSYSTEM=="pci", DRIVER=="amdgpu", ATTR{power_dpm_force_performance_level}="high"' | sudo tee /etc/udev/rules.d/30-amdgpu-high-power.rules
    fi
fi

################################################
##### Unlock LUKS2 with TPM2 token
################################################

# References:
# https://fedoramagazine.org/use-systemd-cryptenroll-with-fido-u2f-or-tpm2-to-decrypt-your-disk/
# https://www.freedesktop.org/software/systemd/man/systemd-cryptenroll.html

# Add tpm2-tss module to dracut
echo 'add_dracutmodules+=" tpm2-tss "' | sudo tee /etc/dracut.conf.d/tpm2.conf

# Enroll TPM2 as LUKS' decryption factor
if sudo btrfs filesystem usage / | grep RAID0 > /dev/null; then
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme0n1p3
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme1n1p1
else
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto /dev/nvme0n1p3
fi

# Update crypttab
sudo sed -i "s|discard|&,tpm2-device=auto|" /etc/crypttab

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
