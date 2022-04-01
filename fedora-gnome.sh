##### Versions
GOLANG_VERSION=1.18
NOMAD_VERSION=1.2.6
CONSUL_VERSION=1.11.4
VAULT_VERSION=1.10.0
TERRAFORM_VERSION=1.1.7
PACKER_VERSION=1.8.0

##### FOLDERS
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/.local/share/themes \
${HOME}/src

##### DNF
sudo tee -a /etc/dnf/dnf.conf << EOF
fastestmirror=true
max_parallel_downloads=10
EOF

##### FLATPAK
# Add Flathub and Flathub Beta repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install TOTP and password manager flatpaks
sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Install applications
sudo flatpak install -y flathub dev.alextren.Spot
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub com.github.tchx84.Flatseal

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
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
        "*.j2": "terraform",
        "*.hcl": "terraform",
        "*.bu": "yaml",
        "*.ign": "json"
        "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true
}
EOF

code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible
code --install-extension dbaeumer.vscode-eslint
code --install-extension editorconfig.editorconfig
code --install-extension octref.vetur

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

# Text editor
gsettings set org.gnome.TextEditor style-scheme 'classic'

# Set fonts
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 9'

##### GNOME EXTENSIONS
sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
