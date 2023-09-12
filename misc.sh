#!/usr/bin/bash

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
##### Virtualization
################################################

# References:
# https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-virtualization/
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_and_managing_virtualization/optimizing-virtual-machine-performance-in-rhel_configuring-and-managing-virtualization

# Install virtualization group
sudo dnf install -y @virtualization

# Enable service
sudo systemctl enable libvirtd

# Install QEMU
sudo dnf install -y qemu

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
##### Java / OpenJDK
################################################

# References:
# https://docs.fedoraproject.org/en-US/quick-docs/installing-java/

# Install OpenJDK
sudo dnf install -y \
  java-latest-openjdk \
  java-latest-openjdk-devel

# Set env vars
tee ${HOME}/.bashrc.d/java << EOF
export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
EOF

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
curl -sSL https://dl.google.com/dl/android/studio/ide-zips/2022.2.1.18/android-studio-2022.2.1.18-linux.tar.gz -O
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