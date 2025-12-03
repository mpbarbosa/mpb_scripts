# mpb_scripts

Linux shell scripts for system automation and maintenance.

## Repository Structure

```
mpb_scripts/
├── src/                      # Shell scripts
│   ├── system_update.sh      # Wrapper script (launches system_update/system_update.sh)
│   └── system_update/        # Modular system_update
│       ├── system_summary.sh # System information summary and diagnostics
│       ├── system_update.sh  # Main orchestrator script
│       ├── lib/              # Core package manager modules
│       │   ├── core_lib.sh
│       │   ├── apt_manager.sh
│       │   ├── pacman_manager.sh
│       │   ├── dpkg_manager.sh
│       │   ├── app_managers.sh
│       │   └── upgrade_utils.sh
│       ├── upgrade_snippets/ # Optional upgrade modules
│       │   ├── snap_manager.sh
│       │   ├── cargo_manager.sh
│       │   ├── pip_manager.sh
│       │   ├── npm_manager.sh
│       │   ├── check_calibre_update.sh
│       │   ├── calibre.yaml
│       │   ├── check_kitty_update.sh
│       │   ├── kitty.yaml
│       │   ├── check_vscode_insiders_update.sh
│       │   ├── vscode_insiders.yaml
│       │   ├── update_github_copilot_cli.sh
│       │   ├── github_copilot_cli.yaml
│       │   ├── update_google_chrome.sh
│       │   ├── google_chrome.yaml
│       │   ├── update_postman.sh
│       │   ├── postman.yaml
│       │   ├── update_tmux.sh
│       │   ├── tmux.yaml
│       │   ├── update_bash.sh
│       │   ├── bash.yaml
│       │   ├── update_nodejs.sh
│       │   ├── nodejs.yaml
│       │   ├── update_nodejs_app.sh
│       │   ├── nodejs_app.yaml
│       │   ├── update_npm.sh
│       │   ├── npm.yaml
│       │   ├── update_oh_my_bash.sh
│       │   ├── oh_my_bash.yaml
│       │   ├── README_nodejs.md
│       │   ├── README_nodejs_app.md
│       │   ├── README_google_chrome.md
│       │   ├── QUICK_REFERENCE.md
│       │   └── examples/
│       ├── README.md         # Modular architecture documentation
│       ├── ARCHITECTURE.md   # Visual architecture diagrams
│       ├── REFACTORING_SUMMARY.md
│       └── PROJECT_SUMMARY.txt
├── docs/                     # Technical documentation
│   ├── system_update_design_document.md
│   ├── system_update_technical_specification.md
│   └── upgrade_script_pattern_documentation.md
├── prompts/                  # Workflow and prompt files
├── LICENSE                   # MIT License
└── README.md                 # This file
```

## Scripts

### system_update.sh

Comprehensive package management and system update script that automates package updates across multiple package managers.

**Features:**
- Multi-package-manager support (apt, pacman)
- Optional package manager support via upgrade snippets (snap, cargo, pip, npm)
- Cross-platform support (Debian/Ubuntu with APT, Arch Linux with Pacman)
- Interactive and quiet modes
- Intelligent handling of kept back packages
- Comprehensive package listing and statistics
- Optional application update checks (GitHub Copilot CLI, Google Chrome, Postman, Calibre, Kitty, VS Code Insiders, Bash, Node.js, npm, Oh-My-Bash, tmux)
- Detailed error analysis and recovery suggestions
- Progress tracking and user confirmation options
- Modular architecture with high cohesion and loose coupling

**Usage:**
```bash
./src/system_update/system_update.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  -s, --simple            Simple mode (skip cleanup)
  -f, --full              Full upgrade mode (includes system_update/system_summary.sh and dist-upgrade)
  -c, --cleanup           Cleanup only mode
  -l, --list              List all installed packages across all package managers
  --list-detailed         Show detailed package information
  -q, --quiet             Quiet mode (no prompts)
```

**Dependencies:**
- sudo privileges for system package operations
- Core package managers (detected automatically): apt or pacman
- Optional package managers (via upgrade_snippets): snap, cargo, pip, npm
- Network connectivity for package updates

