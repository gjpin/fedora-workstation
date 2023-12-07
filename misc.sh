#!/usr/bin/bash

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

# Create required folders
mkdir -p \
  ${HOME}/Android \
  ${HOME}/.android \
  ${HOME}/.m2 \
  ${HOME}/.java \
  ${HOME}/.gradle

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
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'grand-theft-focus@zalckos.github.com', 'gsconnect@andyholmes.github.io', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']"

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