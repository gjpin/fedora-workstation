#!/usr/bin/bash

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

# Configure VSCode
mkdir -p ${HOME}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.config/Code/User/settings.json

# Change VSCode config to use theme
sed -i '2 i \ \ \ \ "workbench.preferredDarkColorTheme": "Adwaita Dark",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.preferredLightColorTheme": "Adwaita Light",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' ${HOME}/.config/Code/User/settings.json

################################################
##### Development
################################################

# References:
# https://developer.fedoraproject.org/tech/languages/python/python-installation.html
# https://developer.fedoraproject.org/tech/languages/rust/rust-installation.html
# https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

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

# Install cfssl
sudo dnf install -y golang-github-cloudflare-cfssl

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
##### Deno
################################################

# Install deno
mkdir -p ${HOME}/.deno/bin
curl https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -L -O
unzip -o deno-x86_64-unknown-linux-gnu.zip -d ${HOME}/.deno/bin
rm -f deno-x86_64-unknown-linux-gnu.zip

# Add Deno to path
tee ${HOME}/.bashrc.d/deno << 'EOF'
export DENO_INSTALL=${HOME}/.deno
export PATH="$PATH:$DENO_INSTALL/bin"
EOF
  
# Add Deno updater to bash updater function
sed -i '2 i \ ' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ deno upgrade' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ # Update Deno' ${HOME}/.bashrc.d/update-all

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
flatpak install -y flathub app/org.winehq.Wine/x86_64/stable-22.08
flatpak install -y flathub runtime/org.winehq.Wine.gecko/x86_64/stable-22.08
flatpak install -y flathub runtime/org.winehq.Wine.mono/x86_64/stable-22.08

# Deny Wine internet access
flatpak override --user --unshare=network org.winehq.Wine

# Prevent installing Mono/Gecko
flatpak override --user --env='WINEDLLOVERRIDES=mscoree=d;mshtml=d' org.winehq.Wine

# Set wine alias
tee ${HOME}/.bashrc.d/wine << 'EOF'
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
flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git//22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git//22.08

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
tee ${HOME}/.bashrc.d/dotnet << EOF
export DOTNET_CLI_TELEMETRY_OPTOUT=true
export DOTNET_ROOT=${HOME}/.dotnet
export PATH=\$PATH:${HOME}/.dotnet
EOF

# Enable tab autocomplete for the .NET CLI
tee -a ${HOME}/.bashrc.d/dotnet << 'EOF'

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
tee ${HOME}/.bashrc.d/android << EOF
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