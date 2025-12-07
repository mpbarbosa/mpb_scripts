# Release Notes - v0.7.0

**Release Date**: 2025-12-07  
**Repository**: https://github.com/mpbarbosa/mpb_scripts

## 🎯 Overview

Version 0.7.0 introduces AWS CLI update support, enhanced version comparison, improved pip package management, better APT error handling, and various bug fixes and improvements across the system update tooling.

## ✨ New Features

### AWS CLI Update Support
- **New Script**: `update_awscli.sh` - AWS CLI v2 update manager
- **Configuration**: `awscli.yaml` - Config-driven AWS CLI update settings
- **Method**: Custom installer pattern with GitHub API version detection
- **Features**:
  - Automatic version checking against AWS GitHub releases
  - Clean installer download and installation
  - Update support for existing AWS CLI installations
  - Proper cleanup of temporary files
  - Integration with upgrade_utils library

## 🔧 Enhancements

### Core Library Improvements (`core_lib.sh` v0.5.0)
- **Enhanced Version Comparison**: Added `dpkg --compare-versions` support for more accurate Debian package version comparisons
- **Improved Version Parsing**: Better handling of version strings with alphabetic suffixes (e.g., `2.0.1rc1`)
- **Fallback Mechanism**: Maintains custom comparison logic when dpkg is unavailable
- **Better Edge Cases**: Improved handling of complex version formats

### APT Manager Improvements (`apt_manager.sh` v0.4.3)
- **Better 404 Error Detection**: Improved parsing of repository 404 errors
- **Enhanced URL Extraction**: More precise URL extraction from apt-get update output
- **Cross-Format Compatibility**: Works with both `.list` and `.sources` repository file formats
- **Improved Comments**: Added detailed documentation explaining the 404 error handling logic
- **User Prompts**: Better user interaction when broken repositories are detected

### Pip Package Manager Improvements (`pip_manager.sh` v0.5.0)
- **User-Only Updates**: Changed to `pip3 list --outdated --user` to avoid system package conflicts
- **Safer Management**: Prevents conflicts with apt-managed Python packages
- **Clearer Messaging**: Updated user feedback to indicate user package focus
- **Removed Exclusions**: Simplified logic by focusing on user-installed packages only

### Upgrade Utilities Enhancements (`upgrade_utils.sh`)
- **Version Detection**: Enhanced version detection functions for various package types
- **Error Handling**: Improved error messages and recovery suggestions
- **Library Functions**: Additional helper functions for common update patterns

## 🐛 Bug Fixes

### ARCHITECTURE.md
- **Fixed Typo**: Removed stray "t " character from markdown header
- **Impact**: Minor formatting correction for proper documentation rendering

### System Summary (`system_summary.sh`)
- **Code Quality**: Various improvements and consistency fixes
- **Output Formatting**: Enhanced table formatting and display

### Google Chrome Update Script (`update_google_chrome.sh`)
- **Refinements**: Minor improvements to update detection and handling

### Postman Update Script (`update_postman.sh`)
- **Enhancements**: Improved update logic and error handling

### Tmux Update Script (`update_tmux.sh`)
- **Improvements**: Enhanced build-from-source workflow
- **YAML Config** (`tmux.yaml`): Updated configuration parameters

### Calibre YAML (`calibre.yaml`)
- **Config Updates**: Refined configuration settings

### README Documentation (`README_google_chrome.md`)
- **Documentation**: Updated documentation for Google Chrome update script

## 📋 Version Updates

| Component | Previous Version | New Version |
|-----------|-----------------|-------------|
| `core_lib.sh` | 0.4.0 | 0.5.0 |
| `apt_manager.sh` | 0.4.2 | 0.4.3 |
| `pip_manager.sh` | 0.4.2 | 0.5.0 |
| `update_awscli.sh` | - | 0.1.0-alpha |
| `awscli.yaml` | - | 0.1.0-alpha |

## 📚 Documentation Updates

### Main README.md
- Added AWS CLI to the repository structure diagram
- Added AWS CLI to the list of optional application updates
- Added `update_awscli.sh` to Current Implementations section (Method 1)

### Configuration Files
- **New**: `awscli.yaml` - Complete configuration for AWS CLI updates including:
  - Application identifiers
  - Dependency requirements (curl, unzip)
  - User messages and installation instructions
  - Version extraction patterns
  - Update method configuration

## 🔍 Technical Details

### Version Comparison Algorithm Improvements

The enhanced `compare_versions()` function in `core_lib.sh` now:

1. **First tries dpkg** (if available):
   ```bash
   dpkg --compare-versions "$version1" eq "$version2"
   ```

2. **Falls back to custom logic** with improved parsing:
   - Splits versions by dots
   - Extracts numeric and alphabetic parts separately
   - Compares numeric parts as integers
   - Compares alphabetic parts lexicographically
   - Handles missing version segments gracefully

### Pip Package Management Strategy

Changed from system-wide package checking with exclusions to user-only package management:

**Before**:
```bash
pip3 list --outdated | grep -vE "^(dbus-python|PyGObject|distro-info|python-apt)"
```

**After**:
```bash
pip3 list --outdated --user
```

**Benefits**:
- No conflicts with apt-managed Python packages
- Simpler logic, easier to maintain
- Clearer user messaging
- Safer system package management

### APT 404 Error Handling

Improved repository error detection with enhanced URL extraction:

```bash
# Extract only the URL portion (up to first space after URL)
# This ensures compatibility with both .list and .sources file formats
match(prev, /https?:\/\/[^ ]+/)
```

## 🎨 Upgrade Script Pattern Compliance

The new `update_awscli.sh` follows the established **Upgrade Script Pattern v1.1.0**:

- ✅ Config-driven design with `awscli.yaml`
- ✅ Uses `upgrade_utils.sh` library functions
- ✅ Implements Method 1 (Standard Pattern)
- ✅ Proper version header with alpha status
- ✅ Consistent error handling
- ✅ User-friendly prompts and messages
- ✅ Clean temporary file management

## 🔐 Dependencies

### New Dependencies (for AWS CLI)
- `curl` - Required for downloading AWS CLI installer
- `unzip` - Required for extracting AWS CLI installer package
- `sudo` - Required for system-wide AWS CLI installation

### Existing Dependencies
- Bash shell
- Standard Linux utilities
- Optional: apt, snap, cargo, pip, npm (as applicable)

## 🚀 Migration Notes

### For Users
1. **No Breaking Changes**: All existing functionality remains intact
2. **New Feature**: AWS CLI updates now available via `update_awscli.sh`
3. **Pip Updates**: Now focuses on user-installed packages only (safer)
4. **APT Handling**: Better 404 error detection and recovery

### For Developers
1. **Version Comparison**: New dpkg-based comparison available in `core_lib.sh`
2. **Pip Integration**: Update any pip-related scripts to use `--user` flag
3. **APT Error Parsing**: Reference improved URL extraction logic in `apt_manager.sh`

## 📊 Statistics

- **Files Modified**: 12
- **Files Added**: 2
- **Total Lines Changed**: ~250+ (additions and improvements)
- **New Upgrade Scripts**: 1 (AWS CLI)
- **Version Bumps**: 3 modules

## 🔗 References

- [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [dpkg Version Comparison](https://man7.org/linux/man-pages/man1/dpkg.1.html)
- [pip User Installs](https://pip.pypa.io/en/stable/user_guide/#user-installs)

## 🎯 Next Steps

Potential future improvements:
- Add more application update scripts
- Enhance test coverage
- Improve error recovery mechanisms
- Add support for more package managers

---

**Contributors**: mpb  
**License**: MIT
