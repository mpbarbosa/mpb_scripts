# Release v0.6.0 - Chrome, Postman & APT Package Manager Support

**Release Date:** December 3, 2025  
**Upgrade Pattern Version:** 1.2.0  
**Previous Version:** v0.5.0

## 🎯 Overview

This release adds Google Chrome and Postman upgrade scripts, introduces APT package manager support to the upgrade script pattern, and improves repository organization with better file structure.

---

## ✨ New Features

### 🌐 Browser & API Platform Support

#### `update_google_chrome.sh` - Google Chrome Update Manager
**Version:** 0.1.0-alpha

APT-based Chrome updater with automatic repository configuration:

- **Auto-Configuration**: Sets up Chrome repository if not present
- **Signing Key Management**: Automatically downloads and configures GPG key
- **Installation & Updates**: Handles both fresh install and updates
- **Method 1 Pattern**: Uses config-driven approach with upgrade_utils.sh

**Key Features:**
- Automatic repository setup (signing key + sources.list)
- Version detection from `google-chrome-stable --version`
- APT-based installation and updates
- Comprehensive error handling and recovery

**Files:**
- `update_google_chrome.sh` - Main update script
- `google_chrome.yaml` - Configuration file
- `README_google_chrome.md` - Documentation

**Reference:** [Google Chrome Admin Guide](https://support.google.com/chrome/a/answer/9025903)

---

#### `update_postman.sh` - Postman API Platform Updater
**Version:** 0.2.0-alpha

Hybrid updater supporting both snap and tarball installations:

- **Auto-Detection**: Detects snap or tarball installation method
- **Compatibility Check**: Identifies snap compatibility issues
- **Migration Support**: Automatically migrates from snap to tarball
- **Method 3 Pattern**: Custom update logic for complex scenarios

**Key Features:**
- Installation method detection (snap/tarball)
- Snap compatibility checking (GLIBC issues)
- Automated migration from snap to tarball
- Desktop entry creation
- Backup before updates

**Files:**
- `update_postman.sh` - Main update script
- `postman.yaml` - Configuration file

**Reference:** [Postman Installation Guide](https://learning.postman.com/docs/getting-started/installation/)

---

### 📦 Upgrade Pattern v1.2.0 - APT Package Manager Support

Enhanced upgrade script pattern with Debian/Ubuntu package manager support:

**New Features:**
- `get_apt_latest_version()` function in upgrade_utils.sh
- APT configuration schema in YAML files
- Support for apt-based version checking
- Repository configuration workflows

**YAML Schema Addition:**
```yaml
version:
  source: "apt"  # New option alongside "github" and "npm"
  package_name: "package-name"  # APT package name

update:
  method: "apt"
  pre_install_steps:  # Optional repository setup
    - action: "add_signing_key"
      command: "..."
    - action: "add_repository"
      command: "..."
  install_command: "sudo apt-get install -y package"
  update_command: "sudo apt-get install --only-upgrade -y package"
```

**Documentation:**
- Updated `upgrade_script_pattern_documentation.md` to v1.2.0
- Added APT configuration examples
- New implementation method for apt-based updates

---

## 🔧 Improvements

### Repository Organization
- **Moved `system_summary.sh`**: Relocated from `src/` to `src/system_update/`
- **Better Structure**: All system_update components now in same directory
- **Documentation Updates**: All references updated to new location

### Code Quality
- **Fixed VERBOSE Variable**: Corrected 12 instances of `$VEBOSE` to `${VERBOSE_MODE:-false}` in update_postman.sh
- **Standardized Headers**: All scripts now have complete version headers
- **Alpha Status**: Clear alpha versioning and production readiness disclaimers

### Documentation
- **README.md**: Updated with Chrome and Postman scripts
- **Pattern Documentation**: Version 1.2.0 with APT support
- **Comprehensive Guides**: Added README_google_chrome.md

---

## 📊 Current Script Collection

### Method 1: Standard Pattern (Config + Library)
- `update_github_copilot_cli.sh` - npm-based
- `update_npm.sh` - npm-based
- **`update_google_chrome.sh`** - **NEW: apt-based**

### Method 2: Installer Script Pattern
- `check_kitty_update.sh` - shell installer
- `check_calibre_update.sh` - shell installer
- `check_vscode_insiders_update.sh` - .deb package

### Method 3: Custom Update Logic
- **`update_postman.sh`** - **NEW: snap/tarball hybrid**
- `update_tmux.sh` - build from source
- `update_bash.sh` - git-based source build
- `update_nodejs.sh` - multi-method (nvm/n/fnm/binaries/source)
- `update_nodejs_app.sh` - git pull + npm workflow
- `update_oh_my_bash.sh` - git commit-based update

---

## 📝 Files Changed

**New Files (5):**
- `src/system_update/upgrade_snippets/update_google_chrome.sh`
- `src/system_update/upgrade_snippets/google_chrome.yaml`
- `src/system_update/upgrade_snippets/update_postman.sh`
- `src/system_update/upgrade_snippets/postman.yaml`
- `src/system_update/upgrade_snippets/README_google_chrome.md`

**Modified Files:**
- `README.md` - Added Chrome and Postman
- `docs/upgrade_script_pattern_documentation.md` - v1.2.0 with APT support
- `src/system_update/lib/upgrade_utils.sh` - Added `get_apt_latest_version()`
- `src/system_update/lib/apt_manager.sh` - Enhanced functionality

**Moved Files:**
- `src/system_summary.sh` → `src/system_update/system_summary.sh`

---

## 🔄 Upgrade Instructions

From v0.5.0 to v0.6.0:

```bash
# Pull latest changes
cd mpb_scripts
git pull origin main

# Checkout v0.6.0
git checkout v0.6.0

# Verify installation
./src/system_update/system_update.sh --version
```

**Note:** `system_summary.sh` path changed - update any custom scripts referencing it.

---

## 📚 Documentation

- [Upgrade Script Pattern v1.2.0](docs/upgrade_script_pattern_documentation.md)
- [Google Chrome Update Manager](src/system_update/upgrade_snippets/README_google_chrome.md)
- [System Update Architecture](src/system_update/ARCHITECTURE.md)

---

## ⚠️ Status

**Alpha Release** - All new scripts (v0.1.0-alpha, v0.2.0-alpha) are not production-ready:
- Extensive testing recommended
- Bug reports welcome
- Feedback appreciated

---

## 🙏 Acknowledgments

Scripts created with GitHub Copilot CLI assistance.

---

## 📋 Statistics

- **Total Shell Scripts:** 25
- **Upgrade Scripts:** 13
- **Configuration Files:** 13 YAML files
- **Documentation:** 3 README files in upgrade_snippets/
- **Lines Added:** ~1,500
- **Pattern Version:** 1.2.0

---

**Full Changelog:** [v0.5.0...v0.6.0](https://github.com/mpbarbosa/mpb_scripts/compare/v0.5.0...v0.6.0)
