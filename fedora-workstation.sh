#!/usr/bin/env bash

################################################
##### General
################################################

sudo tee -a /etc/dnf/dnf.conf << EOF
max_parallel_downloads=10
EOF

sudo dnf upgrade -y --refresh

# Create user folders
mkdir -p \
    ${HOME}/.bashrc.d \
    ${HOME}/.local/bin \
    ${HOME}/.themes \
    ${HOME}/.local/share/gnome-shell/extensions \
    ${HOME}/.config/systemd/user \
    ${HOME}/src

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
update-all() {
  # Update system
  sudo dnf clean all
  sudo dnf upgrade -y --refresh

  # Update Flatpak apps
  flatpak update -y

  # Update Firefox theme
  update-firefox-theme

  # Update GTK theme
  update-gtk-theme

  # Update tailscale
  update-tailscale

  # Update global npm packages
  npm update -g
}
EOF

################################################
##### Firewalld
################################################

# Set default firewall zone
sudo firewall-cmd --set-default-zone=block

# Overlay firewalld GUI
sudo dnf install -y firewall-config

################################################
##### SELinux
################################################

# Create aliases
tee ${HOME}/.bashrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
EOF

################################################
##### Tools
################################################

# Install ansible
sudo dnf install -y ansible

# Install go
sudo dnf install -y golang

tee ${HOME}/.bashrc.d/golang << 'EOF'
# paths
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Install nodejs
sudo dnf install -y nodejs npm

mkdir -p ${HOME}/.npm-global

npm config set prefix '~/.npm-global'

tee ${HOME}/.bashrc.d/nodejs << 'EOF'
export PATH="$HOME/.npm-global/bin:$PATH"
EOF

npm install -g typescript typescript-language-server pyright

################################################
##### Flathub
################################################

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable
sudo flatpak update --appstream

################################################
##### Firefox
################################################

# Remove Firefox RPM
sudo dnf remove -y firefox

# Install Firefox from Flathub
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/21.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08

# Set Firefox Flatpak as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# Temporarily open Firefox to create profiles
timeout 5 flatpak run org.mozilla.firefox --headless

# Install Firefox Gnome theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme
cd firefox-gnome-theme
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
cd .. && rm -rf firefox-gnome-theme/

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/env bash

git clone https://github.com/rafaelmardojai/firefox-gnome-theme
cd firefox-gnome-theme
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
cd .. && rm -rf firefox-gnome-theme/
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

# Enable wayland
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Install Intel VA-API drivers if applicable
if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/21.08
fi

################################################
##### Applications
################################################

# Install common applications
sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub net.cozic.joplin_desktop
sudo flatpak install -y flathub rest.insomnia.Insomnia
sudo flatpak install -y flathub org.gimp.GIMP
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak install -y flathub org.gnome.Builder
sudo flatpak install -y flathub com.usebottles.bottles && \
    sudo flatpak override com.usebottles.bottles --filesystem=xdg-data/applications

# Improve QT applications theming in GTK
sudo flatpak install -y flathub org.kde.KStyle.Adwaita/x86_64/5.15-21.08
sudo flatpak install -y flathub org.kde.KStyle.Adwaita/x86_64/5.15-22.08

sudo flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-21.08
sudo flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-22.08

sudo flatpak install -y flathub org.kde.PlatformTheme.QtSNI/x86_64/5.15-21.08

sudo flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15-21.08
sudo flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15-22.08

################################################
##### Visual Studio Code
################################################

# Install VSCode
sudo flatpak install -y flathub com.visualstudio.code

# Add bash alias
tee ${HOME}/.bashrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

# Install extensions
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension HashiCorp.terraform
flatpak run com.visualstudio.code --install-extension redhat.ansible
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint

# Configure VSCode
mkdir -p ${HOME}/.var/app/com.visualstudio.code/config/Code/User
tee ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
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
    "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",
    "editor.formatOnSave": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "terminal.integrated.defaultProfile.linux": "bash",
    "terminal.integrated.profiles.linux": {
      "bash": {
        "path": "/usr/bin/flatpak-spawn",
        "args": ["--host", "--env=TERM=xterm-256color", "bash"]
      }
    }
}
EOF

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/env bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
rm -rf ${HOME}/.themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.themes/
rm -f adw-*.tar.xz
EOF

chmod +x ${HOME}/.local/bin/update-gtk-theme

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'

################################################
##### Shortcuts
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

# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

# Laptop specific
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

# Configure bash prompt
tee ${HOME}/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

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

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
sudo dnf install -y xprop

curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v8.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v42.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

################################################
##### Tailscale
################################################

