# System Update - Modular Package Management System

Refactored version of the system_update.sh script following cohesion and coupling principles.

## Architecture

The modular system_update script is organized into focused, single-responsibility modules:

```
system_update/
├── system_update.sh          # Main orchestrator (coordinator only)
├── lib/                      # Core library modules
│   ├── core_lib.sh           # Core utilities & output formatting
│   ├── apt_manager.sh        # APT package manager operations
│   ├── pacman_manager.sh     # Pacman package manager operations
│   ├── dpkg_manager.sh       # DPKG maintenance operations
│   └── app_managers.sh       # Application updates & snippet loader
├── upgrade_snippets/         # Optional upgrade modules (dynamically loaded)
│   ├── snap_manager.sh       # Snap package operations
│   ├── cargo_manager.sh      # Rust/Cargo package operations
│   ├── pip_manager.sh        # Python pip package operations
│   ├── npm_manager.sh        # Node.js npm package operations
│   ├── check_calibre_update.sh         # Calibre update checker
│   ├── check_kitty_update.sh           # Kitty terminal update checker
│   ├── check_vscode_insiders_update.sh # VS Code Insiders update checker
│   └── update_github_copilot_cli.sh    # GitHub Copilot CLI updater
└── README.md                 # This file
```

## Benefits of Modular Design

### High Cohesion
- Each module has a **single, well-defined responsibility**
- `core_lib.sh` - only formatting and common utilities
- `apt_manager.sh` - only APT operations
- `app_managers.sh` - only application-specific updates

### Loose Coupling
- Modules are **independent** and can be tested separately
- Main script just **coordinates** module execution
- Easy to add/remove/replace package managers
- Library modules can be sourced individually if needed

### Maintainability
- ~200-400 lines per file instead of 2600 lines
- Easier to locate and fix bugs
- Clear separation of concerns
- Better code organization

### Extensibility Through Upgrade Snippets
- **Dynamic loading**: All scripts in `upgrade_snippets/` are automatically sourced
- **No code modification required**: Add new package managers by dropping files into the directory
- **Backward compatible**: Core functionality remains in `lib/` for stability
- **Optional dependencies**: Upgrade snippets only execute if their tools are available

## Usage

The main script maintains **100% backward compatibility** with the original:

```bash
# Basic usage (interactive mode)
./system_update.sh

# Quiet mode (no prompts)
./system_update.sh -q

# Full system upgrade
./system_update.sh -f

# List installed packages
./system_update.sh -l

# Cleanup only
./system_update.sh -c

# Show version
./system_update.sh -v

# Help
./system_update.sh -h
```

## Module Details

### core_lib.sh
- Color definitions
- Output formatting functions (`print_*`)
- Common utilities (`ask_continue`, `detect_package_manager`, `compare_versions`)

### apt_manager.sh
- `update_package_list()` - Update APT cache
- `check_unattended_upgrades()` - Configure automatic updates
- `check_updates_available()` - Check for available updates
- `upgrade_packages()` - Upgrade packages with kept-back handling (uses `apt upgrade`)
- `full_upgrade()` - Dist-upgrade operation
- `cleanup()` - Autoremove and autoclean
- `check_broken_packages()` - Fix broken packages

### pacman_manager.sh
- `update_pacman_database()` - Update package database
- `upgrade_pacman_packages()` - Upgrade packages
- `clean_pacman_cache()` - Clean package cache
- `remove_pacman_orphans()` - Remove orphaned packages
- `list_pacman_packages()` - List packages
- `check_pacman_config()` - Configuration checks

### dpkg_manager.sh
- `maintain_dpkg_packages()` - DPKG maintenance and status

### app_managers.sh
- `source_upgrade_snippets()` - Dynamically load all upgrade snippet modules
- `install_nodejs()` - Install Node.js via NVM
- `check_nodejs_update()` - Check for Node.js updates

## Upgrade Snippets

Optional modules in `upgrade_snippets/` that are automatically loaded if present:

### snap_manager.sh
- `update_snap_packages()` - Update Snap packages

### cargo_manager.sh
- `update_rustup_toolchain()` - Update rustup
- `update_rust_toolchains()` - Update Rust toolchains
- `update_cargo_packages()` - Update Cargo packages
- `update_rust_packages()` - Main entry point

### pip_manager.sh
- `update_pip_packages()` - Update Python packages

### npm_manager.sh
- `update_npm_packages()` - Update Node.js global packages

### check_kitty_update.sh
- `check_kitty_update()` - Update Kitty terminal

### check_calibre_update.sh
- `check_calibre_update()` - Update Calibre e-book manager

### check_vscode_insiders_update.sh
- `check_vscode_insiders_update()` - Update VS Code Insiders

### update_github_copilot_cli.sh
- `update_github_copilot_cli()` - Update GitHub Copilot CLI

## Design Principles Applied

### Single Responsibility Principle (SRP)
Each module handles one package manager or category of functionality.

### Open/Closed Principle
Easy to extend with new package managers by adding files to `upgrade_snippets/` without modifying existing code.

### Dependency Inversion
Main script depends on abstractions (sourced modules), not concrete implementations.

### High Cohesion
Functions within each module are strongly related and work together.

### Loose Coupling
Modules are independent; changes in one don't require changes in others.

## Testing

Individual modules can be tested by sourcing them:

```bash
# Test APT module functions
source lib/core_lib.sh
source lib/apt_manager.sh
QUIET_MODE=true
check_updates_available

# Test upgrade snippets
source lib/core_lib.sh
source lib/app_managers.sh
source_upgrade_snippets  # This loads all upgrade snippets
```

## Adding New Package Managers

To add a new package manager or upgrade feature:

1. Create a new script in `upgrade_snippets/` directory
2. Define your update functions using the naming convention from existing snippets
3. The script will be automatically loaded by `source_upgrade_snippets()` on next run
4. No modification to core scripts required

Example:
```bash
# upgrade_snippets/my_new_manager.sh
#!/bin/bash

update_my_package_manager() {
    print_operation_header "Checking My Package Manager updates..."
    # Your update logic here
}
```

## Migration Notes

The original monolithic `/src/system_update.sh` has been removed. This modular version:

1. Maintains all original functionality
2. Preserves all command-line options
3. Keeps the same user interface
4. Uses the same output formatting
5. Adds extensibility through the `upgrade_snippets/` directory

To use the modular version:

```bash
cd src/system_update
./system_update.sh
```

## Version

- **Version**: 0.5.0 (Modular with upgrade snippets)
- **Previous Version**: 0.4.1 (Modular)
- **Author**: mpb
- **Repository**: https://github.com/mpbarbosa/mpb_scripts
- **License**: MIT
