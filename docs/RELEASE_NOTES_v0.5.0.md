# 🚀 Release v0.5.0 - Node.js & Shell Tooling Suite

**Release Date:** November 28, 2025  
**System Update Version:** 0.5.0  
**Upgrade Pattern Version:** 1.1.0

## 🎯 Overview

This release significantly expands the upgrade scripts collection with comprehensive support for Node.js ecosystem and shell environment updates. All new scripts follow the standardized upgrade script pattern v1.1.0 with config-driven architecture.

---

## ✨ New Features

### 🟢 Node.js Ecosystem Support

#### `update_nodejs.sh` - Node.js Runtime Manager
**Version:** 1.0.0-alpha

A sophisticated Node.js runtime update manager supporting multiple installation methods:

- **Version Managers**: Auto-detects and uses nvm, n, or fnm
- **Official Binaries**: Fast installation without compilation (1-2 minutes)
- **Build from Source**: Full control with optimized parallel builds (20-60 minutes)
- **Package Manager**: System package manager fallback (apt, dnf, pacman)

**Key Features:**
- Multi-architecture support (x64, arm64, armv7l)
- Intelligent version manager detection
- GitHub API version checking
- Optimized source builds with multi-core support
- Comprehensive documentation

**Documentation:** [`README_nodejs.md`](src/system_update/upgrade_snippets/README_nodejs.md)

---

#### `update_nodejs_app.sh` - Node.js Application Updater
**Version:** 1.0.0-alpha

Generic template for updating any Node.js application from source code:

- Git pull workflow automation
- Dependency management (npm ci/install)
- Build step execution
- Service restart support (systemd, pm2, docker-compose)
- Version tracking from package.json or git tags

**Supported Frameworks:**
- Express.js
- Next.js
- Any Node.js application with package.json

**Configuration Examples:**
- Express API: [`nodejs_app_express_example.yaml`](src/system_update/upgrade_snippets/examples/nodejs_app_express_example.yaml)
- Next.js App: [`nodejs_app_nextjs_example.yaml`](src/system_update/upgrade_snippets/examples/nodejs_app_nextjs_example.yaml)

**Documentation:** [`README_nodejs_app.md`](src/system_update/upgrade_snippets/README_nodejs_app.md)

---

#### `update_npm.sh` - npm Package Manager Updater
**Version:** 1.0.0-alpha

Simple and efficient npm version updater using the direct command pattern:

- Updates npm to latest stable version
- Requires Node.js (bundled with Node.js installations)
- Uses `npm install -g npm@latest`

---

### 🐚 Shell Environment Support

#### `update_bash.sh` - Bash Shell Updater
**Version:** 1.1.0-alpha

Professional Bash shell update manager with source build capabilities:

- **Git-based versioning**: Uses official GNU Bash repository
- **Source builds**: Clone, configure, compile, install workflow
- **Tag-based versions**: Tracks official Bash releases
- **Optional testing**: Make test suite execution
- **Package manager fallback**: Attempts system package manager first

**Build Process:**
1. Clones from `git://git.savannah.gnu.org/bash.git`
2. Runs autoconf to generate configure script
3. Configures with `--prefix=/usr/local`
4. Builds with make
5. Optional: Runs test suite
6. Installs to `/usr/local/bin/bash`

---

#### `update_oh_my_bash.sh` - Oh-My-Bash Framework Updater
**Version:** 1.0.0-alpha

Oh-My-Bash framework updater with Git commit-based version tracking:

- **Git commit tracking**: Compares local vs remote commits
- **Smart updates**: Only updates when changes available
- **Safe operations**: Validates Git repository integrity
- **Auto-fetch**: Pulls latest changes from master branch

---

## 📚 Documentation

### New Documentation Files

1. **[`README_nodejs.md`](src/system_update/upgrade_snippets/README_nodejs.md)** (434 lines)
   - Comprehensive Node.js runtime update guide
   - Detailed method comparisons
   - Performance benchmarks
   - Troubleshooting section
   - Version manager installation guides

