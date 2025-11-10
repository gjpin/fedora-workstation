#!/usr/bin/bash

################################################
##### Shared Library Functions
################################################

# Color codes for output
readonly COLOR_RESET="\033[0m"
readonly COLOR_GREEN="\033[0;32m"
readonly COLOR_BLUE="\033[0;34m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[0;31m"

# Print section header
print_section() {
    echo -e "\n${COLOR_BLUE}================================================${COLOR_RESET}"
    echo -e "${COLOR_BLUE}##### $1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}================================================${COLOR_RESET}\n"
}

# Print info message
print_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $1"
}

# Print warning message
print_warning() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

# Print error message
print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

# Install Flatpak application with override config
install_flatpak_app() {
    local app_id=$1
    local config_url="https://raw.githubusercontent.com/gjpin/fedora-workstation/main/configs/flatpak/${app_id}"
    
    print_info "Installing Flatpak: ${app_id}"
    flatpak install -y flathub "${app_id}"
    
    # Download override config if it exists
    if curl --output /dev/null --silent --head --fail "${config_url}"; then
        curl -sSL "${config_url}" -o "${HOME}/.local/share/flatpak/overrides/${app_id}"
        print_info "Applied override config for ${app_id}"
    fi
}

# Append content to update-all script
append_to_updater() {
    local content="$1"
    echo "${content}" >> "${HOME}/.local/bin/update-all"
}

# Create ZSH config file in .zshrc.d
create_zsh_config() {
    local filename=$1
    local content="$2"
    
    echo "${content}" > "${HOME}/.zshrc.d/${filename}"
    print_info "Created ZSH config: ${filename}"
}

# Check if running on laptop
is_laptop() {
    [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
}

# Check if Intel GPU
has_intel_gpu() {
    lspci | grep -q "VGA.*Intel"
}

# Check if AMD GPU
has_amd_gpu() {
    lspci | grep -q "VGA.*AMD"
}

# Check if user wants to install feature
should_install() {
    local feature=$1
    [[ "${!feature}" == "yes" ]]
}

# Detect desktop environment
detect_desktop_environment() {
    if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
        case "${XDG_CURRENT_DESKTOP}" in
            *GNOME*)
                echo "gnome"
                return 0
                ;;
            *KDE*|*Plasma*)
                echo "plasma"
                return 0
                ;;
        esac
    fi
    
    # Fallback: check for session type
    if [ -n "${DESKTOP_SESSION:-}" ]; then
        case "${DESKTOP_SESSION}" in
            gnome*|GNOME*)
                echo "gnome"
                return 0
                ;;
            plasma*|kde*)
                echo "plasma"
                return 0
                ;;
        esac
    fi
    
    # Fallback: check for running processes
    if pgrep -x "gnome-shell" > /dev/null; then
        echo "gnome"
        return 0
    elif pgrep -x "plasmashell" > /dev/null; then
        echo "plasma"
        return 0
    fi
    
    # No desktop detected
    echo "none"
    return 1
}

# Export all functions for use in modules
export -f print_section
export -f print_info
export -f print_warning
export -f print_error
export -f install_flatpak_app
export -f append_to_updater
export -f create_zsh_config
export -f is_laptop
export -f has_intel_gpu
export -f has_amd_gpu
export -f should_install
export -f detect_desktop_environment