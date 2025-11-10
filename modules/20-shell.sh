#!/usr/bin/bash

################################################
##### ZSH Configuration
################################################

print_section "ZSH Configuration"

# Install ZSH
print_info "Installing ZSH"
sudo dnf install -y zsh

# Configure ZSH
print_info "Configuring ZSH"
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.zshrc -o ${HOME}/.zshrc

# Configure powerlevel10k zsh theme
print_info "Installing Powerlevel10k theme"
curl -sSL https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/zsh/.p10k.zsh -o ${HOME}/.p10k.zsh

# Add ~/.local/bin to the path
print_info "Adding ~/.local/bin to PATH"
tee ${HOME}/.zshrc.d/local-bin << 'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
EOF

# Change user default shell to ZSH
print_info "Setting ZSH as default shell"
chsh -s $(which zsh)

print_info "ZSH configuration completed"