2. **[`README_nodejs_app.md`](src/system_update/upgrade_snippets/README_nodejs_app.md)** (287 lines)
   - Node.js application update guide
   - Configuration examples for popular frameworks
   - Service integration patterns
   - Advanced usage scenarios

3. **[`QUICK_REFERENCE.md`](src/system_update/upgrade_snippets/QUICK_REFERENCE.md)** (147 lines)
   - Quick reference distinguishing runtime vs app updates
   - Fast setup instructions
   - Common use cases

### Configuration Examples

Added 4 example configurations in `examples/`:

- **`nodejs_lts_example.yaml`**: LTS version pinning
- **`nodejs_dev_example.yaml`**: Development version setup
- **`nodejs_app_express_example.yaml`**: Express.js API configuration
- **`nodejs_app_nextjs_example.yaml`**: Next.js application configuration

---

## 🔧 Improvements

### Enhanced Error Handling
- **`dpkg_manager.sh`**: Improved broken package count handling
  - Fixed potential command substitution errors
  - Added fallback value assignment
  - More robust error detection

### Updated Documentation
- **`README.md`**: Complete upgrade snippets listing
  - Added all 5 new scripts
  - Updated feature list
  - Expanded implementation examples

### Version Management
- **`system_update.sh`**: Version bumped to 0.5.0
- **Repository references**: All URLs updated to `mpb_scripts`

---

## 📦 Configuration Files

All new scripts include corresponding YAML configuration files:

- `bash.yaml` (119 lines) - Bash update configuration
- `nodejs.yaml` (150 lines) - Node.js runtime configuration
- `nodejs_app.yaml` (114 lines) - Node.js application template
- `npm.yaml` (51 lines) - npm configuration
- `oh_my_bash.yaml` (84 lines) - Oh-My-Bash configuration

**Total Configuration:** 518 lines of externalized YAML configuration

---

## 📊 Statistics

### Code Metrics
- **Files Changed:** 22
- **Insertions:** 2,980 lines
- **Deletions:** 7 lines
- **Net Addition:** 2,973 lines

### Script Breakdown
| Script | Lines | Method | Status |
|--------|-------|--------|--------|
| `update_bash.sh` | 357 | Method 3 | Alpha |
| `update_nodejs.sh` | 344 | Method 3 | Alpha |
| `update_nodejs_app.sh` | 182 | Method 3 | Alpha |
| `update_npm.sh` | 74 | Method 1 | Alpha |
| `update_oh_my_bash.sh` | 251 | Method 3 | Alpha |

**Total Script Code:** 1,208 lines

---

## 🏗️ Architecture

All scripts follow the **Upgrade Script Pattern v1.1.0**:

### Design Principles
- ✅ **Config-Driven**: All configuration externalized to YAML
- ✅ **Reusable Libraries**: Common functions in `upgrade_utils.sh`
- ✅ **Consistent Structure**: Uniform version headers and error handling
- ✅ **Three Implementation Methods**: Support for different update patterns
- ✅ **Alpha Versioning**: Non-production status clearly marked

### Implementation Methods Used

**Method 1: Direct Command Update**
- `update_npm.sh` - Simple npm command execution

**Method 3: Custom Update Logic**
- `update_bash.sh` - Git-based source builds
- `update_nodejs.sh` - Multi-method selection (nvm/binary/source)
- `update_nodejs_app.sh` - Git pull + npm workflow
- `update_oh_my_bash.sh` - Git commit tracking

---

## 🔄 Complete Upgrade Scripts Collection

After this release, the repository includes **10 upgrade scripts**:

### Package Managers
- ✅ `snap_manager.sh`
- ✅ `cargo_manager.sh`
- ✅ `pip_manager.sh`
- ✅ `npm_manager.sh`
- ✅ **`update_npm.sh`** (new)

### Applications
- ✅ `check_calibre_update.sh`
- ✅ `check_kitty_update.sh`
- ✅ `check_vscode_insiders_update.sh`
- ✅ `update_github_copilot_cli.sh`
- ✅ `update_tmux.sh`
- ✅ **`update_nodejs_app.sh`** (new - template)

