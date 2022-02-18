##### GNOME EXTENSIONS
# AppIndicator and KStatusNotifierItem Support
wget https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v41.shell-extension.zip
gnome-extensions install appindicatorsupportrgcjonas.gmail.com.v41.shell-extension.zip
rm appindicatorsupportrgcjonas.gmail.com.v41.shell-extension.zip

# Tray Icons: Reloaded
wget https://extensions.gnome.org/extension-data/trayIconsReloadedselfmade.pl.v21.shell-extension.zip
gnome-extensions install trayIconsReloadedselfmade.pl.v21.shell-extension.zip
rm trayIconsReloadedselfmade.pl.v21.shell-extension.zip

###### Steam
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/gjpin/fedora-gnome/main/gaming/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules

# Reload udev rules
sudo udevadm control --reload && sudo udevadm trigger

# Enable uinput module
sudo tee -a /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

###### CoreCtrl
sudo dnf install -y corectrl

# Launch CoreCtrl on session startup
mkdir -p ~/.config/autostart
cp /usr/share/applications/org.corectrl.corectrl.desktop ~/.config/autostart/org.corectrl.corectrl.desktop

# Don't ask for user password
sudo tee -a /etc/polkit-1/rules.d/90-corectrl.rules << EOF
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

# Download CoreCtrl profile
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-gnome/main/gaming/_global_.ccpro -o ~/Downloads/_global_.ccpro