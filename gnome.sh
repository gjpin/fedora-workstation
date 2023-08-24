#!/usr/bin/bash

################################################
##### Remove unneeded packages and services
################################################

# Remove Gnome software
sudo dnf remove -y gnome-software

# Remove packages
sudo dnf remove -y \
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

# Disable Tracker (indexing) and search providers
gsettings set org.gnome.desktop.search-provers disable-external true
gsettings set org.freedesktop.Tracker3.Miner.Files index-single-directories "@as []"
gsettings set org.freedesktop.Tracker3.Miner.Files index-recursive-directories "@as []"

systemctl --user mask \
  tracker-extract-3.service \
  tracker-miner-fs-control-3.service \
  tracker-writeback-3.service \
  tracker-miner-fs-3.service \
  tracker-miner-rss-3.service \
  tracker-xdg-portal-3.service

################################################
##### Flatpak
################################################

# Install applications
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub io.github.celluloid_player.Celluloid
flatpak install -y flathub org.gaphor.Gaphor
flatpak install -y flathub com.github.flxzt.rnote
flatpak install -y flathub org.gnome.gitg

################################################
##### Firefox
################################################

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)

# Install Firefox Gnome theme
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/bash

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)
git -C ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme pull
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

# Add Firefox theme updater to bash updater function
sed -i '2 i \ ' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ update-firefox-theme' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ # Update Firefox theme' ${HOME}/.bashrc.d/update-all

# Gnome specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// Firefox Gnome theme
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity", 0);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.theme.dark-private-windows", false);
EOF

################################################
##### VSCode
################################################

# References:
# https://github.com/piousdeer/vscode-adwaita

# Install VSCode Gnome theme
code --install-extension piousdeer.adwaita-theme

# Change VSCode config to use theme
sed -i '2 i \ \ \ \ "workbench.preferredDarkColorTheme": "Adwaita Dark",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.preferredLightColorTheme": "Adwaita Light",' ${HOME}/.config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' ${HOME}/.config/Code/User/settings.json

################################################
##### Utilities
################################################

# Install gnome-randr
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/apps/gnome-randr.py -O
chmod +x gnome-randr.py
sudo mv gnome-randr.py /usr/local/bin/gnome-randr.py

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O || exit 1
rm -rf ${HOME}/.local/share/themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz
EOF

chmod +x ${HOME}/.local/bin/update-gtk-theme

# Add gnome theme updater to bash updater function
sed -i '2 i \ ' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ update-gtk-theme' ${HOME}/.bashrc.d/update-all
sed -i '2 i \ \ # Update GTK theme' ${HOME}/.bashrc.d/update-all

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
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
##### Gnome UI / UX changes
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
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10' # default: Cantarell 11
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 10' # default: Cantarell 11
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 10' # default: Cantarell Bold 11
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10' # default: Source Code Pro 10

# Folders
gsettings set org.gnome.desktop.app-folders folder-children "['Office', 'Dev', 'Media', 'System', 'Gaming', 'Emulators']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Office/ name 'Office'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Office/ apps "['libreoffice-calc.desktop', 'libreoffice-impress.desktop', 'libreoffice-writer.desktop', 'com.github.flxzt.rnote.desktop', 'org.gnome.Evince.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.clocks.desktop', 'md.obsidian.Obsidian.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Dev/ name 'Dev'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Dev/ apps "['code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.github.marhkb.Pods.desktop', 'org.gaphor.Gaphor.desktop', 'org.gnome.gitg.desktop', 'org.gnome.Boxes.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Media/ name 'Media'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Media/ apps "['io.github.celluloid_player.Celluloid.desktop', 'io.github.seadve.Kooha.desktop', 'com.spotify.Client.desktop', 'org.blender.Blender.desktop', 'org.gimp.GIMP.desktop', 'org.gnome.eog.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ name 'System'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ apps "['org.gnome.baobab.desktop', 'firewall-config.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Settings.desktop', 'gnome-system-monitor.desktop', 'org.gnome.Characters.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Logs.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'kvantummanager.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gaming/ name 'Gaming'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gaming/ apps "['com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop', 'net.lutris.Lutris.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Emulators/ name 'Emulators'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Emulators/ apps "['org.duckstation.DuckStation.desktop', 'net.pcsx2.PCSX2.desktop', 'org.ppsspp.PPSSPP.desktop', 'org.DolphinEmu.dolphin-emu.desktop', 'org.yuzu_emu.yuzu.desktop', 'org.citra_emu.citra.desktop', 'org.flycast.Flycast.desktop', 'app.xemu.xemu.desktop', 'com.snes9x.Snes9x.desktop', 'net.kuribo64.melonDS.desktop', 'net.rpcs3.RPCS3.desktop']"

gsettings set org.gnome.shell app-picker-layout "[{'Dev': <{'position': <0>}>, 'Emulators': <{'position': <1>}>, 'Gaming': <{'position': <2>}>, 'Media': <{'position': <3>}>, 'Office': <{'position': <4>}>, 'System': <{'position': <5>}>, 'com.belmoussaoui.Authenticator.desktop': <{'position': <6>}>, 'com.bitwarden.desktop.desktop': <{'position': <7>}>, 'com.usebottles.bottles.desktop': <{'position': <8>}>, 'chromium-freeworld.desktop': <{'position': <9>}>, 'com.github.tchx84.Flatseal.desktop': <{'position': <10>}>}]"

# Wallpaper and screensaver
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/blobs-l.svg'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/gnome/blobs-d.svg'
gsettings set org.gnome.desktop.background primary-color '#241f31'

gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/backgrounds/gnome/blobs-l.svg'
gsettings set org.gnome.desktop.screensaver primary-color '#241f31'

################################################
##### Gnome Shell Extensions
################################################

# Create Gnome shell extensions folder
mkdir -p ${HOME}/.local/share/gnome-shell/extensions

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v56.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
sudo dnf install -y xprop

curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v9.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

gsettings --schemadir ~/.local/share/gnome-shell/extensions/dark-variant@hardpixel.eu/schemas set org.gnome.shell.extensions.dark-variant applications "['code.desktop', 'com.visualstudio.code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.spotify.Client.desktop', 'md.obsidian.Obsidian.desktop', 'org.gimp.GIMP.desktop', 'org.blender.Blender.desktop', 'org.godotengine.Godot.desktop', 'com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop', 'org.duckstation.DuckStation.desktop', 'net.pcsx2.PCSX2.desktop', 'org.ppsspp.PPSSPP.desktop', 'app.xemu.xemu.desktop']"

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
sudo dnf install -y openssl

curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v55.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v11.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v7.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'gsconnect@andyholmes.github.io', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']"

################################################
##### Gnome misc configurations
################################################

# Hide applications from Gnome overview
APPLICATIONS=('htop' 'lpf-cleartype-fonts' 'lpf' 'lpf-gui' 'lpf-ms-core-fonts' 'lpf-notify' 'lpf-mscore-tahoma-fonts' 'syncthing-start' 'syncthing-ui')
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