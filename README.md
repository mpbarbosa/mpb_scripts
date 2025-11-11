# mpb_scripts

Linux shell scripts for system automation and maintenance.

## Repository Structure

```
mpb_scripts/
├── src/                      # Shell scripts
│   ├── system_update.sh      # Comprehensive package management and system updates
│   └── system_summary.sh     # System information summary and diagnostics
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

**Usage:**
```bash
./src/system_update.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -v, --version           Show version information
  -s, --stop              Stop before each major operation (interactive mode)
  -f, --full              Full upgrade mode (includes system_summary.sh and dist-upgrade)
  -c, --cleanup-only      Only run cleanup operations
  -l, --list              List all installed packages across all package managers
  --list-detailed         Show detailed package information
  -q, --quiet             Suppress all output
```

**Dependencies:**
- sudo privileges for system package operations
- Various package managers (detected automatically): apt or pacman (base system), snap, cargo, pip, npm
- Network connectivity for package updates
- Node.js and npm (for GitHub Copilot CLI updates)

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
git clone https://github.com/mpbarbosa/scripts.git
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

## Development

This repository was created primarily using GitHub Copilot prompts to generate and maintain the code.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

mpb - [GitHub](https://github.com/mpbarbosa)
