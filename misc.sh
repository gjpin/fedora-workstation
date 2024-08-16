#!/usr/bin/bash

# Install Obsidian
flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/md.obsidian.Obsidian -o ${HOME}/.local/share/flatpak/overrides/md.obsidian.Obsidian

# Install OpenLens
flatpak install -y flathub dev.k8slens.OpenLens
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/dev.k8slens.OpenLens -o ${HOME}/.local/share/flatpak/overrides/dev.k8slens.OpenLens

################################################
##### Firefox (Flatpak)
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
vm.page-cluster=0 # default: 3
vm.swappiness=10 # default: 60
vm.vfs_cache_pressure=50 # default: 100
kernel.nmi_watchdog=0 # default: 0
kernel.split_lock_mitigate=0 # default: 1
vm.compaction_proactiveness=0 # default: 20
vm.page_lock_unfairness=1 # default: 5
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_bytes=419430400"; fi) # default: 0
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_background_bytes=209715200"; fi) # default: 0
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_expire_centisecs=500"; else echo "vm.dirty_expire_centisecs=3000"; fi) # default: 3000
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_writeback_centisecs=250"; else echo "vm.dirty_writeback_centisecs=1500"; fi) # default: 500
vm.min_free_kbytes=${BEST_KEEP_FREE} # default: 67584
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
##### VSCode (Adwaita theme)
################################################

# References:
# https://github.com/piousdeer/vscode-adwaita

# Install VSCode Gnome theme
code --install-extension piousdeer.adwaita-theme

# Change VSCode config to use theme
sed -i '2 i \ \ \ \ "workbench.preferredDarkColorTheme": "Adwaita Dark",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.preferredLightColorTheme": "Adwaita Light",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' ${HOME}/.config/Code/User/settings.json

################################################
##### lazyvim
################################################

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

# Cleanup
rm -f ${HOME}/LICENSE.txt

################################################
##### Cloud / Kubernetes
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
##### Disable unneeded services
################################################

# Disable tracker services
systemctl --user mask \
  tracker-extract-3.service \
  tracker-miner-fs-control-3.service \
  tracker-writeback-3.service \
  tracker-miner-fs-3.service \
  tracker-miner-rss-3.service \
  tracker-xdg-portal-3.service

################################################
##### Bottles
################################################

# Install Bottles
flatpak install -y flathub com.usebottles.bottles
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.usebottles.bottles -o ${HOME}/.local/share/flatpak/overrides/com.usebottles.bottles

# Configure MangoHud
mkdir -p ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud

# Create folder for Bottles repos
mkdir -p ${HOME}/src/bottles

# Clone Bottles dependencies repo
git clone https://github.com/bottlesdevs/dependencies.git ${HOME}/src/bottles/dependencies

# Alias for bottles with local dependencies
tee ${HOME}/.zshrc.d/bottles << EOF
# Set bottles alias
alias bottles_local="LOCAL_DEPENDENCIES=${HOME}/src/bottles/dependencies flatpak run com.usebottles.bottles"
EOF

################################################
##### Remove unneeded services
################################################

# Disable ABRT service
sudo systemctl mask abrtd.service

# Disable mobile broadband modem management service
sudo systemctl mask ModemManager.service

# Disable PC/SC Smart Card service
sudo systemctl mask pcscd.service
sudo systemctl mask pcscd.socket

# Disable location lookup service
sudo systemctl mask geoclue.service

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

# Source NVM
export NVM_DIR="$HOME/.devtools/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

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
##### ROCm
################################################

# Install ROCm packages
if lspci | grep "VGA" | grep "AMD" > /dev/null; then
sudo usermod -a -G video ${USER}
sudo usermod -a -G render ${USER}
sudo dnf install -y \
  rocminfo rocm-clinfo \
  rocm-opencl rocm-opencl-devel \
  rocm-hip rocm-hip-devel \
  rocm-runtime rocm-runtime-devel \
  rocm-smi rocm-smi-devel \
  rocm-cmake rocm-comgr rocm-comgr-devel rocm-device-libs

tee ${HOME}/.zshrc.d/rocm << EOF
# Confirm "Node:" of GPU with rocminfo
export HIP_VISIBLE_DEVICES=1

# If GPU is not officially supported, pretend to be 6900xt
export HSA_OVERRIDE_GFX_VERSION=10.3.0
export HCC_AMDGPU_TARGET=gfx1030
EOF
fi