**Modular Architecture:**
- **Core modules** (`lib/`): Essential package managers and utilities
- **Upgrade snippets** (`upgrade_snippets/`): Optional, dynamically loaded upgrade modules
- High cohesion: Each module has a single, well-defined responsibility
- Loose coupling: Modules are independent and testable
- Extensible: Add new functionality by dropping scripts into upgrade_snippets/

See [src/system_update/README.md](src/system_update/README.md) for detailed modular architecture documentation.

### system_update/system_summary.sh

System information summary script that provides a comprehensive overview of system details.

**Features:**
- Operating system and distribution information
- Storage and file system analysis
- Memory and system resources monitoring
- Network configuration display
- Multi-package-manager statistics (apt, snap, pip, npm, cargo)
- Formatted table output for enhanced readability
- System environment and PATH information
- Interactive continuation prompts to control output scrolling

**Usage:**
```bash
./src/system_update/system_summary.sh
```

**Dependencies:**
- Standard Linux utilities (df, free, ip, etc.)
- Optional: lsb_release for detailed distribution information

## Dependencies

**Required:**
- Bash shell
- Standard Linux utilities

**Optional (for full functionality):**
- apt (Debian/Ubuntu package manager) OR pacman (Arch Linux package manager)
- snap (Snap package manager)
- cargo (Rust package manager)
- pip3 (Python package manager)
- npm (Node.js package manager)
- sudo privileges (for system_update.sh)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/mpbarbosa/mpb_scripts.git
cd mpb_scripts
```

2. Make scripts executable:
```bash
chmod +x src/*.sh
```

3. Run the scripts:
```bash
./src/system_update.sh
./src/system_update/system_summary.sh
```

## Documentation

### Technical Specifications

The repository includes comprehensive technical documentation in the `docs/` directory:

- **[system_update_technical_specification.md](docs/system_update_technical_specification.md)**: Complete technical specification for the system_update.sh script, including functional requirements, non-functional requirements, architecture specifications, and quality assurance procedures.
- **[system_update_design_document.md](docs/system_update_design_document.md)**: Architectural design document describing implementation strategy, modular architecture, component relationships, and design patterns.
- **[upgrade_script_pattern_documentation.md](docs/upgrade_script_pattern_documentation.md)**: Comprehensive documentation for the standardized upgrade script pattern used across all application update scripts (v1.1.0).

### Upgrade Script Pattern

All application-specific update scripts in `src/system_update/upgrade_snippets/` follow a standardized pattern (v1.1.0) that ensures consistency, maintainability, and code reusability:

**Pattern Features:**
- **Config-driven**: All configuration externalized to YAML files
- **Reusable library functions**: Common update logic centralized in `upgrade_utils.sh`
- **Three implementation methods**: 
  - Method 1: Standard Pattern (config + library)
  - Method 2: Installer Script Pattern (shell/deb installers)
  - Method 3: Custom Update Logic (complex workflows)
- **Consistent structure**: Version headers, error handling, user prompts
- **Alpha versioning**: All scripts currently in non-production alpha status

**Current Implementations:**
- `update_github_copilot_cli.sh` - Method 1 (npm-based)
- `update_npm.sh` - Method 1 (npm-based)
- `update_google_chrome.sh` - Method 1 (apt-based)
- `check_kitty_update.sh` - Method 2 (shell installer)
- `check_calibre_update.sh` - Method 2 (shell installer)
- `check_vscode_insiders_update.sh` - Method 2 (.deb package)
- `update_postman.sh` - Method 3 (snap/tarball with auto-detection)
- `update_tmux.sh` - Method 3 (build from source)
- `update_bash.sh` - Method 3 (git-based source build)
- `update_nodejs.sh` - Method 3 (multi-method: version managers, binaries, source)
- `update_nodejs_app.sh` - Method 3 (git pull + npm workflow)
- `update_oh_my_bash.sh` - Method 3 (git commit-based update)

See [upgrade_script_pattern_documentation.md](docs/upgrade_script_pattern_documentation.md) for complete pattern specification and implementation guidelines.

## Development

This repository was created primarily using GitHub Copilot prompts to generate and maintain the code.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

mpb - [GitHub](https://github.com/mpbarbosa)
