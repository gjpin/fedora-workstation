#!/usr/bin/bash

################################################
##### IDEs and Editors
################################################

print_section "IDEs and Editors"

################################################
##### Neovim
################################################

print_info "Installing Neovim"

# Install Neovim and set as default editor
sudo dnf install -y neovim

create_zsh_config "neovim" '# Set neovim alias
alias vi=nvim
alias vim=nvim

# Set preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='\''vim'\''
  export VISUAL='\''vim'\''
else
  export EDITOR='\''nvim'\''
  export VISUAL='\''nvim'\''
fi'

################################################
##### VSCode (Native)
################################################

print_info "Installing VSCode"

# Import Microsoft key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Add VSCode repository
sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Install VSCode
dnf check-update
sudo dnf install -y code

# Install extensions
print_info "Installing VSCode extensions"
code --install-extension golang.Go
code --install-extension ms-python.python
code --install-extension redhat.vscode-yaml
code --install-extension hashicorp.terraform

# Configure VSCode
mkdir -p ${HOME}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/vscode/settings.json -o ${HOME}/.config/Code/User/settings.json

################################################
##### Godot
################################################

print_info "Installing Godot"

# Install Godot
install_flatpak_app "org.godotengine.Godot"

# Blender wrapper for Godot
tee ${HOME}/.local/bin/blender-flatpak-wrapper << 'EOF'
#!/usr/bin/bash

flatpak-spawn --host flatpak run org.blender.Blender "$@"
EOF

chmod +x ${HOME}/.local/bin/blender-flatpak-wrapper

# Pin Godot version
flatpak mask org.godotengine.Godot

print_info "IDEs and editors installation completed"