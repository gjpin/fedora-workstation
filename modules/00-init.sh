#!/usr/bin/bash

################################################
##### Initialization and User Input
################################################

print_section "System Configuration Setup"

# Collect user preferences
read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Gaming (yes / no): " GAMING
export GAMING

read -p "Steam (native / flatpak): " STEAM_VERSION
export STEAM_VERSION

read -p "RPM Fusion (yes / no): " RPM_FUSION
export RPM_FUSION

print_info "Configuration collected:"
print_info "  Hostname: ${NEW_HOSTNAME}"
print_info "  Gaming: ${GAMING}"
print_info "  Steam: ${STEAM_VERSION}"
print_info "  RPM Fusion: ${RPM_FUSION}"
print_info ""
print_info "Desktop environment will be auto-detected during setup"