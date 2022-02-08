##### Versions
GOLANG_VERSION=1.17.6
NOMAD_VERSION=1.2.5
CONSUL_VERSION=1.11.2
VAULT_VERSION=1.9.3
TERRAFORM_VERSION=1.1.4

##### FOLDERS
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/.local/share/themes \
${HOME}/.local/share/icons \
${HOME}/src

##### FLATPAK
# Add Flathub and Flathub Beta repos
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Allow Flatpaks to access themes and icons
flatpak override --filesystem=xdg-data/themes:ro
flatpak override --filesystem=xdg-data/icons:ro

# Install TOTP and password manager flatpaks
flatpak install -y flathub org.gnome.World.Secrets
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak override --unshare=network com.belmoussaoui.Authenticator

# Install applications
flatpak install -y flathub dev.alextren.Spot
flatpak install -y flathub com.usebottles.bottles
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub org.chromium.Chromium
flatpak install -y flathub-beta com.google.Chrome
flatpak install -y flathub org.libreoffice.LibreOffice

# flatpak install -y flathub com.valvesoftware.Steam
# flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton
# flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
# flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-Exp
# flatpak override --filesystem=/media/${USER}/data/games/steam com.valvesoftware.Steam

# Chrome - Enable GPU acceleration
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
EOF

# Chromium - Enable GPU acceleration
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
EOF

##### FIREFOX
# Install Firefox Flatpak
flatpak install -y flathub org.mozilla.firefox
flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Install Firefox theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme && cd firefox-gnome-theme
git checkout libadwaita
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
cd .. && rm -rf firefox-gnome-theme/

# Import Firefox user settings
cd ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
tee -a user.js << EOF
// Required by Firefox theme
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity", 0);
user_pref("svg.context-properties.content.enabled", true);
user_pref("ui.useOverlayScrollbars", 1);

// Enable hardware acceleration
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
EOF
cd

##### APPLICATIONS
# Common software
sudo dnf install -y git ninja-build meson sassc autoconf automake make

# Podman
sudo dnf install -y podman

tee -a ${HOME}/.bashrc.d/aliases << EOF
alias docker="podman"
EOF

# Syncthing
sudo dnf install -y syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Ansible
sudo dnf install -y ansible-core

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
    "editor.fontWeight": "500"
}
EOF

code --install-extension PKief.material-icon-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible

# Hashistack
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o hashistack-nomad.zip
curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o hashistack-consul.zip
curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o hashistack-vault.zip
curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o hashistack-terraform.zip
unzip 'hashistack-*.zip' -d  ${HOME}/.local/bin
rm hashistack-*.zip

# Golang
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -rf ${HOME}/.local/go
tar -C ${HOME}/.local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:${HOME}/.local/go/bin' ${HOME}/.bashrc.d/exports || echo 'export PATH=$PATH:${HOME}/.local/go/bin' >> ${HOME}/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Node.js 16
sudo dnf module install -y nodejs:16/default

##### THEMING
# adw-gtk3 theme (libadwaita ported to GTK3)
git clone https://github.com/lassekongo83/adw-gtk3.git
cd adw-gtk3
meson build
DESTDIR=${HOME}/.local/share/themes ninja -C build install
mv ${HOME}/.local/share/themes/usr/share/themes/* ${HOME}/.local/share/themes
rm -r ${HOME}/.local/share/themes/usr

gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3

# Gnome 42 icons
git clone --depth=1 https://gitlab.gnome.org/GNOME/adwaita-icon-theme.git
cd adwaita-icon-theme
./autogen.sh
make
sudo make install
cd .. && rm -rf adwaita-icon-theme

gsettings set org.gnome.desktop.interface icon-theme Adwaita

# Gnome Terminal
dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ default-size-columns 110

# Noto Fonts
sudo dnf install -y google-noto-sans-vf-fonts google-noto-serif-vf-fonts google-noto-sans-mono-vf-fonts \ 
google-noto-sans-arabic-vf-fonts google-noto-sans-cherokee-vf-fonts google-noto-sans-thaana-vf-fonts \
google-noto-sans-hebrew-vf-fonts google-noto-rashi-hebrew-vf-fonts google-noto-sans-math-vf-fonts \
google-noto-sans-armenian-vf-fonts google-noto-serif-armenian-vf-fonts google-noto-sans-canadian-aboriginal-vf-fonts \
google-noto-sans-georgian-vf-fonts google-noto-serif-georgian-vf-fonts google-noto-sans-lao-vf-fonts \
google-noto-serif-lao-vf-fonts google-noto-serif-gurmukhi-vf-fonts google-noto-serif-sinhala-vf-fonts \
google-noto-sans-ethiopic-vf-fonts google-noto-serif-ethiopic-vf-fonts

# Update font cache
fc-cache -v

# Set Noto Fonts
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 9'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

##### UI / UX CONFIGURATIONS
# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.preferences click-policy 'single'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

# Text editor
dconf write /org/gnome/gedit/preferences/ui/side-panel-visible true
dconf write /org/gnome/gedit/preferences/editor/wrap-mode "'none'"
dconf write /org/gnome/gedit/preferences/editor/highlight-current-line false

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

# Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

# Screenshots
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Super><Shift>s']"
