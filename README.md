# mpb_scripts

Linux shell scripts for system automation and maintenance.

## Repository Structure

```
mpb_scripts/
├── src/                      # Shell scripts
│   ├── system_update.sh      # Comprehensive package management (monolithic version)
│   ├── system_summary.sh     # System information summary and diagnostics
│   └── system_update/        # Modular system_update (refactored version)
│       ├── system_update.sh  # Main orchestrator script
│       ├── lib/              # Package manager modules
│       │   ├── core_lib.sh
│       │   ├── apt_manager.sh
│       │   ├── pacman_manager.sh
│       │   ├── dpkg_manager.sh
│       │   ├── snap_manager.sh
│       │   ├── cargo_manager.sh
│       │   ├── pip_manager.sh
│       │   ├── npm_manager.sh
│       │   └── app_managers.sh
│       ├── README.md         # Modular architecture documentation
│       ├── ARCHITECTURE.md   # Visual architecture diagrams
│       └── REFACTORING_SUMMARY.md
├── docs/                     # Technical documentation
│   └── system_update_technical_specification.md
├── prompts/                  # Workflow and prompt files
│   └── tests_documentation_update_enhanced.txt
├── LICENSE                   # MIT License
└── README.md                 # This file
```

## Scripts

### system_update.sh

Comprehensive package management and system update script that automates package updates across multiple package managers.

**Available Versions:**
- **Monolithic** (`src/system_update.sh`): Single-file version (v0.3.0) - stable, production-ready
- **Modular** (`src/system_update/`): Refactored architecture (v0.4.0) - improved maintainability

**Features:**
- Multi-package-manager support (apt, pacman, snap, cargo, pip, npm)
- Cross-platform support (Debian/Ubuntu with APT, Arch Linux with Pacman)
- Interactive and quiet modes
- Intelligent handling of kept back packages
- Comprehensive package listing and statistics
- GitHub Copilot CLI automatic updates
- Calibre update checking
- Detailed error analysis and recovery suggestions
- Progress tracking and user confirmation options
- Modular architecture with high cohesion and loose coupling (modular version)

**Usage:**
```bash
# Monolithic version
./src/system_update.sh [OPTIONS]

# Modular version
./src/system_update/system_update.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  -s, --simple            Simple mode (skip cleanup)
  -f, --full              Full upgrade mode (includes system_summary.sh and dist-upgrade)
  -c, --cleanup           Cleanup only mode
  -l, --list              List all installed packages across all package managers
  --list-detailed         Show detailed package information
  -q, --quiet             Quiet mode (no prompts)
```

**Dependencies:**
- sudo privileges for system package operations
- Various package managers (detected automatically): apt or pacman (base system), snap, cargo, pip, npm
- Network connectivity for package updates
- Node.js and npm (for GitHub Copilot CLI updates)

**Modular Architecture Benefits:**
- High cohesion: Each module has a single, well-defined responsibility
- Loose coupling: Modules are independent and testable
- Easy to maintain: 42-560 lines per module vs. 2,606 lines in monolithic version
- Reusable: Individual modules can be sourced in other scripts
- Extensible: Add new package managers without modifying existing code

See [src/system_update/README.md](src/system_update/README.md) for detailed modular architecture documentation.

### system_summary.sh

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
./src/system_summary.sh
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
./src/system_summary.sh
```

## Documentation

### Technical Specifications

The repository includes comprehensive technical documentation in the `docs/` directory:

- **[system_update_technical_specification.md](docs/system_update_technical_specification.md)**: Complete technical specification for the system_update.sh script, including functional requirements, non-functional requirements, architecture specifications, and quality assurance procedures.
- **[system_update_design_document.md](docs/system_update_design_document.md)**: Architectural design document describing implementation strategy, modular architecture, component relationships, and design patterns.

## Development

This repository was created primarily using GitHub Copilot prompts to generate and maintain the code.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

mpb - [GitHub](https://github.com/mpbarbosa)
