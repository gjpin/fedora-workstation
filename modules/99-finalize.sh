#!/usr/bin/bash

################################################
##### Finalization
################################################

print_section "Finalization"

################################################
##### Gaming Setup
################################################

if should_install GAMING; then
    print_info "Installing gaming setup"
    
    # Download and execute gaming setup script
    curl https://raw.githubusercontent.com/gjpin/fedora-workstation/main/gaming.sh -O
    chmod +x ./gaming.sh
    ./gaming.sh
else
    print_info "Skipping gaming setup"
fi

################################################
##### Completion
################################################

print_section "Setup Complete!"

print_info "All modules have been executed successfully."
print_info "Some changes may require a system reboot to take effect."
print_info ""
print_info "Next steps:"
print_info "  1. Review any warnings or errors above"
print_info "  2. Reboot your system: sudo reboot"
print_info "  3. After reboot, run 'update-all' to update all components"
print_info ""
print_info "Your update script is located at: ${HOME}/.local/bin/update-all"

echo ""
read -p "Would you like to reboot now? (yes/no): " REBOOT_NOW

if [ "${REBOOT_NOW}" = "yes" ]; then
    print_info "Rebooting system..."
    sudo reboot
else
    print_info "Please remember to reboot your system when ready."
fi