#!/usr/bin/bash

################################################
##### Desktop Environment Configuration Library
################################################

# Configure desktop environment by detecting and sourcing appropriate module
configure_desktop() {
    print_section "Desktop Environment Setup"

    # Detect desktop environment automatically
    DETECTED_DESKTOP=$(detect_desktop_environment)

    if [ "${DETECTED_DESKTOP}" = "none" ]; then
        print_warning "No desktop environment detected"
        print_info "Attempting to use user-specified desktop environment: ${DESKTOP_ENVIRONMENT:-none}"
        
        # Fallback to user-specified desktop if detection fails
        if [ -z "${DESKTOP_ENVIRONMENT}" ] || [ "${DESKTOP_ENVIRONMENT}" = "none" ]; then
            print_warning "No valid desktop environment selected or detected. Skipping desktop setup."
            return 0
        fi
        
        DETECTED_DESKTOP="${DESKTOP_ENVIRONMENT}"
    fi

    print_info "Desktop environment detected: ${DETECTED_DESKTOP}"

    # Source and execute appropriate desktop configuration module
    case "${DETECTED_DESKTOP}" in
        gnome)
            print_info "Configuring GNOME desktop environment"
            source "${SCRIPT_DIR}/modules/91-desktop-gnome.sh"
            ;;
        plasma)
            print_info "Configuring KDE Plasma desktop environment"
            source "${SCRIPT_DIR}/modules/92-desktop-plasma.sh"
            ;;
        *)
            print_warning "Unsupported desktop environment: ${DETECTED_DESKTOP}"
            print_warning "Skipping desktop configuration"
            ;;
    esac

    print_info "Desktop environment setup completed"
}

# Export function
export -f configure_desktop