# Install CLBlast packages
sudo dnf install -y clblast clblast-devel clblast-tuners

################################################
##### PyTorch
################################################

# References:
# Check supported python version at (eg. cp311 for python 3.11): https://download.pytorch.org/whl/rocm5.6/torch/

# Install Python 3.11
sudo dnf install -y python3.11

# Create venv for pytorch
python3.11 -m venv ${HOME}/.python/pytorch

tee -a ${HOME}/.zshrc.d/python << 'EOF'
alias pytorch="source ${HOME}/.python/pytorch/bin/activate"
EOF

# Enable pytorch venv
source ${HOME}/.python/pytorch/bin/activate

# Install pytorch
if lspci | grep "VGA" | grep "AMD" > /dev/null; then
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.6
fi

# Deactivate pytorch venv
deactivate

################################################
##### Minikube (kubernetes)
################################################

# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm

# todo: add auto updater
# check current and latest versions: minikube update-check
# if they are different, then download latest rpm, install it and remove rpm file

# Set minikube default settings
minikube config set driver kvm2
minikube config set container-runtime containerd
minikube config set memory 8192
minikube config set cpus 4

# Enable minikube ingress addon
minikube addons enable ingress

################################################
##### Kind (kubernetes)
################################################

# Install kind
# https://kind.sigs.k8s.io/docs/user/rootless/
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

tee ${HOME}/.zshrc.d/kind << 'EOF'
# Enable podman backend in Kind
KIND_EXPERIMENTAL_PROVIDER=podman

# Alias
alias kind-single-node="kind create cluster --name single-node"
alias kind-multi-node="kind create cluster --name multi-node --config ${HOME}/.kind/kind-multi-node.yaml"
EOF

echo "source <(kind completion bash)" >> ${HOME}/.zshrc.d/kind

mkdir -p ${HOME}/.kind
tee ${HOME}/.kind/kind-multi-node.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

# todo: add auto updater
# check current and latest versions
# if they are different, then download latest version

################################################
##### Icon theme
################################################

# References:
# https://github.com/somepaulo/MoreWaita

# Create MoreWaita directory
mkdir -p ${HOME}/.local/share/icons/MoreWaita

# Install MoreWaita icon theme
git clone https://github.com/somepaulo/MoreWaita.git ${HOME}/.local/share/icons/MoreWaita

# Update icon theme cache
gtk-update-icon-cache -f -t ${HOME}/.local/share/icons/MoreWaita
xdg-desktop-menu forceupdate

# Set MoreWaita icon theme
gsettings set org.gnome.desktop.interface icon-theme 'MoreWaita'

# MoreWaita icon theme updater
tee ${HOME}/.local/bin/update-morewaita-icon-theme << 'EOF'
#!/usr/bin/bash

# Update MoreWaita icon theme
git -C ${HOME}/.local/share/icons/MoreWaita pull

# Update Icon theme cache
gtk-update-icon-cache -f -t ${HOME}/.local/share/icons/MoreWaita
xdg-desktop-menu forceupdate
EOF

chmod +x ${HOME}/.local/bin/update-morewaita-icon-theme

# Add MoreWaita icon theme updater to bash updater function
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ update-morewaita-icon-theme' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update MoreWaita icon theme' ${HOME}/.zshrc.d/update-all

################################################
##### VSCode (Flatpak)
################################################

# Install support for additional languages in Flatpak
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.openjdk17/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.openjdk17/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.dotnet7/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.dotnet7/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.node18/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.node18/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.typescript/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.typescript/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.golang/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.golang/x86_64/23.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.rust-stable/x86_64/22.08
flatpak install -y flathub runtime/org.freedesktop.Sdk.Extension.rust-stable/x86_64/23.08

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
flatpak override --user --env='FLATPAK_ENABLE_SDK_EXT=node18,typescript,golang,openjdk17,dotnet7,rust-stable' com.visualstudio.code

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
tee ${HOME}/.zshrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

# Install VSCode Gnome theme
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme

# Change VSCode config to use theme
sed -i '2 i \ \ \ \ "workbench.preferredDarkColorTheme": "Adwaita Dark",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.preferredLightColorTheme": "Adwaita Light",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json

################################################
##### Cockpit
################################################

# References:
# https://cockpit-project.org/running.html#fedora

# Install cockpit
sudo dnf install -y cockpit

