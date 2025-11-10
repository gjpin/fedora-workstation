#!/usr/bin/bash

################################################
##### Development Tools
################################################

print_section "Development Tools"

################################################
##### Git
################################################

print_info "Configuring Git"

# Install gitg
install_flatpak_app "org.gnome.gitg"

# Set git configurations
git config --global init.defaultBranch main

################################################
##### Make
################################################

print_info "Installing Make"
sudo dnf install -y make

################################################
##### Go
################################################

print_info "Installing Go"
sudo dnf install -y golang

mkdir -p ${HOME}/.go

create_zsh_config "go" 'export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"'

################################################
##### C++ Compilers
################################################

print_info "Installing C++ compilers"
sudo dnf install -y gcc-c++ clang clang-tools-extra llvm

################################################
##### Python
################################################

print_info "Installing Python uv"
sudo dnf install -y uv

create_zsh_config "python" '# uv shell autocompletion
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"'

################################################
##### Java
################################################

print_info "Installing Java (OpenJDK)"

# Install OpenJDK 17
sudo dnf install -y \
  java-17-openjdk \
  java-17-openjdk-devel

# Install OpenJDK 21
sudo dnf install -y \
  java-21-openjdk \
  java-21-openjdk-devel

# Set default Java version to 21
sudo alternatives --set java java-21-openjdk.x86_64

################################################
##### Syncthing
################################################

print_info "Installing Syncthing"

# Install syncthing and enable service
sudo dnf install -y syncthing
systemctl --user enable syncthing.service

print_info "Development tools installation completed"