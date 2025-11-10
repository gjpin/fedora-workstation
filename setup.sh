#!/usr/bin/bash

################################################
##### Fedora Workstation Setup Script
################################################
# Modular setup script for Fedora Workstation
# 
# This script orchestrates the installation and
# configuration of a complete Fedora workstation
# by executing numbered modules in sequence.
################################################

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared library functions
source "${SCRIPT_DIR}/lib/functions.sh"

################################################
##### Welcome Message
################################################

clear
echo "================================================"
echo "    Fedora Workstation Setup Script"
echo "================================================"
echo ""
echo "This script will set up your Fedora workstation"
echo "by executing a series of installation modules."
echo ""
echo "The setup includes:"
echo "  - System base configuration"
echo "  - Shell and terminal setup (ZSH)"
echo "  - Security hardening"
echo "  - Development tools"
echo "  - Applications and desktop environment"
echo ""
echo "Press Ctrl+C to cancel at any time."
echo ""
read -p "Press Enter to continue..."

################################################
##### Execute Modules
################################################

# Array of module files in execution order
MODULES=(
    "00-init.sh"
    "10-system-base.sh"
    "20-shell.sh"
    "30-security.sh"
    "40-rpm-fusion.sh"
    "41-flatpak.sh"
    "50-containers.sh"
    "60-development.sh"
    "61-dev-android.sh"
    "62-dev-cloud.sh"
    "70-ide.sh"
    "80-applications.sh"
    "81-browsers.sh"
    "90-desktop.sh"
    "99-finalize.sh"
)

# Execute each module
for module in "${MODULES[@]}"; do
    module_path="${SCRIPT_DIR}/modules/${module}"
    
    if [ -f "${module_path}" ]; then
        print_info "Executing module: ${module}"
        source "${module_path}"
        
        if [ $? -ne 0 ]; then
            print_error "Module ${module} failed to execute"
            exit 1
        fi
    else
        print_warning "Module not found: ${module}"
    fi
done

################################################
##### Completion
################################################

echo ""
print_info "All modules executed successfully!"