# Enable cockpit
sudo systemctl enable cockpit.socket

################################################
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/rust/rust-installation.html
# https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

# Install cfssl
sudo dnf install -y golang-github-cloudflare-cfssl

# mitmproxy
mkdir -p ${HOME}/.mitmproxy

tee ${HOME}/.zshrc.d/mitmproxy << 'EOF'
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
  ${HOME}/.java \
  ${HOME}/.gradle

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
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/com.google.AndroidStudio -o ${HOME}/.local/share/flatpak/overrides/com.google.AndroidStudio

# Workaround for incompatibility with BTRFS copy-on-write (see issue in references)
mkdir -p ${HOME}/.android
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
rm -f platform-tools_r*-linux.zip

# Android emulator
wget https://dl.google.com/android/repository/emulator-linux_x64-11150993.zip

unzip emulator-linux_x64-*.zip -d ${ANDROID_SDK_PATH}
rm -f emulator-linux_x64-*.zip

# Set env vars
tee ${HOME}/.zshrc.d/android << EOF
export ANDROID_HOME='${ANDROID_SDK_PATH}'
export PATH="\${PATH}:\${ANDROID_HOME}/build-tools/latest"
export PATH="\${PATH}:\${ANDROID_HOME}/cmdline-tools/latest/bin"
export PATH="\${PATH}:\${ANDROID_HOME}/platform-tools"
export PATH="\${PATH}:\${ANDROID_HOME}/emulator"
EOF

################################################
##### Deno
################################################

# Install deno
mkdir -p ${HOME}/.deno/bin
curl https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -L -O
unzip -o deno-x86_64-unknown-linux-gnu.zip -d ${HOME}/.deno/bin
rm -f deno-x86_64-unknown-linux-gnu.zip

# Add Deno to path
tee ${HOME}/.zshrc.d/deno << 'EOF'
export DENO_INSTALL=${HOME}/.deno
export PATH="$PATH:$DENO_INSTALL/bin"
EOF
  
# Add Deno updater to bash updater function
sed -i '2 i \ ' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ deno upgrade' ${HOME}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Deno' ${HOME}/.zshrc.d/update-all

# Install Deno VSCode extension
code --install-extension denoland.vscode-deno

################################################
##### Lutris
################################################

# Install Lutris
flatpak install -y flathub net.lutris.Lutris

# Allow Lutris to create application shortcuts
flatpak override --user --filesystem=xdg-data/applications net.lutris.Lutris

# Allow Lutris access to its folder
flatpak override --user --filesystem=/data/games/lutris net.lutris.Lutris

# Allow Lutris access to Steam (Lutris expects to find Steam at ~/.steam)
ln -s ${HOME}/.var/app/com.valvesoftware.Steam/.steam ${HOME}/.steam
flatpak override --user --filesystem=home/.var/app/com.valvesoftware.Steam/data/Steam net.lutris.Lutris

# Deny Lutris talk
flatpak override --user --no-talk-name=org.freedesktop.Flatpak net.lutris.Lutris

# Configure MangoHud for Lutris
mkdir -p ${HOME}/.var/app/net.lutris.Lutris/config/MangoHud
tee ${HOME}/.var/app/net.lutris.Lutris/config/MangoHud/MangoHud.conf << EOF
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
##### Wine
################################################

# References:
# https://github.com/Winetricks/winetricks/blob/master/files/verbs/download.txt
# https://github.com/FanderWasTaken/wine-dependency-hell-solver
# https://github.com/Matoking/protontricks

# Install Wine and dependencies
flatpak install -y flathub app/org.winehq.Wine/x86_64/stable-23.08
flatpak install -y flathub runtime/org.winehq.Wine.gecko/x86_64/stable-23.08
flatpak install -y flathub runtime/org.winehq.Wine.mono/x86_64/stable-23.08

# Deny Wine internet access
flatpak override --user --unshare=network org.winehq.Wine

# Prevent installing Mono/Gecko
flatpak override --user --env='WINEDLLOVERRIDES=mscoree=d;mshtml=d' org.winehq.Wine

# Set wine alias
tee ${HOME}/.zshrc.d/wine << 'EOF'
alias wine="flatpak run org.winehq.Wine"
alias wineuninstaller="flatpak run org.winehq.Wine uninstaller"
alias winecfg="flatpak run --command=winecfg org.winehq.Wine"
alias winetricks="flatpak run --command=winetricks org.winehq.Wine"
alias winemango="flatpak run --command=mangohud org.winehq.Wine wine"
alias winegamescope="flatpak run --command=gamescope org.winehq.Wine -f -- wine"
EOF

