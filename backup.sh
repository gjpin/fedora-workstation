# Ansible
sudo dnf install -y ansible

# Hashi stack
sudo dnf -y install nomad consul vault packer terraform terraform-ls

###### golang
# install golang
sudo dnf install -y golang

# set paths
tee -a ${HOME}/.bashrc.d/golang << 'EOF'
# paths
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
EOF

source ${HOME}/.bashrc.d/golang

##### Node.js
# Install and configure Node.js
sudo dnf install -y nodejs npm
mkdir -p ${HOME}/.npm-global
npm config set prefix '~/.npm-global'

tee -a ${HOME}/.bashrc.d/nodejs << 'EOF'
export PATH="$HOME/.npm-global/bin:$PATH"
EOF

source ${HOME}/.bashrc.d/nodejs

# Install Node.js global packages
npm install -g typescript typescript-language-server pyright

##### neovim
# install neovim and dependencies
sudo dnf install -y neovim fzf fd-find ripgrep tree-sitter-cli python3-pip python-neovim

# import configurations
mkdir -p ${HOME}/.config/nvim

curl -Ssl https://raw.githubusercontent.com/gjpin/fedora-gnome/main/configs/neovim \
  -o ${HOME}/.config/nvim/init.lua

# bootstrap neovim
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

tee -a ${HOME}/.bashrc.d/neovim << 'EOF'
# env
export EDITOR="nvim"
export VISUAL="nvim"

# alias
alias vi="nvim"
alias vim="nvim"
EOF




#### Configure DNS over TLS with DNSSEC
sudo mkdir -p /etc/systemd/resolved.conf.d

sudo tee /etc/systemd/resolved.conf.d/dns_over_tls.conf << EOF
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSOverTLS=yes
DNSSEC=yes
FallbackDNS=8.8.8.8 1.0.0.1 8.8.4.4
EOF

sudo systemctl restart systemd-resolved






#### GNOME SOFTWARE
# Prevent Gnome Software from autostarting
mkdir -p ~/.config/autostart
cp /etc/xdg/autostart/org.gnome.Software.desktop ~/.config/autostart/
echo "X-GNOME-Autostart-enabled=false" >> ~/.config/autostart/org.gnome.Software.desktop

##### SEARCH
# Disable select search providers
dconf write /org/gnome/desktop/search-providers/disabled "['firefox.desktop', 'org.gnome.Software.desktop', 'org.gnome.Photos.desktop', 'org.gnome.Characters.desktop', 'org.gnome.clocks.desktop', 'org.gnome.Contacts.desktop']"
