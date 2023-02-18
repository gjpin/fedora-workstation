#!/bin/bash

################################################
##### Set variables
################################################

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Gaming (yes / no): " GAMING
export GAMING

################################################
##### Remove unneeded packages and services
################################################

# Remove packages
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
    mediawriter \
    yelp \
    abrt

# Mask services
sudo systemctl mask \
  ModemManager.service \
  pcscd.service

################################################
##### General
################################################

# Set hostname
sudo hostnamectl set-hostname --pretty "${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --static "${NEW_HOSTNAME}"

# Configure DNF
sudo tee -a /etc/dnf/dnf.conf << EOF
max_parallel_downloads=10
EOF

# Update system
sudo dnf upgrade -y --refresh

# Install common packages
sudo dnf install -y \
  bind-utils \
  kernel-tools \
  unzip \
  htop

# Create common user directories
mkdir -p \
  ${HOME}/.local/share/applications \
  ${HOME}/.bashrc.d \
  ${HOME}/.local/bin \
  ${HOME}/.config/autostart

################################################
##### Mounts
################################################

# Enable additional BTRFS options
if grep -E 'noatime|space_cache|discard' /etc/fstab; then
  echo "Possible conflict. No changes have been made."
else
  sudo sed -i "s|compress=zstd:1|&,noatime,space_cache=v2,discard=async|" /etc/fstab
  sudo systemctl daemon-reload
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
  sudo dnf clean all
  sudo dnf upgrade -y --refresh

  # Update firmware
  sudo fwupdmgr refresh
  sudo fwupdmgr update

  # Update Flatpak apps
  flatpak update -y

  # Update Firefox theme
  update-firefox-theme

  # Update GTK theme
  update-gtk-theme
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
##### RPM Fusion
################################################

# References:
# https://rpmfusion.org/Configuration/
# https://rpmfusion.org/Howto/Multimedia
# https://copr-dist-git.fedorainfracloud.org/cgit/gloriouseggroll/nobara/nobara-login.git/tree/codeccheck.sh?h=f37

# Enable free and nonfree repositories
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install Appstream metadata
sudo dnf groupupdate -y core

# Install additional codecs
sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate -y sound-and-video

# Install Intel hardware accelerated codecs
if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo dnf install -y intel-media-driver
fi

# Install AMD hardware accelerated codecs
if lspci | grep VGA | grep "AMD" > /dev/null; then
  sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
  sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
fi

# Install chromium with non-free multimedia formats support
sudo dnf install -y chromium-freeworld

# Install additional codecs
sudo dnf install -y x264 x265 gpac-libs libheif libftl live555 pipewire-codec-aptx libmediainfo mediainfo compat-ffmpeg4

# Install Microsoft fonts
sudo dnf install -y lpf-cleartype-fonts lpf-mscore-fonts

# Install Steam devices
sudo dnf install -y steam-devices

################################################
##### Flatpak / Flathub
################################################

# Add Flathub repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable

sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak remote-modify flathub-beta --enable

# Global override to deny all applications the permission to access certain directories
flatpak override --nofilesystem='home' --nofilesystem='host' --nofilesystem='xdg-cache' --nofilesystem='xdg-config' --nofilesystem='xdg-data'

################################################
##### Flatpak runtimes
################################################

# Install Flatpak runtimes
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08
if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
fi

################################################
##### Flatpak applications
################################################

# Install common applications
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak install -y flathub com.github.tchx84.Flatseal

sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub io.github.celluloid_player.Celluloid
sudo flatpak install -y flathub io.github.seadve.Kooha

sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub com.github.flxzt.rnote

sudo flatpak install -y flathub org.gnome.gitg

# Bitwarden
sudo flatpak install -y flathub com.bitwarden.desktop
sudo flatpak override --socket=wayland com.bitwarden.desktop
cp /var/lib/flatpak/app/com.bitwarden.desktop/current/active/files/share/applications/com.bitwarden.desktop.desktop ${HOME}/.local/share/applications
sed -i "s|Exec=bitwarden|Exec=flatpak run com.bitwarden.desktop --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland|g" ${HOME}/.local/share/applications/com.bitwarden.desktop.desktop

# Insomnia
sudo flatpak install -y flathub rest.insomnia.Insomnia
sudo flatpak override --env=GTK_THEME=adw-gtk3-dark rest.insomnia.Insomnia
sudo flatpak override --socket=wayland rest.insomnia.Insomnia
cp /var/lib/flatpak/app/rest.insomnia.Insomnia/current/active/files/share/applications/rest.insomnia.Insomnia.desktop ${HOME}/.local/share/applications
sed -i "s|Exec=/app/bin/insomnia|Exec=flatpak run rest.insomnia.Insomnia --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland|g" ${HOME}/.local/share/applications/rest.insomnia.Insomnia.desktop

# GIMP beta (has native wayland support)
sudo flatpak install -y flathub-beta org.gimp.GIMP

# Blender
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak override --socket=wayland org.blender.Blender

# Bottles
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak override --filesystem=xdg-data/applications com.usebottles.bottles

# Obsidian
sudo flatpak install -y flathub md.obsidian.Obsidian
sudo flatpak override --env=OBSIDIAN_USE_WAYLAND=1 md.obsidian.Obsidian
sudo flatpak override --env=GTK_THEME=adw-gtk3-dark md.obsidian.Obsidian

