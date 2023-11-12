#!/usr/bin/bash

################################################
##### Disable unneeded services
################################################

# Disable Gnome Software autostart
cp /etc/xdg/autostart/org.gnome.Software.desktop ${HOME}/.config/autostart/org.gnome.Software.desktop
tee -a ${HOME}/.config/autostart/org.gnome.Software.desktop << EOF
Hidden=true
EOF

# Disable Gnome Software auto updates
gsettings set org.gnome.software download-updates false
gsettings set org.gnome.software download-updates-notify false

# Disable Tracker (indexing) and search providers
gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Nautilus.desktop', 'org.gnome.Boxes.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.Characters.desktop', 'org.gnome.clocks.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Contacts.desktop', 'org.gnome.Photos.desktop', 'org.gnome.Software.desktop']"
gsettings set org.gnome.desktop.search-providers enabled "@as []"
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

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

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
user_pref("gnomeTheme.activeTabContrast", true);
EOF

################################################
##### VSCode
################################################

# References:
# https://github.com/piousdeer/vscode-adwaita

# Install VSCode Gnome theme
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme

# Change VSCode config to use theme
sed -i '2 i \ \ \ \ "workbench.preferredDarkColorTheme": "Adwaita Dark",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.preferredLightColorTheme": "Adwaita Light",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json
sed -i '2 i \ \ \ \ "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json

################################################
##### GTK theme
################################################

# References:
# https://github.com/lassekongo83/adw-gtk3

# Install adw-gtk3 flatpak
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Install adw-gtk3 theme
sudo dnf install -y adw-gtk3-theme

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

################################################
##### Utilities
################################################

# Install gnome-randr
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/apps/gnome-randr.py -O
chmod +x gnome-randr.py
sudo mv gnome-randr.py /usr/local/bin/gnome-randr

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
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'com.visualstudio.code.desktop']"

# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Increase check-alive-timeout to 30 seconds
gsettings set org.gnome.mutter check-alive-timeout 30000

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
gsettings set org.gnome.desktop.interface monospace-font-name 'Source Code Pro 10' # default: Source Code Pro 10

# Set text editor font
gsettings set org.gnome.TextEditor custom-font 'Source Code Pro 10'

# Folders
gsettings set org.gnome.desktop.app-folders folder-children "['Dev', 'Emulators', 'Gaming', 'Gnome', 'Media', 'Office', 'Security', 'System']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Dev/ name 'Dev'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Dev/ apps "['code.desktop', 'com.visualstudio.code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.github.marhkb.Pods.desktop', 'org.gaphor.Gaphor.desktop', 'org.gnome.gitg.desktop', 'org.gnome.Boxes.desktop', 'nvim.desktop', 'org.chromium.Chromium.desktop', 'org.gnome.Connections.desktop', 'qemu.desktop', 'remote-viewer.desktop', 'com.google.Chrome.desktop', 'virt-manager.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Emulators/ name 'Emulators'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Emulators/ apps "['org.duckstation.DuckStation.desktop', 'net.pcsx2.PCSX2.desktop', 'org.ppsspp.PPSSPP.desktop', 'org.DolphinEmu.dolphin-emu.desktop', 'org.yuzu_emu.yuzu.desktop', 'org.citra_emu.citra.desktop', 'org.flycast.Flycast.desktop', 'app.xemu.xemu.desktop', 'com.snes9x.Snes9x.desktop', 'net.kuribo64.melonDS.desktop', 'net.rpcs3.RPCS3.desktop', 'io.mgba.mGBA.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gaming/ name 'Gaming'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gaming/ apps "['com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop', 'net.lutris.Lutris.desktop', 'net.davidotek.pupgui2.desktop', 'com.usebottles.bottles.desktop', 'com.steamgriddb.SGDBoop.desktop', 'sunshine.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gnome/ name 'Gnome'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Gnome/ apps "['org.gnome.Weather.desktop', 'org.gnome.Maps.desktop', 'org.gnome.Tour.desktop', 'org.gnome.Cheese.desktop', 'yelp.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Media/ name 'Media'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Media/ apps "['io.github.celluloid_player.Celluloid.desktop', 'io.github.seadve.Kooha.desktop', 'com.spotify.Client.desktop', 'org.blender.Blender.desktop', 'org.gimp.GIMP.desktop', 'org.gnome.eog.desktop', 'org.gnome.Totem.desktop', 'org.gnome.Rhythmbox3.desktop', 'org.gnome.Photos.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Office/ name 'Office'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Office/ apps "['com.github.flxzt.rnote.desktop', 'org.gnome.Evince.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.clocks.desktop', 'md.obsidian.Obsidian.desktop', 'simple-scan.desktop', 'org.gnome.Contacts.desktop', 'org.libreoffice.LibreOffice.desktop', 'org.libreoffice.LibreOffice.base.desktop', 'org.libreoffice.LibreOffice.calc.desktop', 'org.libreoffice.LibreOffice.draw.desktop', 'org.libreoffice.LibreOffice.impress.desktop', 'org.libreoffice.LibreOffice.math.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'libreoffice-calc.desktop', 'libreoffice-impress.desktop', 'libreoffice-writer.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Security/ name 'Security'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Security/ apps "['com.belmoussaoui.Authenticator.desktop', 'com.bitwarden.desktop.desktop', 'org.keepassxc.KeePassXC.desktop', 'com.github.tchx84.Flatseal.desktop', 'firewall-config.desktop']"

gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ name 'System'
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ apps "['org.gnome.Software.desktop' , 'org.gnome.baobab.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Settings.desktop', 'gnome-system-monitor.desktop', 'org.gnome.Characters.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Logs.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'kvantummanager.desktop', 'org.fedoraproject.MediaWriter.desktop', 'org.freedesktop.GnomeAbrt.desktop']"

gsettings set org.gnome.shell app-picker-layout "[{'Dev': <{'position': <0>}>, 'Emulators': <{'position': <1>}>, 'Gaming': <{'position': <2>}>, 'Gnome': <{'position': <3>}>, 'Media': <{'position': <4>}>, 'Office': <{'position': <5>}>, 'Security': <{'position': <6>}>, 'System': <{'position': <7>}>]"

################################################
##### Gnome Shell Extensions
################################################

# Create Gnome shell extensions folder
mkdir -p ${HOME}/.local/share/gnome-shell/extensions

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
# https://src.fedoraproject.org/rpms/gnome-shell-extension-appindicator/blob/rawhide/f/gnome-shell-extension-appindicator.spec
sudo dnf install -y libappindicator-gtk3

curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v53.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Grand Theft Focus
# # https://extensions.gnome.org/extension/5410/grand-theft-focus
curl -sSL https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v3.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v11.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v5.shell-extension.zip -O
gnome-extensions install *.shell-extension.zip
rm -f *.shell-extension.zip

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'grand-theft-focus@zalckos.github.com', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']"

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