# References:
# https://tailscale.com/blog/steam-deck/

# Install Tailscale
TAILSCALE_LATEST_VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | awk -F\" '/"name"/{print $(NF-1)}')
curl -sSL https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_LATEST_VERSION}_amd64.tgz -O
sudo tar -xf tailscale_*.tgz --strip-components 1 -C /usr/local/bin/ --wildcards tailscale_*/tailscale
sudo tar -xf tailscale_*.tgz --strip-components 1 -C /usr/local/bin/ --wildcards tailscale_*/tailscaled
rm -f tailscale_*.tgz

# Fix SELinux labels
sudo chcon -t bin_t /usr/local/bin/tailscale
sudo chcon -t bin_t /usr/local/bin/tailscaled

# Create systemd service
sudo tee /etc/systemd/system/tailscaled.service << EOF
[Unit]
Description=Tailscale node agent
Documentation=https://tailscale.com/kb/
Wants=network-pre.target
After=network-pre.target NetworkManager.service systemd-resolved.service

[Service]
ExecStartPre=/usr/local/bin/tailscaled --cleanup
ExecStart=/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port 41641
ExecStopPost=/usr/local/bin/tailscaled --cleanup

Restart=on-failure

RuntimeDirectory=tailscale
RuntimeDirectoryMode=0755
StateDirectory=tailscale
StateDirectoryMode=0700
CacheDirectory=tailscale
CacheDirectoryMode=0750
Type=notify

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

# Create tailscaled aliases
tee ${HOME}/.bashrc.d/tailscale << EOF
alias start-tailscaled="sudo systemctl start tailscaled.service"

alias stop-tailscaled="sudo systemctl stop tailscaled.service"
EOF

# Tailscale updater
tee ${HOME}/.local/bin/update-tailscale << 'EOF'
#!/usr/bin/env bash

TAILSCALE_LATEST_VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | awk -F\" '/"name"/{print $(NF-1)}')
TAILSCALE_INSTALLED_VERSION=$(tailscale --version | head -n 1)

if [ "$TAILSCALE_LATEST_VERSION" != "$TAILSCALE_INSTALLED_VERSION" ]; then
    sudo rm -f /usr/local/bin/{tailscale,tailscaled}
    curl -sSL https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_LATEST_VERSION}_amd64.tgz -O
    sudo tar -xf tailscale_*.tgz --strip-components 1 -C /usr/local/bin/ --wildcards tailscale_*/tailscale
    sudo tar -xf tailscale_*.tgz --strip-components 1 -C /usr/local/bin/ --wildcards tailscale_*/tailscaled
    rm -f tailscale_*.tgz
    sudo chcon -t bin_t /usr/local/bin/tailscale
    sudo chcon -t bin_t /usr/local/bin/tailscaled
fi
EOF

chmod +x ${HOME}/.local/bin/update-tailscale

################################################
##### Syncthing
################################################

# References:
# https://github.com/syncthing/syncthing/blob/main/README-Docker.md
# https://docs.syncthing.net/users/firewall.html

# Create volume folder
mkdir -p ${HOME}/containers/syncthing

# Create systemd user service
tee ${HOME}/.config/systemd/user/syncthing.service << EOF
[Unit]
Description=syncthing container
After=firewalld.service

[Service]
ExecStartPre=-/usr/bin/podman kill syncthing
ExecStartPre=-/usr/bin/podman rm syncthing
ExecStartPre=/usr/bin/podman pull docker.io/syncthing/syncthing:latest
ExecStart=/usr/bin/podman run \
    --name=syncthing \
    --hostname=${HOSTNAME} \
    --userns=keep-id \
    -p 8384:8384/tcp \
    -p 22000:22000/tcp \
    -p 22000:22000/udp \
    -p 21027:21027/udp \
    -v ${HOME}/containers/syncthing:/var/syncthing:Z \
    docker.io/syncthing/syncthing:latest
ExecStop=/usr/bin/podman stop syncthing
ExecStopPost=/usr/bin/podman rm syncthing
Restart=always

[Install]
WantedBy=default.target
EOF

# Enable systemd user service
systemctl --user daemon-reload
systemctl --user enable syncthing.service

# Open firewall ports
sudo firewall-cmd --permanent --zone=home --add-port=21027/udp # For discovery broadcasts on IPv4 and multicasts on IPv6
sudo firewall-cmd --permanent --zone=home --add-port=22000/tcp # TCP based sync protocol traffic
sudo firewall-cmd --permanent --zone=home --add-port=22000/udp # QUIC based sync protocol traffic
sudo firewall-cmd --reload