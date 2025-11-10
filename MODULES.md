# Fedora Workstation Setup - Modular Structure

## Overview

The setup script has been refactored into a modular structure for better maintainability, readability, and flexibility. The original monolithic 839-line script is now split into logical, focused modules.

## Directory Structure

```
fedora-workstation/
├── setup.sh                    # Main orchestrator script
├── lib/
│   └── functions.sh           # Shared utility functions
├── modules/
│   ├── 00-init.sh            # User input and initialization
│   ├── 10-system-base.sh     # Core system configuration
│   ├── 20-shell.sh           # ZSH and terminal setup
│   ├── 30-security.sh        # SELinux, systemd, WireGuard, LUKS/TPM2
│   ├── 40-runtimes.sh        # Toolbox, RPM Fusion, Flatpak
│   ├── 50-containers.sh      # Podman, Virtualization
│   ├── 60-development.sh     # Git, Go, Python, Java, C++
│   ├── 61-dev-android.sh     # Android SDK and tools
│   ├── 62-dev-cloud.sh       # Kubernetes, Helm, OpenTofu
│   ├── 70-ide.sh             # Neovim, VSCode, Godot
│   ├── 80-applications.sh    # Flatpak applications
│   ├── 81-app-firefox.sh     # Firefox configuration
│   ├── 90-desktop.sh         # GNOME/Plasma setup
│   └── 99-finalize.sh        # Gaming and completion
├── configs/                   # Configuration files
├── apps/                      # Application scripts
├── gaming.sh                  # Gaming setup (external)
├── gnome.sh                   # GNOME setup (external)
└── plasma.sh                  # Plasma setup (external)
```

## Usage

### Basic Usage

Simply run the main setup script:

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
1. Prompt for configuration options (hostname, desktop environment, gaming, etc.)
2. Execute all modules in sequence
3. Display progress with colored output
4. Create an `update-all` script in `~/.local/bin/`

### Module Execution Order

Modules are executed in numerical order:
1. **00-init.sh** - Collects user preferences
2. **10-system-base.sh** - Sets up base system (DNF, updates, fonts)
3. **20-shell.sh** - Configures ZSH
4. **30-security.sh** - Hardens security (SELinux, TPM2, power management)
5. **40-runtimes.sh** - Installs runtimes (Toolbox, RPM Fusion, Flatpak)
6. **50-containers.sh** - Sets up containers (Podman, libvirt)
7. **60-development.sh** - Installs dev tools (Git, Go, Python, Java)
8. **61-dev-android.sh** - Android development environment
9. **62-dev-cloud.sh** - Cloud/Kubernetes tools
10. **70-ide.sh** - IDEs and editors (Neovim, VSCode, Godot)
11. **80-applications.sh** - Common applications
12. **81-app-firefox.sh** - Firefox browser setup
13. **90-desktop.sh** - Desktop environment configuration
14. **99-finalize.sh** - Gaming setup and completion

## Shared Functions

The `lib/functions.sh` provides reusable utilities:

- **print_section()** - Print colored section headers
- **print_info()** - Print info messages
- **print_warning()** - Print warning messages
- **print_error()** - Print error messages
- **install_flatpak_app()** - Install Flatpak with config
- **append_to_updater()** - Add to update-all script
- **create_zsh_config()** - Create ZSH config snippet
- **is_laptop()** - Check if system is a laptop
- **has_intel_gpu()** - Check for Intel GPU
- **has_amd_gpu()** - Check for AMD GPU
- **should_install()** - Check user preferences

## Benefits of Modular Structure

### Maintainability
- Easy to locate and update specific functionality
- Changes are isolated to relevant modules
- Reduced risk of breaking unrelated features

### Readability
- Clear separation of concerns
- Self-documenting module names
- Smaller, focused files (28-131 lines vs 839 lines)

### Flexibility
- Can skip modules by commenting them out in setup.sh
- Easy to add new modules
- Simple to create variations for different use cases

### Reusability
- Shared functions eliminate code duplication
- Modules can be used independently
- Easy to extract modules for other projects

### Testing
- Test individual modules in isolation
- Syntax checking per module
- Easier debugging with smaller scope

## Customization

### Adding a New Module

1. Create a new file in `modules/` with appropriate number prefix:
   ```bash
   touch modules/65-custom.sh
   ```

2. Add your installation logic using shared functions:
   ```bash
   #!/usr/bin/bash
   print_section "Custom Setup"
   print_info "Installing custom software"
   # Your commands here
   ```

3. Add the module to setup.sh MODULES array

### Skipping Modules

Comment out unwanted modules in `setup.sh`:
```bash
MODULES=(
    "00-init.sh"
    "10-system-base.sh"
    # "61-dev-android.sh"  # Skip Android tools
    "70-ide.sh"
)
```

### Modifying Existing Modules

Simply edit the relevant module file. All changes are contained within that module.

## User Input

User preferences are collected once at the beginning (module 00-init.sh) and exported as environment variables:

- `NEW_HOSTNAME` - System hostname
- `DESKTOP_ENVIRONMENT` - gnome or plasma
- `GAMING` - yes or no
- `STEAM_VERSION` - native or flatpak
- `RPM_FUSION` - yes or no

These variables are available to all subsequent modules.

## Error Handling

The main script uses `set -euo pipefail` to:
- Exit on any error (`-e`)
- Treat unset variables as errors (`-u`)
- Fail on pipe errors (`-o pipefail`)

If any module fails, the entire setup stops, preventing partial configurations.

## Update Script

All modules can contribute to the `~/.local/bin/update-all` script using the `append_to_updater()` function. This creates a centralized update mechanism for:

- System packages (DNF)
- Firmware updates
- Flatpak applications
- Toolbox packages
- Android SDK tools
- Kubectl krew plugins

## Migration from Original Script

The original `setup.sh` has been reorganized but maintains the same functionality:

- All original features preserved
- Same user prompts
- Same installation order
- Same configurations
- Added colored output and progress indicators

## Contributing

When contributing new modules:
1. Use numbered prefix (10, 20, 30, etc.) for execution order
2. Add descriptive comments
3. Use shared functions from `lib/functions.sh`
4. Include print_section() for visibility
5. Test syntax with `bash -n module.sh`
6. Document any new environment variables

## Support

For issues or questions about the modular structure, refer to:
- Individual module comments
- `lib/functions.sh` for available utilities
- Original repository: https://github.com/gjpin/fedora-workstation