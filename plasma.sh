#!/usr/bin/bash

################################################
##### Remove unneeded packages and services
################################################

# Remove games
sudo dnf remove -y \
    kmahjongg \
    kmines \
    kpat

# Disable baloo (file indexer)
balooctl suspend
balooctl disable
balooctl purge

################################################
##### Flatpak
################################################

# Install Breeze-GTK flatpak theme
flatpak install -y flathub org.gtk.Gtk3theme.Breeze

# Install applications
flatpak install -y flathub org.videolan.VLC

################################################
##### Firefox
################################################

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)

# KDE specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// KDE integration
// https://wiki.archlinux.org/title/firefox#KDE_integration
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
EOF

################################################
##### SSH
################################################

# Install Plasma related packages
sudo dnf install -y \
    ksshaskpass

# Use the KDE Wallet to store ssh key passphrases
# https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
tee ${HOME}/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q
Name=ssh-add
Type=Application
EOF

tee ${HOME}/.config/environment.d/ssh_askpass.conf << EOF
SSH_ASKPASS='/usr/bin/ksshaskpass'
GIT_ASKPASS=ksshaskpass
SSH_ASKPASS=ksshaskpass
SSH_ASKPASS_REQUIRE=prefer
EOF

################################################
##### Plasma shortcuts
################################################

kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

################################################
##### Plasma UI / UX changes
################################################

# Import Plasma color schemes
mkdir -p ${HOME}/.local/share/color-schemes
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/Blender.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/DiscordDark.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/Gimp.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/Godot.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/HeroicGamesLauncher.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/Insomnia.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/ObsidianDark.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/SlackAubergineLightcolors.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/Spotify.colors
curl -O --output-dir ${HOME}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/fedora-workstation/configs/kde/colors/VSCodeDefaultDark.colors

# Set Plasma theme
kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Set SDDM theme
sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Change window decorations
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Disable splash screen
kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig6 --file ksplashrc --group KSplash --key Theme "none"

# Disable app launch feedback
kwriteconfig6 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig6 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Configure screen edges
kwriteconfig6 --file kwinrc --group Effect-overview --key BorderActivate "7"
kwriteconfig6 --file kwinrc --group Effect-windowview --key BorderActivateAll "9"

# Konsole shortcut
kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Spectacle shortcut
kwriteconfig6 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"

# Overview shortcut
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Close windows shortcut
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Replace plasmashell
kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_k_friendly_name" "plasmashell --replace"
kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_launch" "Ctrl+Alt+Del,none,plasmashell --replace"

# Enable 2 desktops
kwriteconfig6 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
kwriteconfig6 --file kwinrc --group Desktops --key Number "2"
kwriteconfig6 --file kwinrc --group Desktops --key Rows "1"

# Configure konsole
kwriteconfig6 --file konsolerc --group "KonsoleWindow" --key "RememberWindowSize" --type bool false
kwriteconfig6 --file konsolerc --group "MainWindow" --key "MenuBar" "Disabled"

# Window decorations
kwriteconfig6 --file kwinrulesrc --group 1 --key Description "Application settings for vscode"
kwriteconfig6 --file kwinrulesrc --group 1 --key decocolor "VSCodeDefaultDark"
kwriteconfig6 --file kwinrulesrc --group 1 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 1 --key wmclass "code"
kwriteconfig6 --file kwinrulesrc --group 1 --key wmclasscomplete --type bool true
kwriteconfig6 --file kwinrulesrc --group 1 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 2 --key Description "Application settings for blender"
kwriteconfig6 --file kwinrulesrc --group 2 --key decocolor "Blender"
kwriteconfig6 --file kwinrulesrc --group 2 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 2 --key wmclass "\sblender"
kwriteconfig6 --file kwinrulesrc --group 2 --key wmclasscomplete --type bool true
kwriteconfig6 --file kwinrulesrc --group 2 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 3 --key Description "Application settings for gimp"
kwriteconfig6 --file kwinrulesrc --group 3 --key decocolor "Gimp"
kwriteconfig6 --file kwinrulesrc --group 3 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 3 --key wmclass "gimp"
kwriteconfig6 --file kwinrulesrc --group 3 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 3 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 4 --key Description "Application settings for godot"
kwriteconfig6 --file kwinrulesrc --group 4 --key decocolor "Godot"
kwriteconfig6 --file kwinrulesrc --group 4 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 4 --key wmclass "godot_editor godot"
kwriteconfig6 --file kwinrulesrc --group 4 --key wmclasscomplete --type bool true
kwriteconfig6 --file kwinrulesrc --group 4 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 4 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 5 --key Description "Application settings for discord"
kwriteconfig6 --file kwinrulesrc --group 5 --key decocolor "DiscordDark"
kwriteconfig6 --file kwinrulesrc --group 5 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 5 --key wmclass "discord"
kwriteconfig6 --file kwinrulesrc --group 5 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 5 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 6 --key Description "Application settings for insomnia"
kwriteconfig6 --file kwinrulesrc --group 6 --key decocolor "Insomnia"
kwriteconfig6 --file kwinrulesrc --group 6 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 6 --key wmclass "insomnia"
kwriteconfig6 --file kwinrulesrc --group 6 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 6 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 7 --key Description "Application settings for heroic"
kwriteconfig6 --file kwinrulesrc --group 7 --key decocolor "HeroicGamesLauncher"
kwriteconfig6 --file kwinrulesrc --group 7 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 7 --key wmclass "heroic"
kwriteconfig6 --file kwinrulesrc --group 7 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 7 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 8 --key Description "Application settings for spotify"
kwriteconfig6 --file kwinrulesrc --group 8 --key decocolor "Spotify"
kwriteconfig6 --file kwinrulesrc --group 8 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 8 --key wmclass "spotify"
kwriteconfig6 --file kwinrulesrc --group 8 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 8 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 9 --key Description "Application settings for obsidian"
kwriteconfig6 --file kwinrulesrc --group 9 --key decocolor "ObsidianDark"
kwriteconfig6 --file kwinrulesrc --group 9 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 9 --key wmclass "obsidian"
kwriteconfig6 --file kwinrulesrc --group 9 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 9 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group 10 --key Description "Application settings for slack"
kwriteconfig6 --file kwinrulesrc --group 10 --key decocolor "SlackAubergineLight.colors"
kwriteconfig6 --file kwinrulesrc --group 10 --key decocolorrule 2
kwriteconfig6 --file kwinrulesrc --group 10 --key wmclass "slack"
kwriteconfig6 --file kwinrulesrc --group 10 --key clientmachine "localhost"
kwriteconfig6 --file kwinrulesrc --group 10 --key wmclassmatch 1

kwriteconfig6 --file kwinrulesrc --group General --key count 10
kwriteconfig6 --file kwinrulesrc --group General --key rules "1,2,3,4,5,6,7,8,9,10"