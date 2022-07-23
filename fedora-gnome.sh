sudo tee -a /etc/dnf/dnf.conf << EOF
max_parallel_downloads=10
EOF

sudo dnf update -y --refresh

##### FOLDERS
mkdir -p \
${HOME}/.bashrc.d/ \
${HOME}/.local/bin \
${HOME}/.local/share/themes \
${HOME}/src

# RPM Fusion and multimedia packages
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf groupupdate -y core

sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

sudo dnf groupupdate -y sound-and-video

# Enable VA-API
sudo dnf install -y libva libva-utils

if cat /proc/cpuinfo | grep vendor | grep "GenuineIntel" > /dev/null; then
  sudo dnf install -y intel-media-driver
fi

# Install firewalld GUI and set default zone to 'block'
sudo dnf install -y firewall-config
sudo firewall-cmd --set-default-zone=block

##### FONTS
# Install JetBrains Font
mkdir -p ~/.local/share/fonts/JetBrainsMono

curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip -o JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
rm JetBrainsMono.zip

fc-cache -v

##### FLATPAK
# Add Flathub repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable
flatpak update --appstream

# Install TOTP and password manager flatpaks
sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Install applications
sudo flatpak install -y flathub dev.alextren.Spot
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub com.rafaelmardojai.Blanket
sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub de.haeckerfelix.Shortwave
sudo flatpak install -y flathub net.cozic.joplin_desktop
sudo flatpak install -y flathub rest.insomnia.Insomnia

sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak override com.usebottles.bottles --filesystem=xdg-data/applications

# Install Chrome and enable GPU acceleration
sudo flatpak install -y flathub com.google.Chrome
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
sudo dnf install -y ninja-build meson sassc autoconf automake make jq htop lm_sensors kernel-tools

# Git
sudo dnf install -y git
git config --global init.defaultBranch main

# Podman
sudo dnf install -y podman

tee -a ${HOME}/.bashrc.d/alias << EOF
alias docker="podman"
EOF

# SELinux tools and udica
sudo dnf install -y setools-console udica

tee -a ${HOME}/.bashrc.d/alias << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
alias seinspect="sudo sealert -l"
EOF

# Ansible
sudo dnf install -y ansible

# Syncthing
sudo dnf install -y syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sudo dnf check-update

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
    "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",
    "editor.formatOnSave": true
}
EOF

code --install-extension piousdeer.adwaita-theme
code --install-extension golang.Go
code --install-extension HashiCorp.terraform
code --install-extension redhat.ansible
code --install-extension dbaeumer.vscode-eslint

# Tailscale
sudo rpm --import https://pkgs.tailscale.com/stable/fedora/repo.gpg

sudo tee /etc/yum.repos.d/tailscale.repo << 'EOF'
[tailscale-stable]
name=Tailscale stable
baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
enabled=1
type=rpm
repo_gpgcheck=1
gpgcheck=0
gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF

sudo dnf check-update

sudo dnf install -y tailscale

# Hashistack
sudo rpm --import https://rpm.releases.hashicorp.com/gpg

sudo tee /etc/yum.repos.d/hashicorp.repo << 'EOF'
[hashicorp]
name=Hashicorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF

sudo dnf check-update

sudo dnf -y install nomad consul vault packer terraform terraform-ls

# k6.io
sudo rpm --import https://dl.k6.io/key.gpg

sudo tee /etc/yum.repos.d/k6-io.repo << 'EOF'
[k6]
name=k6
baseurl=https://dl.k6.io/rpm/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.k6.io/key.gpg
EOF

sudo dnf check-update

sudo dnf -y install k6

###### golang
# install golang
sudo dnf install -y golang

# set paths
tee -a ${HOME}/.bashrc.d/env << 'EOF'
export GOPATH="$HOME/.go"
EOF

tee -a ${HOME}/.bashrc.d/path << 'EOF'
export PATH="$GOPATH/bin:$PATH"
EOF

source ${HOME}/.bashrc.d/env
source ${HOME}/.bashrc.d/path

##### Node.js
# Install NVM
export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
) && \. "$NVM_DIR/nvm.sh"

# Add NVM updater
tee ${HOME}/.local/bin/update-nvm << 'EOF'
(
  cd "$NVM_DIR"
  git fetch --tags origin
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
) && \. "$NVM_DIR/nvm.sh"
EOF

chmod +x ${HOME}/.local/bin/update-nvm

# Set default global packages
tee ${NVM_DIR}/default-packages << EOF
typescript
typescript-language-server
pyright
neovim
EOF

