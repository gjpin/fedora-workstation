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
sudo systemctl mask pcscd.socket

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
  fzf

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
DefaultTimeoutStopSec=10s
EOF

# Configure default timeout to stop user units
sudo mkdir -p /etc/systemd/user.conf.d
sudo tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

################################################
##### ZSH
################################################

# Install ZSH and plugins
sudo dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting

# Install Oh-My-Zsh
# https://github.com/ohmyzsh/ohmyzsh#manual-installation
git clone https://github.com/ohmyzsh/ohmyzsh.git ${HOME}/.oh-my-zsh
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.zshrc -o ${HOME}/.zshrc

# Install powerlevel10k zsh theme
# https://github.com/romkatv/powerlevel10k#oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${HOME}/.oh-my-zsh/custom/themes/powerlevel10k
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.p10k.zsh -o ${HOME}/.p10k.zsh

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
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/global -o ${HOME}/.local/share/flatpak/overrides/global

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/23.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/23.08

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/23.08
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
flatpak install -y flathub org.chromium.Chromium
flatpak install -y flathub com.github.marhkb.Pods

# Install Obsidian
flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/md.obsidian.Obsidian -o ${HOME}/.local/share/flatpak/overrides/md.obsidian.Obsidian

################################################
##### Kubernetes
################################################

# Install kubectl
curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# kubectl updater
tee ${HOME}/.local/bin/update-kubectl << 'EOF'
LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
INSTALLED_VERSION=$(kubectl version --client --output=json | jq -r .clientVersion.gitVersion)

if [[ "${INSTALLED_VERSION}" != *"${LATEST_VERSION}"* ]]; then
  curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
fi
EOF

chmod +x ${HOME}/.local/bin/update-kubectl

sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-kubectl' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update kubectl' ${HOME}/.zshrc.d/update-all

# Install kubectx / kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# kubectx updater
tee ${HOME}/.local/bin/update-kubectx << 'EOF'
#!/usr/bin/bash

# Update kubectx
sudo git -C /opt/kubectx pull
EOF

chmod +x ${HOME}/.local/bin/update-kubectx

sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-kubectx' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update kubectx' ${HOME}/.zshrc.d/update-all

# Kubernetes aliases and autocompletion
tee ${HOME}/.zshrc.d/kubectl << 'EOF'
# Kubectl alias
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

# Autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion zsh)
EOF

# Install OpenLens
flatpak install -y flathub dev.k8slens.OpenLens
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/dev.k8slens.OpenLens -o ${HOME}/.local/share/flatpak/overrides/dev.k8slens.OpenLens

# Install Helm
LATEST_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
curl -s -Lo helm.tar.gz https://get.helm.sh/helm-${LATEST_VERSION}-linux-amd64.tar.gz
sudo tar -xzf helm.tar.gz -C /usr/local/bin linux-amd64/helm --strip-components 1
rm -f helm.tar.gz

# Helm updater
tee ${HOME}/.local/bin/update-helm << 'EOF'
LATEST_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
INSTALLED_VERSION=$(helm version --template='{{.Version}}')

if [[ "${INSTALLED_VERSION}" != *"${LATEST_VERSION}"* ]]; then
  curl -s -Lo helm.tar.gz https://get.helm.sh/helm-${LATEST_VERSION}-linux-amd64.tar.gz
  sudo tar -xzf helm.tar.gz -C /usr/local/bin linux-amd64/helm --strip-components 1
  rm -f helm.tar.gz
fi
EOF

chmod +x ${HOME}/.local/bin/update-helm

sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-helm' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Helm' ${HOME}/.zshrc.d/update-all

# Install Cilium
LATEST_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
curl -s -Lo cilium.tar.gz https://github.com/cilium/cilium-cli/releases/download/${LATEST_VERSION}/cilium-linux-amd64.tar.gz
sudo tar -xzf cilium.tar.gz -C /usr/local/bin
rm -f cilium.tar.gz

# Cilium updater
tee ${HOME}/.local/bin/update-cilium << 'EOF'
LATEST_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
INSTALLED_VERSION=$(cilium version --client | grep -o -P '(?<=cilium-cli: ).*(?= compiled)')

