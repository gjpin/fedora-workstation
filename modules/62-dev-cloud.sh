#!/usr/bin/bash

################################################
##### Cloud / Kubernetes Tools
################################################

print_section "Cloud / Kubernetes Tools"

################################################
##### OpenTofu
################################################

print_info "Installing OpenTofu"
sudo dnf install -y opentofu

################################################
##### Kubernetes Tools
################################################

print_info "Installing Kubernetes tools"

# Install kubectl
sudo dnf install -y kubernetes-client

# Install helm
sudo dnf install -y helm

################################################
##### Krew
################################################

print_info "Installing Krew"

# Install Krew
mkdir -p /tmp/krew
curl -sSL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz -o /tmp/krew/krew.tar.gz
tar zxvf /tmp/krew/krew.tar.gz -C /tmp/krew
./tmp/krew/krew-linux_amd64 install krew
rm -rf /tmp/krew

# Add Kubectl Krew updater to main updater
append_to_updater '
################################################
##### Kubectl Krew plugins
################################################

# Update Kubectl Krew plugins
kubectl krew upgrade
'

# Source krew temporarily
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install krew plugins
print_info "Installing Krew plugins"
kubectl krew install ctx
kubectl krew install ns
kubectl krew install node-shell

################################################
##### Kubernetes Configuration
################################################

print_info "Configuring Kubernetes aliases and autocompletion"

# Kubernetes aliases and autocompletion
create_zsh_config "kubernetes" '# Kubectl alias
alias k="kubectl"
alias kx="kubectl ctx"
alias kn="kubectl ns"
alias ks="kubectl node-shell"

# Autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion zsh)

# Krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# k9s
alias k9s="podman run --rm -it -v ~/.kube/config:/root/.kube/config quay.io/derailed/k9s"'

print_info "Cloud/Kubernetes tools installation completed"