################################################
##### Firefox
################################################

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.mozilla/firefox/*.default-release)

# Import Firefox configs
curl -Ssl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/firefox.js \
  -o ${FIREFOX_PROFILE_PATH}/user.js

# Install Firefox Gnome theme
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo "@import \"firefox-gnome-theme/userChrome.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo "@import \"firefox-gnome-theme/userContent.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF
// Enable customChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Set UI density to normal
user_pref("browser.uidensity", 0);

// Enable SVG context-propertes
user_pref("svg.context-properties.content.enabled", true);

// Disable private window dark theme
user_pref("browser.theme.dark-private-windows", false);

// Add more contrast to the active tab
user_pref("gnomeTheme.activeTabContrast", true);
EOF

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/bash

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.mozilla/firefox/*.default-release)
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

################################################
##### VSCode
################################################

# References:
# https://code.visualstudio.com/docs/setup/linux#_rhel-fedora-and-centos-based-distributions

# Import Microsoft key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Add VSCode repository
sudo tee /etc/yum.repos.d/vscode.repo << EOF
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
code --install-extension piousdeer.adwaita-theme

# Configure VSCode
mkdir -p ${HOME}/.config/Code/User
tee ${HOME}/.config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "editor.fontLigatures": true,
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "workbench.preferredDarkColorTheme": "Adwaita Dark",
    "workbench.preferredLightColorTheme": "Adwaita Light",
    "editor.fontWeight": "500",
    "files.associations": {
      "*.j2": "terraform",
      "*.hcl": "terraform",
      "*.bu": "yaml",
      "*.ign": "json",
      "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true,
    "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",
    "editor.formatOnSave": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
}
EOF

################################################
##### Podman
################################################

# Install Pods (podman frontend)
sudo flatpak install -y flathub com.github.marhkb.Pods

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf << EOF
# Enable docker.io as unqualified search registry
unqualified-search-registries = ["docker.io"]
EOF

################################################
##### Syncthing
################################################

# Install syncthing
sudo dnf install -y syncthing

# Enable syncthing service
systemctl --user enable syncthing.service

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
rm -rf ${HOME}/.local/share/themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz
EOF

chmod +x ${HOME}/.local/bin/update-gtk-theme

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'

################################################
##### Gnome shortcuts
################################################

# Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'

# Windows management
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

# Screenshots
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"

# Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>E'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Shift><Control>Escape'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-system-monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'gnome-system-monitor'

# Change alt+tab behaviour
gsettings set org.gnome.desktop.wm.keybindings switch-applications "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

# Switch to workspace
gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"

# Move window to workspace
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>exclam']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>at']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>numbersign']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>dollar']"

################################################
##### UI / UX changes
################################################

# Set dash applications
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'code.desktop']"

# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'

# Laptop specific
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

# Configure terminal color scheme
dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ default-size-columns 110
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ palette "['rgb(46,52,54)', 'rgb(204,0,0)', 'rgb(34,209,139)', 'rgb(196,160,0)', 'rgb(51,142,250)', 'rgb(117,80,123)', 'rgb(6,152,154)', 'rgb(211,215,207)', 'rgb(85,87,83)', 'rgb(239,41,41)', 'rgb(138,226,52)', 'rgb(252,233,79)', 'rgb(114,159,207)', 'rgb(173,127,168)', 'rgb(52,226,226)', 'rgb(238,238,236)']"

# Set fonts
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

################################################
##### Gnome Shell Extensions
################################################

# Create Gnome shell extensions folder
mkdir -p ${HOME}/.local/share/gnome-shell/extensions

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v46.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v54.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
sudo dnf install -y xprop

curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v8.shell-extension.zip -O
gnome-extensions install dark-varianthardpixel.eu.v8.shell-extension.zip
rm -f *.shell-extension.zip

gsettings set org.gnome.shell.extensions.dark-variant applications "['code.desktop', 'com.visualstudio.code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.spotify.Client.desktop', 'md.obsidian.Obsidian.desktop', 'org.gimp.GIMP.desktop', 'org.blender.Blender.desktop', 'org.godotengine.Godot.desktop', 'com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop']"

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v10.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'gsconnect@andyholmes.github.io', 'rounded-window-corners@yilozt']"

################################################
##### Unlock LUKS2 with TPM2 token
################################################

# Install tpm2-tools
sudo dnf install -y tpm2-tools

# Update crypttab
sudo sed -ie '/^luks-/s/$/ tpm2-device=auto/' /etc/crypttab

# Regenerate initramfs
sudo dracut -f

# Enroll TPM2 token into LUKS2
sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 /dev/nvme0n1p3

################################################
##### Cleanup
################################################

APPLICATIONS=('htop')
for APPLICATION in "${APPLICATIONS[@]}"
do
    # Create a local copy of the desktop files and append properties
    cp /usr/share/applications/${APPLICATION}.desktop ${HOME}/.local/share/applications/${APPLICATION}.desktop 2>/dev/null || : 

    if test -f "${HOME}/.local/share/applications/${APPLICATION}.desktop"; then
        echo "NoDisplay=true" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
        echo "Hidden=true" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
        echo "NotShowIn=KDE;GNOME;" >> ${HOME}/.local/share/applications/${APPLICATION}.desktop
    fi
done

################################################
##### Gaming
################################################

# Install and configure gaming with Flatpak
if [ ${GAMING} = "yes" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/setup_gaming.sh -O
    chmod +x setup_gaming.sh
    ./setup_gaming.sh
    rm setup_gaming.sh
fi