if [[ "${INSTALLED_VERSION}" != *"${LATEST_VERSION}"* ]]; then
  curl -s -Lo cilium.tar.gz https://github.com/cilium/cilium-cli/releases/download/${LATEST_VERSION}/cilium-linux-amd64.tar.gz
  sudo tar -xzf cilium.tar.gz -C /usr/local/bin
  rm -f cilium.tar.gz
fi
EOF

chmod +x ${HOME}/.local/bin/update-cilium

sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-cilium' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Cilium' ${HOME}/.zshrc.d/update-all

################################################
##### Terraform
################################################

# Install Terraform
LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/[^0-9.]*//g')
curl -s -o terraform.zip https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/terraform
rm -f terraform.zip

# Terraform updater
tee ${HOME}/.local/bin/update-terraform << 'EOF'
LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/[^0-9.]*//g')
INSTALLED_VERSION=$(terraform --version --json | jq -r .terraform_version)

if [[ "${INSTALLED_VERSION}" != *"${LATEST_VERSION}"* ]]; then
  curl -s -o terraform.zip https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_amd64.zip
  unzip terraform.zip
  sudo mv terraform /usr/local/bin/terraform
  rm -f terraform.zip
fi
EOF

chmod +x ${HOME}/.local/bin/update-terraform

sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-terraform' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Terraform' ${HOME}/.zshrc.d/update-all

################################################
##### Bottles
################################################

# Install Bottles
flatpak install -y flathub com.usebottles.bottles
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.usebottles.bottles -o ${HOME}/.local/share/flatpak/overrides/com.usebottles.bottles

# Create directory for Bottles games
mkdir -p ${HOME}/games/bottles

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

# Remove native firefox
sudo dnf remove -y firefox
rm -rf ${HOME}/.mozilla

# Install Firefox from Flathub
flatpak install -y flathub org.mozilla.firefox

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
##### Node.js
################################################

# References:
# https://github.com/nvm-sh/nvm#manual-install

# Install NVM
git clone https://github.com/nvm-sh/nvm.git ${HOME}/.devtools/nvm
cd ${HOME}/.devtools/nvm
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
cd

# Source NVM temporarily
export NVM_DIR="$HOME/.devtools/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Source NVM permanently
tee ${HOME}/.zshrc.d/nvm << 'EOF'
export NVM_DIR="$HOME/.devtools/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

# NVM updater
tee ${HOME}/.local/bin/update-nvm << 'EOF'
#!/usr/bin/bash

# Update NVM
cd ${HOME}/.devtools/nvm
git fetch --tags origin
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
cd
EOF

chmod +x ${HOME}/.local/bin/update-nvm

# Add nvm updater to updater function
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-nvm' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update NVM' ${HOME}/.zshrc.d/update-all

# Node updater
tee ${HOME}/.local/bin/update-node << 'EOF'
#!/usr/bin/bash

# Update node
nvm install --lts
nvm install-latest-npm
EOF

chmod +x ${HOME}/.local/bin/update-node

# Add node updater to updater function
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-node' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Node' ${HOME}/.zshrc.d/update-all

# Install Node LTS and latest supported NPM version
nvm install --lts
nvm install-latest-npm

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

# Install LazyVim
# https://www.lazyvim.org/installation
git clone https://github.com/LazyVim/starter ${HOME}/.config/nvim
rm -rf ${HOME}/.config/nvim/.git

# Install arctic.nvim (Dark Modern) color scheme in neovim
# https://github.com/rockyzhang24/arctic.nvim/tree/v2
# https://www.lazyvim.org/plugins/colorscheme
tee ${HOME}/.config/nvim/lua/plugins/colorscheme.lua << 'EOF'
return {
    {
        "gjpin/arctic.nvim",
        branch = "v2",
        dependencies = { "rktjmp/lush.nvim" }
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "arctic",
        }
    }
}
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
##### Unlock LUKS2 with TPM2 token
################################################

# References:
# https://fedoramagazine.org/use-systemd-cryptenroll-with-fido-u2f-or-tpm2-to-decrypt-your-disk/
# https://www.freedesktop.org/software/systemd/man/systemd-cryptenroll.html

# Add tpm2-tss module to dracut
echo 'add_dracutmodules+=" tpm2-tss "' | sudo tee /etc/dracut.conf.d/tpm2.conf

# Enroll TPM2 as LUKS' decryption factor
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device auto --tpm2-pcrs "0+1+2+3+4+5+7+9" /dev/nvme0n1p3

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