# Source NVM
tee ${HOME}/.bashrc.d/nvm << 'EOF'
# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

source ${HOME}/.bashrc.d/nvm

# install nodejs 18
nvm install 18

# Update npm
nvm install-latest-npm

# Source NVM and automatically call nvm use based on nvmrc
tee -a ${HOME}/.bashrc.d/nvm << 'EOF'

# Automatically call nvm use
cdnvm() {
    command cd "$@";
    nvm_path=$(nvm_find_up .nvmrc | tr -d '\n')

    # If there are no .nvmrc file, use the default nvm version
    if [[ ! $nvm_path = *[^[:space:]]* ]]; then

        declare default_version;
        default_version=$(nvm version default);

        # If there is no default version, set it to `node`
        # This will use the latest version on your machine
        if [[ $default_version == "N/A" ]]; then
            nvm alias default node;
            default_version=$(nvm version default);
        fi

        # If the current version is not the default version, set it to use the default version
        if [[ $(nvm current) != "$default_version" ]]; then
            nvm use default;
        fi

    elif [[ -s $nvm_path/.nvmrc && -r $nvm_path/.nvmrc ]]; then
        declare nvm_version
        nvm_version=$(<"$nvm_path"/.nvmrc)

        declare locally_resolved_nvm_version
        # `nvm ls` will check all locally-available versions
        # If there are multiple matching versions, take the latest one
        # Remove the `->` and `*` characters and spaces
        # `locally_resolved_nvm_version` will be `N/A` if no local versions are found
        locally_resolved_nvm_version=$(nvm ls --no-colors "$nvm_version" | tail -1 | tr -d '\->*' | tr -d '[:space:]')

        # If it is not already installed, install it
        # `nvm install` will implicitly use the newly-installed version
        if [[ "$locally_resolved_nvm_version" == "N/A" ]]; then
            nvm install "$nvm_version";
        elif [[ $(nvm current) != "$locally_resolved_nvm_version" ]]; then
            nvm use "$nvm_version";
        fi
    fi
}
alias cd='cdnvm'
cd "$PWD"
EOF

##### neovim
# install neovim
sudo dnf install -y neovim

# neovim dependencies
sudo dnf install fzf fd-find ripgrep tree-sitter-cli python3-pip
python -m pip install pynvim

# import configurations
mkdir -p ${HOME}/.config/nvim

curl -Ssl https://raw.githubusercontent.com/gjpin/fedora-gnome/main/configs/neovim \
  -o ${HOME}/.config/nvim/init.lua

# install lsp
go install golang.org/x/tools/gopls@latest

tee ${HOME}/.local/bin/update-lsp << EOF
go install golang.org/x/tools/gopls@latest
npm update -g typescript-language-server typescript pyright neovim
EOF

chmod +x ${HOME}/.local/bin/update-lsp

# bootstrap neovim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

tee -a ${HOME}/.bashrc.d/env << 'EOF'
export EDITOR="nvim"
export VISUAL="nvim"
EOF

tee -a ${HOME}/.bashrc.d/alias << EOF
alias vi="nvim"
alias vim="nvim"
EOF

source ${HOME}/.bashrc.d/env

##### THEMING
tee ${HOME}/.local/bin/update-themes << EOF
# adw-gtk3
git clone https://github.com/lassekongo83/adw-gtk3.git
cd adw-gtk3
meson -Dprefix="${HOME}/.local" build
ninja -C build install
cd .. && rm -rf adw-gtk3

# firefox-gnome-theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme && cd firefox-gnome-theme
./scripts/install.sh
cd .. && rm -rf firefox-gnome-theme/
EOF

chmod +x ${HOME}/.local/bin/update-themes

# Install GTK and Firefox themes
update-themes

# Set GTK theme
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'

# Customize bash
tee ~/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
update-all() {
  # Update Flatpak apps
  flatpak update

  # Update system packages
  sudo dnf update -y --refresh

  # Update LSP servers
  update-lsp

  # Update GTK and Firefox themes
  update-themes

  # Update NVM
  update-nvm

  # Update NPM
  nvm install-latest-npm
}
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
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

# Laptop specific
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
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
# mkdir -p ~/.config/autostart
# cp /etc/xdg/autostart/org.gnome.Software.desktop ~/.config/autostart/
# echo "X-GNOME-Autostart-enabled=false" >> ~/.config/autostart/org.gnome.Software.desktop
# dconf write /org/gnome/desktop/search-providers/disabled "['org.gnome.Software.desktop']"

# Disable PackageKit
#sudo systemctl mask packagekit.service