### Development Tools & Shells
- ✅ **`update_bash.sh`** (new)
- ✅ **`update_nodejs.sh`** (new)
- ✅ **`update_oh_my_bash.sh`** (new)

---

## 🚀 Getting Started

### Quick Installation

```bash
# Clone repository
git clone https://github.com/mpbarbosa/mpb_scripts.git
cd mpb_scripts

# Make scripts executable (if needed)
chmod +x src/system_update/upgrade_snippets/*.sh

# Run system update
./src/system_update.sh
```

### Using Individual Scripts

#### Update Node.js Runtime
```bash
./src/system_update/upgrade_snippets/update_nodejs.sh

# Choose method:
# v = version manager (nvm/n/fnm)
# b = binary (fast, recommended)
# s = source (slow, 20-60 min)
# p = package manager
```

#### Update Node.js Application
```bash
# 1. Configure your app in nodejs_app.yaml
# 2. Run updater
./src/system_update/upgrade_snippets/update_nodejs_app.sh
```

#### Update Bash Shell
```bash
./src/system_update/upgrade_snippets/update_bash.sh

# Options:
# p = package manager (fast)
# s = source build (compile from git)
```

---

## 📖 Documentation References

- **[Upgrade Script Pattern Documentation](docs/upgrade_script_pattern_documentation.md)** - v1.1.0
- **[System Update Design Document](docs/system_update_design_document.md)**
- **[System Update Technical Specification](docs/system_update_technical_specification.md)**

---

## 🔍 Dependencies

### Required
- Bash shell
- Standard Linux utilities

### Optional (Based on Scripts Used)

**For Node.js Scripts:**
- git (for source builds and app updates)
- npm (bundled with Node.js)
- Node.js v18+ (for applications)

**For Bash Update:**
- git, autoconf, bison, gcc/clang, make, libncurses-dev

**For Oh-My-Bash:**
- git

---

## ⚠️ Important Notes

### Alpha Status
All new scripts are marked as **alpha** (non-production):
- Thoroughly tested but not production-ready
- Configuration may change
- Feedback and contributions welcome

### Version Managers
If using Node.js version managers (nvm, n, fnm):
- Ensure they're properly installed before running `update_nodejs.sh`
- Scripts will auto-detect and offer appropriate options

### Source Builds
Building from source requires:
- Significant disk space (~2GB for Node.js)
- Time commitment (20-60 minutes for Node.js)
- Build dependencies installed

---

## 🐛 Bug Fixes

- **dpkg_manager.sh**: Fixed potential error in broken package count detection
  - Changed from `|| echo 0` to `${broken_count:-0}` pattern
  - More robust error handling

---

## 🔜 Future Enhancements

Potential features for upcoming releases:
- Python version manager support (pyenv)
- Ruby version manager support (rbenv, rvm)
- Go version manager support
- Additional Node.js application templates
- Automated testing framework
- CI/CD integration examples

---

## 📝 Upgrade Path

### From v0.1.0-alpha to v0.5.0

**Breaking Changes:** None

**New Features:**
- 5 new upgrade scripts
- Expanded documentation
- Configuration examples

**Action Required:**
```bash
git pull origin main
git checkout v0.5.0
```

No configuration changes needed for existing scripts.

---

## 🤝 Contributing

This repository was created primarily using GitHub Copilot. Contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Follow the upgrade script pattern v1.1.0
4. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 👤 Author

**mpb** - [GitHub](https://github.com/mpbarbosa)

---

## 🙏 Acknowledgments

- GNU Bash Project
- Node.js Foundation
- Oh-My-Bash contributors
- npm team
- All open-source tool maintainers

---

## 📞 Support

For issues, questions, or suggestions:
- **Issues:** [GitHub Issues](https://github.com/mpbarbosa/mpb_scripts/issues)
- **Discussions:** [GitHub Discussions](https://github.com/mpbarbosa/mpb_scripts/discussions)

---

**Full Changelog:** [v0.1.0-alpha...v0.5.0](https://github.com/mpbarbosa/mpb_scripts/compare/v0.1.0-alpha...v0.5.0)