# Disable Large Address Aware
flatpak override --user --env='WINE_LARGE_ADDRESS_AWARE=0' org.winehq.Wine

# Install dependencies
flatpak run --command=winetricks org.winehq.Wine --unattended --force vcrun2022
sleep 5
flatpak run --command=winetricks org.winehq.Wine --unattended --force faudio
sleep 5

# Create wine directories
mkdir -p ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/system32
mkdir -p ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/syswow64

# Install DXVK
LATEST_DXVK_VERSION=$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
curl https://github.com/doitsujin/dxvk/releases/latest/download/dxvk-${LATEST_DXVK_VERSION}.tar.gz -L -O
tar -xzf dxvk-${LATEST_DXVK_VERSION}.tar.gz -C ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/system32 dxvk-${LATEST_DXVK_VERSION}/x64/* --strip-components 2
tar -xzf dxvk-${LATEST_DXVK_VERSION}.tar.gz -C ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/syswow64 dxvk-${LATEST_DXVK_VERSION}/x32/* --strip-components 2
rm -f tar -xzf dxvk-${LATEST_DXVK_VERSION}.tar.gz

flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d11 /d native /f
sleep 5
flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d10core /d native /f
sleep 5
flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v dxgi /d native /f
sleep 5
flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d9 /d native /f
sleep 5

# Install VKD3D
LATEST_VKD3D_VERSION=$(curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
curl https://github.com/HansKristian-Work/vkd3d-proton/releases/latest/download/vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -L -O
tar -xf vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -C ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/system32 vkd3d-proton-${LATEST_VKD3D_VERSION}/x64/* --strip-components 2
tar -xf vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -C ${HOME}/.var/app/org.winehq.Wine/data/wine/drive_c/windows/syswow64 vkd3d-proton-${LATEST_VKD3D_VERSION}/x86/* --strip-components 2
rm -f vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst

flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d12 /d native /f
sleep 5
flatpak run org.winehq.Wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d12core /d native /f
sleep 5

# Install and configure MangoHud and Gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08
flatpak override --user --env='PATH=/app/bin:/usr/bin:/usr/lib/extensions/vulkan/MangoHud/bin:/usr/lib/extensions/vulkan/gamescope/bin' org.winehq.Wine

mkdir -p ${HOME}/.var/app/org.winehq.Wine/config/MangoHud
tee ${HOME}/.var/app/org.winehq.Wine/config/MangoHud/MangoHud.conf << EOF
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

# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dx9
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dx10
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dx11_43
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dcompiler_42
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dcompiler_43
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dcompiler_46
# flatpak run --command=winetricks org.winehq.Wine --unattended --force d3dcompiler_47
# flatpak run --command=winetricks org.winehq.Wine --unattended --force dotnet40
# flatpak run --command=winetricks org.winehq.Wine --unattended --force dotnet40_kb2468871
# flatpak run --command=winetricks org.winehq.Wine --unattended --force dotnet48
# flatpak run --command=winetricks org.winehq.Wine --unattended --force dotnetdesktop6
# flatpak run --command=winetricks org.winehq.Wine --unattended --force xna40
# flatpak run --command=winetricks org.winehq.Wine --unattended --force faudio
# flatpak run --command=winetricks org.winehq.Wine --unattended --force corefonts
# flatpak run --command=winetricks org.winehq.Wine --unattended --force physx
# flatpak run --command=winetricks org.winehq.Wine --unattended --force dxvk
# flatpak run --command=winetricks org.winehq.Wine --unattended --force vkd3d
# flatpak run --command=winetricks org.winehq.Wine --unattended --force mf

################################################
##### MangoHud (native)
################################################

# Install MangoHud
sudo dnf install -y mangohud

# Configure MangoHud
mkdir -p ${HOME}/.config/MangoHud
tee ${HOME}/.config/MangoHud/MangoHud.conf << EOF
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
##### Gnome Shell Extensions
################################################

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v11.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
sudo dnf install -y openssl

curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v55.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
sudo dnf install -y xprop

curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v9.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

gsettings --schemadir ~/.local/share/gnome-shell/extensions/dark-variant@hardpixel.eu/schemas set org.gnome.shell.extensions.dark-variant applications "['code.desktop', 'com.visualstudio.code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.spotify.Client.desktop', 'md.obsidian.Obsidian.desktop', 'org.gimp.GIMP.desktop', 'org.blender.Blender.desktop', 'org.godotengine.Godot.desktop', 'com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop', 'org.duckstation.DuckStation.desktop', 'net.pcsx2.PCSX2.desktop', 'org.ppsspp.PPSSPP.desktop', 'app.xemu.xemu.desktop']"

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['rounded-window-corners@yilozt', 'appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'grand-theft-focus@zalckos.github.com', 'gsconnect@andyholmes.github.io', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']"

################################################
##### Fonts
################################################

# Ubuntu fonts
curl -sSL https://assets.ubuntu.com/v1/0cef8205-ubuntu-font-family-0.83.zip -o ubuntu-font.zip
unzip -j ubuntu-font.zip ubuntu-font-family-0.83/*.ttf -d ${HOME}/.local/share/fonts
rm -f ubuntu-font.zip
fc-cache ${HOME}/.local/share/fonts

################################################
##### Mounts
################################################

# Enable additional BTRFS options and change ZSTD compression level
if grep -E 'noatime|space_cache|discard|ssd' /etc/fstab; then
  echo "Possible conflict. No changes have been made."
else
  sudo sed -i "s|compress=zstd:1|&,noatime,ssd,space_cache=v2,discard=async|" /etc/fstab
  sudo sed -i "s|compress=zstd:1|compress=zstd:3|g" /etc/fstab
  sudo systemctl daemon-reload
fi

################################################
##### Flatpak mesa git
################################################

# References:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git

# Add Flathub beta repo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak remote-modify flathub-beta --enable

# Install Mesa git
flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git//23.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git//23.08

# Make Steam use mesa-git
flatpak override --user --env=FLATPAK_GL_DRIVERS=mesa-git com.valvesoftware.Steam

# Make Heroic use mesa-git
flatpak override --user --env=FLATPAK_GL_DRIVERS=mesa-git com.heroicgameslauncher.hgl

################################################
##### Hashicorp tools
################################################

# Import Hashicorp's key
sudo rpm --import https://rpm.releases.hashicorp.com/gpg

# Add Hashicorp repository
sudo tee /etc/yum.repos.d/hashicorp.repo << 'EOF'
[hashicorp]
name=Hashicorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF

# Install Hashicorp tools
dnf check-update
sudo dnf -y install terraform nomad consul vault

# Install VScode extensions
code --install-extension HashiCorp.terraform
code --install-extension HashiCorp.HCL

################################################
##### waydroid
################################################

# References:
# https://docs.waydro.id/usage/waydroid-command-line-options#init-options
# https://wiki.archlinux.org/title/Waydroid

# Install waydroid
sudo dnf install -y waydroid

# Initialize waydroid
sudo waydroid init -c https://ota.waydro.id/system -v https://ota.waydro.id/vendor -s GAPPS

# Enable waydroid service
sudo systemctl enable waydroid-container.service

################################################
##### Font rendering
################################################

# Set antialiasing to subpixel
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'

# Set hinting to none
gsettings set org.gnome.desktop.interface font-hinting 'none'

# Add font configs
sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d/

# Rebuild font cache
sudo fc-cache -f
fc-cache -f

################################################
##### CoreCtrl
################################################

# References:
# https://gitlab.com/corectrl/corectrl/-/wikis/Setup

# Install corectrl
sudo dnf install -y corectrl

# Launch CoreCtrl on session startup
cp /usr/share/applications/org.corectrl.corectrl.desktop ${HOME}/.config/autostart/org.corectrl.corectrl.desktop

# Don't ask for user password
sudo tee /etc/polkit-1/rules.d/90-corectrl.rules << EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.corectrl.helper.init" ||
         action.id == "org.corectrl.helperkiller.init") &&
        subject.local == true &&
        subject.active == true &&
        subject.isInGroup("${USER}")) {
            return polkit.Result.YES;
    }
});
EOF

# Full AMD GPU controls
sudo grubby --update-kernel=ALL --args=amdgpu.ppfeaturemask=0xffffffff

################################################
##### .NET SDK
################################################

# References:
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-fedora#dependencies
# https://learn.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete
# https://learn.microsoft.com/en-us/dotnet/core/tools/telemetry#how-to-opt-out

# Install dependencies
sudo dnf install -y \
  krb5-libs \
  libicu \
  openssl-libs \
  zlib \
  libgdiplus

# Download install script
curl -sSL https://dot.net/v1/dotnet-install.sh -o ${HOME}/.local/bin/dotnet-install.sh
chmod +x ${HOME}/.local/bin/dotnet-install.sh

# Install latest .NET
dotnet-install.sh --channel STS

# Export dotnet to path
tee ${HOME}/.zshrc.d/dotnet << EOF
export DOTNET_CLI_TELEMETRY_OPTOUT=true
export DOTNET_ROOT=${HOME}/.dotnet
export PATH=\$PATH:${HOME}/.dotnet
EOF

# Enable tab autocomplete for the .NET CLI
tee -a ${HOME}/.zshrc.d/dotnet << 'EOF'

# bash parameter completion for the dotnet CLI
function _dotnet_bash_complete()
{
  local cur="${COMP_WORDS[COMP_CWORD]}" IFS=$'\n'
  local candidates

  read -d '' -ra candidates < <(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)

  read -d '' -ra COMPREPLY < <(compgen -W "${candidates[*]:-}" -- "$cur")
}

complete -f -F _dotnet_bash_complete dotnet
EOF

# .NET updater
tee ${HOME}/.local/bin/update-dotnet << 'EOF'
#!/usr/bin/bash

curl -sSL https://dot.net/v1/dotnet-install.sh -o ${HOME}/.local/bin/dotnet-install.sh
chmod +x ${HOME}/.local/bin/dotnet-install.sh
dotnet-install.sh --channel STS
EOF

chmod +x ${HOME}/.local/bin/update-dotnet

# Install VSCode extensions
code --install-extension ms-dotnettools.csharp

################################################
##### Unity Hub
################################################

# References:
# https://docs.unity3d.com/hub/manual/InstallHub.html#install-hub-linux
# https://www.reddit.com/r/Fedora/comments/wupxy7/how_to_install_correctly_unity_hub_on_fedora/

# Install dependencies
sudo dnf install -y \
    openssl \
    openssl-libs \
    GConf2 \
    openssl1.1

# Add Unity Hub repository
sudo tee /etc/yum.repos.d/unityhub.repo << EOF
[unityhub]
name=Unity Hub
baseurl=https://hub.unity3d.com/linux/repos/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://hub.unity3d.com/linux/repos/rpm/stable/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# Install Unity Hub
dnf check-update
sudo dnf install -y unityhub

# Install VSCode extensions
code --install-extension Unity.unity-debug

################################################
##### Android Studio
################################################

# References:
# https://developer.android.com/studio/install#linux
# https://github.com/flathub/com.google.AndroidStudio/blob/master/com.google.AndroidStudio.json
# https://developer.android.com/studio/releases/cmdline-tools
# https://developer.android.com/studio/releases/platform-tools
# https://plugins.jetbrains.com/plugin/19177-vscode-theme/versions
# https://developer.android.com/tools/variables#android_home

# Install dependencies
sudo dnf install -y \
  zlib.i686 \
  ncurses-libs.i686 \
  bzip2-libs.i686

# Download and install Android Studio
curl -sSL https://dl.google.com/dl/android/studio/ide-zips/2022.3.1.20/android-studio-2022.3.1.20-linux.tar.gz -O
sudo tar -xzf android-studio-*-linux.tar.gz -C /opt
rm -f android-studio-*-linux.tar.gz

# Create desktop entry
sudo tee /usr/share/applications/jetbrains-studio.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Icon=/opt/android-studio/bin/studio.svg
Exec="/opt/android-studio/bin/studio.sh" %f
Comment=The Drive to Develop
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-studio
StartupNotify=true
EOF

# Download and install VSCode Theme
curl -sSL https://plugins.jetbrains.com/files/19177/311822/VSCode_Theme-1.7.8-signed.zip -O
sudo unzip VSCode_Theme-*-signed.zip -d /opt/android-studio/plugins
rm -f VSCode_Theme-*-signed.zip

# Set environment
tee ${HOME}/.zshrc.d/android << EOF
export ANDROID_HOME=${HOME}/Android/Sdk
export ANDROID_USER_HOME=${HOME}/.android
export PATH=\$PATH:${HOME}/Android/Sdk/platform-tools
export PATH=\$PATH:${HOME}/Android/Sdk/emulator
EOF

################################################
##### Gnome - Remove unneeded packages and services
################################################

# Remove applications
sudo dnf remove -y \
    abrt \
    mediawriter

# GNOME - Remove packages
sudo dnf remove -y \
    gnome-software \
    gnome-weather \
    gnome-contacts \
    gnome-maps \
    gnome-photos \
    gnome-tour \
    gnome-connections \
    simple-scan \
    rhythmbox \
    cheese \
    totem \
    yelp

# PLASMA - Remove discover
sudo dnf remove -y \
    plasma-discover \
    plasma-discover-flatpak \
    plasma-discover-libs \
    plasma-discover-notifier \
    plasma-discover-offline-updates \
    plasma-discover-packagekit \
    fedora-appstream-metadata

################################################
##### Gnome VRR
################################################

# References:
# https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/

# Add gnome-vrr Copr
sudo dnf copr enable -y kylegospo/gnome-vrr

# Avoid upstream changes to mutter
sudo dnf config-manager --save --setopt="copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr.priority=1"

# Install Mutter VRR
sudo dnf update -y --refresh

sudo tee -a /etc/environment << 'EOF'

# Gnome VRR
MUTTER_DEBUG_FORCE_KMS_MODE=simple
EOF

################################################
##### npm
################################################

# Change npm's default directory
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
mkdir ${HOME}/.npm-global
npm config set prefix '~/.npm-global'
tee ${HOME}/.zshrc.d/npm << 'EOF'
export PATH=~/.npm-global/bin:$PATH
EOF

################################################
##### 
################################################
################################################
##### Lutris
################################################
################################################
##### 
################################################

################################################
##### Wine GE
################################################

# https://github.com/GloriousEggroll/wine-ge-custom

LATEST_WINE_GE_VERSION=$(curl -s https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LUTRIS_WINE_GE_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runners/wine"

# Create Lutris Wine GE folder
mkdir -p ${LUTRIS_WINE_GE_FOLDER}

# Download latest Wine GE version
curl https://github.com/GloriousEggroll/wine-ge-custom/releases/latest/download/wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz -L -O

# Extract Wine GE to Lutris folder
tar -xf wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz -C ${LUTRIS_WINE_GE_FOLDER}

# Remove downloaded Wine GE tar
rm -f wine-lutris-${LATEST_WINE_GE_VERSION}-x86_64.tar.xz

################################################
##### DXVK
################################################

# https://github.com/doitsujin/dxvk

LATEST_DXVK_VERSION=$(curl -s https://api.github.com/repos/doitsujin/dxvk/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
LUTRIS_DXVK_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/dxvk"

# Create Lutris DXVK folder
mkdir -p ${LUTRIS_DXVK_FOLDER}

# Download latest DXVK version
curl https://github.com/doitsujin/dxvk/releases/latest/download/dxvk-${LATEST_DXVK_VERSION}.tar.gz -L -O

# Extract DXVK to Lutris folder
tar -xzf dxvk-${LATEST_DXVK_VERSION}.tar.gz -C ${LUTRIS_DXVK_FOLDER}

# Rename DXVK folder
mv ${LUTRIS_DXVK_FOLDER}/dxvk-${LATEST_DXVK_VERSION} ${LUTRIS_DXVK_FOLDER}/v${LATEST_DXVK_VERSION}

# Remove downloaded DXVK tar
rm -f dxvk-${LATEST_DXVK_VERSION}.tar.gz

################################################
##### VKD3D
################################################

# https://github.com/HansKristian-Work/vkd3d-proton

LATEST_VKD3D_VERSION=$(curl -s https://api.github.com/repos/HansKristian-Work/vkd3d-proton/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//')
LUTRIS_VKD3D_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/vkd3d"

# Create Lutris VKD3D folder
mkdir -p ${LUTRIS_VKD3D_FOLDER}

# Download latest VKD3D version
curl https://github.com/HansKristian-Work/vkd3d-proton/releases/latest/download/vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -L -O

# Extract VKD3D to Lutris folder
tar -xf vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst -C ${LUTRIS_VKD3D_FOLDER}

# Rename VKD3D folder
mv ${LUTRIS_VKD3D_FOLDER}/vkd3d-proton-${LATEST_VKD3D_VERSION} ${LUTRIS_VKD3D_FOLDER}/v${LATEST_VKD3D_VERSION}

# Remove downloaded VKD3D tar
rm -f vkd3d-proton-${LATEST_VKD3D_VERSION}.tar.zst

################################################
##### Winetricks
################################################

# https://github.com/Winetricks/winetricks

LATEST_WINETRICKS_VERSION=$(curl -s https://api.github.com/repos/Winetricks/winetricks/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LUTRIS_WINETRICKS_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/winetricks"

# Create Lutris Winetricks folder
mkdir -p ${LUTRIS_WINETRICKS_FOLDER}

# Download latest Winetricks version
curl https://github.com/Winetricks/winetricks/archive/refs/tags/${LATEST_WINETRICKS_VERSION}.tar.gz -L -O

# Extract Winetricks to Lutris folder
tar -xzf ${LATEST_WINETRICKS_VERSION}.tar.gz -C ${LUTRIS_WINETRICKS_FOLDER} winetricks-${LATEST_WINETRICKS_VERSION}/src/winetricks --strip-components 2

# Remove downloaded Winetricks tar
rm -f ${LATEST_WINETRICKS_VERSION}.tar.gz

################################################
##### dgVoodoo2
################################################

# https://github.com/dege-diosg/dgVoodoo2

LATEST_DGVOODOO2_VERSION_DOTS=$(curl -s https://api.github.com/repos/dege-diosg/dgVoodoo2/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}')
LATEST_DGVOODOO2_VERSION=$(curl -s https://api.github.com/repos/dege-diosg/dgVoodoo2/releases/latest | awk -F\" '/tag_name/{print $(NF-1)}' | sed 's/^.//' | tr '.' '_')
LUTRIS_DGVOODOO2_FOLDER="${HOME}/.var/app/net.lutris.Lutris/data/lutris/runtime/dgvoodoo2"

# Create Lutris dgVoodoo2 folder
mkdir -p ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32

# Download latest dgVoodoo2 version
curl https://github.com/dege-diosg/dgVoodoo2/releases/latest/download/dgVoodoo${LATEST_DGVOODOO2_VERSION}.zip -L -O

# Extract dgVoodoo2 to Lutris folder
unzip -j dgVoodoo2_81_3.zip 3Dfx/x86/Glide* -d ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32
unzip -j dgVoodoo2_81_3.zip MS/x86/* -d ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/x32

# Create dgVoodoo2 config file
tee ${LUTRIS_DGVOODOO2_FOLDER}/${LATEST_DGVOODOO2_VERSION_DOTS}/dgVoodoo.conf << 'EOF'
[General]

OutputAPI                            = d3d11_fl11_0

[Glide]

3DfxWatermark                       = false
3DfxSplashScreen                    = false

[DirectX]

dgVoodooWatermark                   = false
EOF

# Remove downloaded dgVoodoo2 zip
rm -f dgVoodoo${LATEST_DGVOODOO2_VERSION}.zip

################################################
##### ALVR (native)
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/alvr_streamer_linux.tar.gz -L -O

# Extract ALVR
tar -xzf alvr_streamer_linux.tar.gz
mv alvr_streamer_linux /home/${USER}/.alvr

# Cleanup ALVR.tar.gz
rm -f alvr_streamer_linux.tar.gz

# Create ALVR shortcut
tee /home/${USER}/.local/share/applications/alvr.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ALVR
GenericName=Game
Comment=ALVR is an open source remote VR display which allows playing SteamVR games on a standalone headset such as Gear VR or Oculus Go/Quest.
Exec=/home/${USER}/.alvr/bin/alvr_dashboard
Icon=alvr
Categories=Game;
StartupNotify=true
PrefersNonDefaultGPU=true
X-KDE-RunOnDiscreteGpu=true
StartupWMClass=ALVR
EOF

# Allow ALVR in firewall
sudo firewall-cmd --zone=block --add-service=alvr
sudo firewall-cmd --zone=FedoraWorkstation --add-service=alvr

sudo firewall-cmd --permanent --zone=block --add-service=alvr
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=alvr

################################################
##### Remove unneeded packages and services (KDE Plasma)
################################################

# Remove media players
sudo dnf remove -y \
    dragon \
    elisa-player \
    kamoso

# Remove akonadi
sudo dnf remove -y *akonadi*

# Remove misc applications
sudo dnf remove -y \
    dnfdragora \
    qt5-qdbusviewer \
    konversation \
    krdc \
    krfb \
    kwrite \
    plasma-welcome \
    kmouth