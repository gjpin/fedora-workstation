##### Versions
GOLANG_VERSION=1.18.1
NOMAD_VERSION=1.2.6
CONSUL_VERSION=1.12.0
VAULT_VERSION=1.10.2
TERRAFORM_VERSION=1.1.9
PACKER_VERSION=1.8.0

##### FOLDERS
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/.local/share/themes \
${HOME}/src

##### DNF
sudo tee -a /etc/dnf/dnf.conf << EOF
max_parallel_downloads=10
EOF

# RPM Fusion and ffmpeg
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf groupupdate -y core

sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# Enable VA-API
sudo dnf install -y libva libva-utils

if [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "GenuineIntel" ]]
then
  sudo dnf install -y intel-media-driver
fi

##### FONTS
# Install JetBrains Font
mkdir -p ~/.local/share/fonts/JetBrainsMono

curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip -o JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
rm JetBrainsMono.zip

fc-cache -v

##### FLATPAK
# Add Flathub and Flathub Beta repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak remote-modify flathub --enable
flatpak update --appstream

# Install TOTP and password manager flatpaks
sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Install applications
sudo flatpak install -y flathub dev.alextren.Spot
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub com.rafaelmardojai.Blanket
sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub de.haeckerfelix.Shortwave
sudo flatpak install -y flathub net.cozic.joplin_desktop

# Install Chrome and enable GPU acceleration
sudo flatpak install -y flathub-beta com.google.Chrome
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--ozone-platform-hint=auto
--enable-webrtc-pipewire-capturer
EOF

# Install Chromium and enable GPU acceleration
sudo flatpak install -y flathub org.chromium.Chromium
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--ozone-platform-hint=auto
--enable-webrtc-pipewire-capturer
EOF

##### APPLICATIONS
# Common software
sudo dnf install -y ninja-build meson sassc autoconf automake make jq htop

# Git
sudo dnf install -y git-core
git config --global init.defaultBranch main

# Podman
sudo dnf install -y podman
tee -a ${HOME}/.bashrc.d/aliases << EOF
alias docker="podman"
EOF

# SELinux tools and udica
sudo dnf install -y setools-console udica

# Ansible
sudo dnf install -y ansible

# Syncthing
sudo dnf install -y syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
sudo dnf install -y code

mkdir -p ${HOME}/.config/Code/User
tee -a ${HOME}/.config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'JetBrainsMono Nerd Font Mono','Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "workbench.preferredDarkColorTheme": "Adwaita Dark",
    "workbench.preferredLightColorTheme": "Adwaita Light",
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
        "*.j2": "terraform",
        "*.hcl": "terraform",
        "*.bu": "yaml",
        "*.ign": "json",
        "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true,
    "workbench.colorTheme": "Adwaita Dark & default syntax highlighting"
}
EOF

code --install-extension piousdeer.adwaita-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
#code --install-extension redhat.ansible
#code --install-extension dbaeumer.vscode-eslint
#code --install-extension editorconfig.editorconfig
#code --install-extension octref.vetur

# Hashistack
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o hashistack-nomad.zip
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o hashistack-consul.zip
curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o hashistack-vault.zip
curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o hashistack-terraform.zip
curl -sSL https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip -o hashistack-packer.zip
unzip 'hashistack-*.zip' -d  ${HOME}/.local/bin
rm hashistack-*.zip

# Install hey
curl -sSL https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o ${HOME}/.local/bin/hey
chmod +x ${HOME}/.local/bin/hey

# Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -rf ${HOME}/.local/go
tar -C ${HOME}/.local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:${HOME}/.local/go/bin' ${HOME}/.bashrc.d/exports || echo 'export PATH=$PATH:${HOME}/.local/go/bin' >> ${HOME}/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Node.js 16
sudo dnf module install -y nodejs:16

##### FIREFOX
# Uninstall Firefox RPM
sudo dnf remove -y firefox

# Install Firefox Flatpak
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Install Firefox theme
#git clone https://github.com/rafaelmardojai/firefox-gnome-theme && cd firefox-gnome-theme
#git checkout libadwaita
#./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
#cd .. && rm -rf firefox-gnome-theme/

# Import Firefox user settings
cd ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
rm user.js
tee -a user.js << EOF
// Enable hardware acceleration
user_pref("media.ffmpeg.vaapi.enabled", true);
EOF
cd

##### THEMING
# adw-gtk3 theme (libadwaita ported to GTK3)
git clone https://github.com/lassekongo83/adw-gtk3.git
cd adw-gtk3
meson -Dprefix="${HOME}/.local" build
ninja -C build install
cd .. && rm -rf adw-gtk3

gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3

sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Customize bash
tee ~/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Terminal
dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ default-size-columns 110
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ palette "['rgb(46,52,54)', 'rgb(204,0,0)', 'rgb(34,209,139)', 'rgb(196,160,0)', 'rgb(51,142,250)', 'rgb(117,80,123)', 'rgb(6,152,154)', 'rgb(211,215,207)', 'rgb(85,87,83)', 'rgb(239,41,41)', 'rgb(138,226,52)', 'rgb(252,233,79)', 'rgb(114,159,207)', 'rgb(173,127,168)', 'rgb(52,226,226)', 'rgb(238,238,236)']"

##### UI / UX CONFIGURATIONS
# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
# gsettings set org.gnome.nautilus.preferences click-policy 'single'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

# Laptop specific
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

##### SHORTCUTS
# Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab '<Primary><Shift>w'

# Window management
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

# Screenshots
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"

# Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

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

# Text editor
gsettings set org.gnome.TextEditor style-scheme 'classic'

# Set fonts
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 9'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 10'

##### GNOME EXTENSIONS
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager

##### GNOME SOFTWARE
# Prevent Gnome Software from autostarting
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/org.gnome.Software.desktop ~/.config/autostart/
echo "X-GNOME-Autostart-enabled=false" >> ~/.config/autostart/org.gnome.Software.desktop
dconf write /org/gnome/desktop/search-providers/disabled "['org.gnome.Software.desktop']"

# Disable PackageKit
#sudo systemctl mask packagekit.service
