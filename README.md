# Installation guide
1. Download setup script: `curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/setup.sh -O`
2. Make setup script executable: `chmod +x setup.sh`
3. Run setup.sh: `./setup.sh`
4. Reboot
5. Import WireGuard config to /etc/wireguard
6. Enable WireGuard connection: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
7. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-interface=wg0`

# Guides
## How to revert to a previous Flatpak commit
```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```

## How to use Gamescope + MangoHud in Steam
```bash
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -e -- %command%

# gamescope native resolution + MangoHud
gamescope -f -e -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -e -- mangohud %command%
```

## How to install .deb package (eg. Aseprite)
```bash
mkdir -p ${HOME}/aseprite
mv ${HOME}/Downloads/Aseprite*.deb ${HOME}/aseprite
ar -x ${HOME}/aseprite/Aseprite*.deb --output ${HOME}/aseprite
tar -xf ${HOME}/aseprite/data.tar.xz -C ${HOME}/aseprite
cp -r ${HOME}/aseprite/usr/bin/aseprite ${HOME}/.local/bin/
cp -r ${HOME}/aseprite/usr/share/* ${HOME}/.local/share/
rm -rf ${HOME}/aseprite
```

## Android Studio
```bash
################################################
##### Android Studio
################################################

# References:
# https://developer.android.com/studio/install#linux
# https://github.com/flathub/com.google.AndroidStudio/blob/master/com.google.AndroidStudio.json
# https://developer.android.com/studio/releases/cmdline-tools
# https://developer.android.com/studio/releases/platform-tools

# Install dependencies
sudo dnf install -y \
  zlib.i686 \
  ncurses-libs.i686 \
  bzip2-libs.i686

# Download and install Android Studio
curl -sSL https://dl.google.com/dl/android/studio/ide-zips/2021.3.1.17/android-studio-2021.3.1.17-linux.tar.gz -O
sudo tar -xzf android-studio-*-linux.tar.gz -C /opt
rm -f android-studio-*-linux.tar.gz

# Create desktop entry
tee ${HOME}/.local/share/applications/android-studio.desktop << EOF
[Desktop Entry]
Type=Application
Name=Android Studio
Exec="/opt/android-studio/bin/studio.sh" %f
Icon=/opt/android-studio/bin/studio.png
Categories=Development;IDE;
Terminal=false
StartupNotify=true
StartupWMClass=android-studio
EOF

chmod +x ${HOME}/.local/share/applications/android-studio.desktop

# Download and install Android CLI and platform tools
sudo mkdir -p /opt/android-sdk/cmdline-tools
curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip -O
sudo unzip commandlinetools-linux-*.zip -d /opt/android-sdk/cmdline-tools
rm -f commandlinetools-linux-*.zip
sudo mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest

curl -sSL  https://dl.google.com/android/repository/platform-tools-latest-linux.zip -O
sudo unzip platform-tools-latest-linux.zip -d /opt/android-sdk
rm -f platform-tools-latest-linux.zip

tee ${HOME}/.bashrc.d/android-sdk-platform-tools << EOF
export ANDROID_HOME=/opt/android-sdk/cmdline-tools/latest/bin
export PATH=\$PATH:/opt/android-sdk/cmdline-tools/latest/bin
export PATH=\$PATH:/opt/android-sdk/platform-tools
EOF

# Accept Android SDK licenses
yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

## .NET SDK
```bash
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
```

## Unity
```bash
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
```

## Java
```bash
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
```

## CoreCtrl
```bash
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
```

## Virtualization
```bash
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
```

## WayDroid
```bash
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
```