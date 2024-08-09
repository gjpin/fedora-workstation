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
  jq \
  fuse-sshfs \
  fd-find \
  fzf \
  libva-utils \
  bc \
  ripgrep \
  yq \
  procps-ng \
  gawk \
  coreutils

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
DefaultTimeoutStopSec=5s
EOF

# Configure default timeout to stop user units
sudo mkdir -p /etc/systemd/user.conf.d
sudo tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

################################################
##### Tweaks
################################################

# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/configuration/general_system_tweaks/
# https://gitlab.com/cscs/maxperfwiz/-/blob/master/maxperfwiz?ref_type=heads
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap

# Sysctl tweaks
COMPUTER_MEMORY=$(echo $(vmstat -sS M | head -n1 | awk '{print $1;}'))
MEMORY_BY_CORE=$(echo $(( $(vmstat -s | head -n1 | awk '{print $1;}')/$(nproc) )))
BEST_KEEP_FREE=$(echo "scale=0; "$MEMORY_BY_CORE"*0.058" | bc | awk '{printf "%.0f\n", $1}')

sudo tee /etc/sysctl.d/99-performance-tweaks.conf << EOF
vm.page-cluster=0
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.nmi_watchdog=0
kernel.split_lock_mitigate=0
vm.compaction_proactiveness=0
vm.page_lock_unfairness=1
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_bytes=419430400"; fi)
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_background_bytes=209715200"; fi)
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_expire_centisecs=500"; else echo "vm.dirty_expire_centisecs=3000"; fi)
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_writeback_centisecs=250"; else echo "vm.dirty_writeback_centisecs=1500"; fi)
vm.min_free_kbytes=${BEST_KEEP_FREE}
EOF

# Udev tweaks
sudo tee /etc/udev/rules.d/99-performance-tweaks.rules << 'EOF'
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler} "mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler} "bfq"
EOF

# Hugepage Defragmentation - default: 1
# Transparent Hugepages - default: always
# Shared Memory in Transparent Hugepages - default: never
sudo tee /etc/systemd/system/kernel-tweaks.service << 'EOF'
[Unit]
Description=Set kernel tweaks
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/usr/bin/bash -c 'echo always > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/usr/bin/bash -c 'echo advise > /sys/kernel/mm/transparent_hugepage/shmem_enabled'
ExecStart=/usr/bin/bash -c 'echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable kernel-tweaks.service

# Disable watchdog timer drivers
# sudo dmesg | grep -e sp5100 -e iTCO -e wdt -e tco
sudo tee /etc/modprobe.d/disable-watchdog-drivers.conf << 'EOF'
blacklist sp5100_tco
blacklist iTCO_wdt
blacklist iTCO_vendor_support
EOF

# Disable broadcast messages
sudo tee /etc/systemd/system/disable-broadcast-messages.service << 'EOF'
[Unit]
Description=Disable broadcast messages
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/usr/bin/busctl set-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager EnableWallMessages b false

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable disable-broadcast-messages.service

################################################
##### ZSH
################################################

# Install ZSH and plugins
sudo dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting

# Configure ZSH
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.zshrc -o ${HOME}/.zshrc

# Configure powerlevel10k zsh theme
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.p10k.zsh -o ${HOME}/.p10k.zsh

# Add ~/.local/bin to the path
tee ${HOME}/.zshrc.d/local-bin << 'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
EOF

# Change user default shell to ZSH
chsh -s $(which zsh)

# Updater zsh function
tee ${HOME}/.zshrc.d/update-all << EOF
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
tee ${HOME}/.zshrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
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
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/23.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/23.08
flatpak install -y flathub org.freedesktop.Sdk//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.llvm16//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.rust-stable//23.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//23.08-extra
flatpak install -y flathub org.freedesktop.Platform.GL32.default//23.08-extra

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/23.08
fi

# Install applications
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak install -y flathub org.keepassxc.KeePassXC
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub rest.insomnia.Insomnia
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub com.github.marhkb.Pods

# Install Joplin
flatpak install -y flathub net.cozic.joplin_desktop
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/net.cozic.joplin_desktop -o ${HOME}/.local/share/flatpak/overrides/net.cozic.joplin_desktop

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

# Kubectl Krew updater
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ kubectl krew upgrade' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Krew plugins' ${HOME}/.zshrc.d/update-all

# Source krew temporarily
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install krew plugins
kubectl krew install ctx
kubectl krew install ns
kubectl krew install node-shell

# Kubernetes aliases and autocompletion
tee ${HOME}/.zshrc.d/kubectl << 'EOF'
# Kubectl alias
alias k="kubectl"
alias kx="kubectl ctx"
alias kn="kubectl ns"
alias ks="kubectl node-shell"

# Autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion zsh)

# Krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
EOF

# k9s
tee ${HOME}/.zshrc.d/k9s << 'EOF'
alias k9s="podman run --rm -it -v ~/.kube/config:/root/.kube/config quay.io/derailed/k9s"
EOF

################################################
##### Firefox
################################################

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.mozilla/firefox/*.default-release)

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
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/python/python-installation.html
# https://fedoraproject.org/wiki/SIGs/HC
# https://developer.fedoraproject.org/tech/languages/c/cpp_installation.html
# https://pytorch.org/get-started/locally/

# Set git configurations
git config --global init.defaultBranch main

# Set podman alias
tee ${HOME}/.zshrc.d/podman << EOF
alias docker="podman"
EOF

# Install make
sudo dnf install -y make

# Golang
sudo dnf install -y golang

mkdir -p ${HOME}/.devtools/go

tee ${HOME}/.zshrc.d/go << 'EOF'
export GOPATH="$HOME/.devtools/go"
EOF

# Create python dev sandbox virtualenv and alias
mkdir -p ${HOME}/.devtools/python

python -m venv ${HOME}/.devtools/python/dev

tee ${HOME}/.zshrc.d/python << 'EOF'
alias pydev="source ${HOME}/.devtools/python/dev/bin/activate"
EOF

# Install C++ compilers
sudo dnf install -y gcc-c++ clang clang-tools-extra llvm

################################################
##### Neovim
################################################

# Install Neovim and set as default editor
sudo dnf install -y neovim

tee ${HOME}/.zshrc.d/neovim << 'EOF'
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
##### VSCode (Native)
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
code --install-extension hashicorp.terraform

# Configure VSCode
mkdir -p ${HOME}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.config/Code/User/settings.json

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
