# Upgrade Script Pattern Documentation

**Version:** 1.0.0  
**Date:** 2025-11-24  
**Author:** mpb  
**Repository:** https://github.com/mpbarbosa/mpb_scripts

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Pattern Components](#pattern-components)
4. [File Structure](#file-structure)
5. [YAML Configuration Schema](#yaml-configuration-schema)
6. [Shell Script Structure](#shell-script-structure)
7. [Workflow](#workflow)
8. [Implementation Examples](#implementation-examples)
9. [Best Practices](#best-practices)
10. [Creating New Upgrade Scripts](#creating-new-upgrade-scripts)
11. [Advanced Features](#advanced-features)
12. [Troubleshooting](#troubleshooting)

---

## Overview

The **Upgrade Script Pattern** is a standardized, config-driven approach for creating modular, maintainable application update scripts. This pattern separates configuration from code logic, enabling:

- **Reusability**: Common functions centralized in shared libraries
- **Maintainability**: Configuration changes without code modifications
- **Consistency**: Uniform behavior across all upgrade scripts
- **Extensibility**: Easy addition of new applications
- **Versioning**: Independent tracking of configuration changes

### Key Principles

1. **Separation of Concerns**: Code logic vs. configuration data
2. **DRY (Don't Repeat Yourself)**: Shared functionality in libraries
3. **Config-Driven**: All strings, commands, and parameters externalized
4. **Semantic Versioning**: Track configuration evolution
5. **Zero Hardcoding**: Dynamic loading of all values

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Upgrade Script Pattern                   │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
    ┌─────────▼────────┐           ┌─────────▼────────┐
    │  Shell Script    │           │  YAML Config     │
    │  (Logic Layer)   │◄──────────┤  (Data Layer)    │
    └─────────┬────────┘           └──────────────────┘
              │
              │ sources
              │
    ┌─────────▼────────┐
    │  Shared Library  │
    │  upgrade_utils.sh│
    │  - get_config()  │
    │  - version_check │
    │  - utilities     │
    └──────────────────┘
```

### Layer Responsibilities

#### 1. **Shell Script Layer** (`update_*.sh`)

- Application-specific logic
- Workflow orchestration
- Custom update procedures
- Error handling

#### 2. **Configuration Layer** (`*.yaml`)

- Application identifiers
- Version extraction rules
- Messages and prompts
- Update commands
- Build instructions

#### 3. **Library Layer** (`upgrade_utils.sh`)

- Config parsing (`get_config()`)
- Version checking (`config_driven_version_check()`)
- GitHub API interactions
- NPM registry queries
- Common utilities

---

## Pattern Components

### Component Overview

```plaintext
upgrade_script_pattern/
├── Shell Script (update_app.sh)
│   ├── Load configuration
│   ├── Check dependencies
│   ├── Perform version check (via library)
│   └── Execute update workflow
│
├── YAML Config (app.yaml)
│   ├── Metadata (version, author, date)
│   ├── Application identifiers
│   ├── Version extraction rules
│   ├── Messages and prompts
│   └── Update commands
│
└── Shared Library (upgrade_utils.sh)
    ├── get_config() - YAML parser
    ├── config_driven_version_check() - Version workflow
    └── Utility functions
```

---

## File Structure

### Repository Layout

```plaintext
src/system_update/
├── lib/
│   └── upgrade_utils.sh              # Shared library
│
└── upgrade_snippets/
    ├── update_tmux.sh                # Tmux upgrade script
    ├── tmux.yaml                     # Tmux configuration
    ├── update_github_copilot_cli.sh  # Copilot upgrade script
    └── github_copilot_cli.yaml       # Copilot configuration
```

### File Naming Conventions

- **Shell Scripts**: `update_<application_name>.sh`
- **Config Files**: `<application_name>.yaml`
- **Library Files**: `<purpose>_utils.sh`

---

## YAML Configuration Schema

### Complete Schema

```yaml
# Metadata Section (Required)
# Version: <semver>-<stage>
# Date: YYYY-MM-DD
# Author: <author_name>
# Repository: <github_url>
# Status: Non-production (Alpha|Beta|RC) | Production

# Application Identifiers (Required)
application:
  name: "<cli_command>"              # Command name
  command: "<cli_command>"           # Executable command
  display_name: "<Human Name>"       # Optional: Display name
  npm_package: "<@scope/package>"    # Optional: For npm apps

# Dependencies (Optional)
dependencies:
  - name: "<dependency_name>"
    command: "<cli_command>"
    help: "<installation_instructions>"
    version: "<min_version>"         # Optional
    required: true|false             # Optional

# Messages (Required)
messages:
  checking_updates: "<checking_message>"
  install_help: |
    <multiline_installation_instructions>
  failed_version: "<error_message>"  # Or failed_get_version
  update_success: "<success_message>" # Optional

# Version Extraction (Required)
version:
  command: "<version_command>"       # e.g., "app --version"
  regex: '<extraction_regex>'        # Capture group 1 = version
  source: "github|npm"               # Version source
  github_owner: "<owner>"            # If source=github
  github_repo: "<repo>"              # If source=github

# Update Commands (Optional - for simple updates)
update:
  command: "<update_command>"
  output_lines: <number>             # Lines to display

# Prompts (Optional - for interactive scripts)
prompts:
  <prompt_name>:
    message: "<prompt_text>"
    options: "<option_format>"       # e.g., "y/n", "p/s"
    default: "<default_value>"
    type: "yes_no|choice"

# Build Instructions (Optional - for source builds)
build_instructions:
  dependencies:
    - <dependency1>
    - <dependency2>
  steps:
    - action: "<action_name>"
      command: "<command_string>"
  reference:
    url: "<documentation_url>"
```

### Schema Examples

#### Example 1: Simple NPM Package

```yaml
# Version: 0.1.0-alpha
# Date: 2025-11-24
# Author: mpb
# Status: Non-production (Alpha)

application:
  name: "copilot"
  display_name: "GitHub Copilot CLI"
  npm_package: "@github/copilot"

messages:
  checking_updates: "Checking GitHub Copilot CLI updates..."
  install_help: "Install: npm install -g @github/copilot"
  failed_version: "Failed to get current version"
  update_success: "GitHub Copilot CLI updated"

version:
  command: "copilot --version"
  regex: '.*@([0-9]+\.[0-9]+\.[0-9]+).*'
  source: "npm"

update:
  command: "npm install -g --force @github/copilot@latest"
  output_lines: 10
```

#### Example 2: GitHub Release with Complex Build

```yaml
# Version: 0.1.0-alpha
# Date: 2025-11-24
# Author: mpb
# Status: Non-production (Alpha)

application:
  name: "tmux"
  command: "tmux"

messages:
  checking_updates: "Checking tmux updates..."
  install_help: |
    Install via: apt install tmux, brew install tmux, or build from source
    Source: https://github.com/tmux/tmux
  failed_get_version: "Failed to get current tmux version"

version:
  command: "tmux -V"
  regex: 'tmux ([0-9]+\.[0-9]+[a-z]?).*'
  source: "github"
  github_owner: "tmux"
  github_repo: "tmux"

prompts:
  update_method:
    message: "Update method: (p)ackage manager or (s)ource build?"
    options: "p/s"
    default: "p"
  build_from_source:
    message: "Build from source instead?"
    type: "yes_no"

build_instructions:
  dependencies:
    - libevent-dev
    - ncurses-dev
    - build-essential
    - autoconf
    - automake
    - pkg-config
    - bison
  steps:
    - action: "Clone"
      command: "git clone https://github.com/tmux/tmux.git"
    - action: "Build"
      command: "cd tmux && sh autogen.sh && ./configure && make"
    - action: "Install"
      command: "sudo make install"
  reference:
    url: "https://github.com/tmux/tmux"
```

---

## Shell Script Structure

### Minimal Script Template

```bash
#!/bin/bash
#
# update_<app>.sh - <App Name> Update Manager
#
# Handles version checking and updates for <application>.
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/<app>.yaml"

update_<app>() {
    # Perform config-driven version check
    if ! config_driven_version_check; then
        return 0
    fi
    
    # Handle update workflow
    local update_cmd
    update_cmd=$(get_config "update.command")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "$update_cmd 2>&1 | tail -$output_lines && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        ask_continue
        return 1
    fi
}

update_<app>
```

### Script Components Explained

#### 1. Header Section

```bash
#!/bin/bash
#
# update_<app>.sh - <App Name> Update Manager
#
# Handles version checking and updates for <application>.
# Reference: <documentation_url>  # Optional
#
# Dependencies:  # Optional
#   - <dep1>
#   - <dep2>
#
```

#### 2. Library Loading

```bash
# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"
```

**Purpose**: 

- Dynamically locate the library directory
- Source shared utilities
- Enable access to `get_config()` and `config_driven_version_check()`

#### 3. Configuration Loading

```bash
# Load configuration
CONFIG_FILE="$SCRIPT_DIR/<app>.yaml"
```

**Purpose**:

- Set the configuration file path
- Used by `get_config()` and `config_driven_version_check()`

#### 4. Main Update Function

```bash
update_<app>() {
    # 1. Optional: Check additional dependencies
    # 2. Perform version check (automatic)
    # 3. Handle update workflow (custom logic)
}
```

#### 5. Function Invocation

```bash
update_<app>
```

**Purpose**: Execute the main function when script is run

---

## Workflow

### Complete Update Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                  Script Execution Starts                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Load Libraries & Configuration                          │
│     - Source upgrade_utils.sh                               │
│     - Set CONFIG_FILE path                                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Check Additional Dependencies (Optional)                │
│     - Verify npm, specific tools, etc.                      │
│     - Exit if missing                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  3. config_driven_version_check()                           │
│     ┌─────────────────────────────────────────────────────┐ │
│     │ 3a. Print operation header                          │ │
│     │ 3b. Check if application installed                  │ │
│     │ 3c. Extract current version (via regex)             │ │
│     │ 3d. Get latest version (GitHub/npm)                 │ │
│     │ 3e. Compare and report versions                     │ │
│     │ 3f. Set global variables:                           │ │
│     │     - CURRENT_VERSION                               │ │
│     │     - LATEST_VERSION                                │ │
│     │     - VERSION_STATUS                                │ │
│     │     - APP_DISPLAY_NAME                              │ │
│     └─────────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Check VERSION_STATUS                                    │
│     - 0: Same version (up to date)                          │
│     - 1: Current > Latest (ahead)                           │
│     - 2: Current < Latest (update available)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Execute Update Workflow                                 │
│     - Prompt user confirmation                              │
│     - Run update command from config                        │
│     - Display success/failure message                       │
│     - Show installation info                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Script Execution Ends                       │
└─────────────────────────────────────────────────────────────┘
```

### VERSION_STATUS Values

| Value | Meaning | Action |
|-------|---------|--------|
| `0` | Same version | No update needed |
| `1` | Current > Latest | Already ahead |
| `2` | Update available | Proceed with update |

---

## Implementation Examples

### Example 1: Simple NPM Package Update

**File: `update_github_copilot_cli.sh`**

```bash
#!/bin/bash
#
# update_github_copilot_cli.sh - GitHub Copilot CLI Update Manager
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/github_copilot_cli.yaml"

update_github_copilot_cli() {
    # Check npm dependency first
    local dep_name=$(get_config "dependencies[0].name")
    local dep_cmd=$(get_config "dependencies[0].command")
    local dep_help=$(get_config "dependencies[0].help")
    
    if ! check_app_installed_or_help "$dep_name" "$dep_cmd" "$dep_help"; then
        return 0
    fi
    
    # Perform config-driven version check
    if ! config_driven_version_check; then
        return 0
    fi
    
    # Handle update workflow
    local update_cmd=$(get_config "update.command")
    local output_lines=$(get_config "update.output_lines")
    local success_msg=$(get_config "messages.update_success")
    local app_name=$(get_config "application.name")
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "$update_cmd 2>&1 | tail -$output_lines && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        ask_continue
        return 1
    fi
}

update_github_copilot_cli
```

**Configuration: `github_copilot_cli.yaml`**

See [YAML Configuration Schema](#yaml-configuration-schema) Example 1.

### Example 2: Complex Build from Source

**File: `update_tmux.sh`**

```bash
#!/bin/bash
#
# update_tmux.sh - Tmux Update Manager
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/tmux.yaml"

build_tmux_from_source() {
    local version=$1
    # ... custom build logic ...
}

perform_tmux_update() {
    local latest_version="$1"
    
    # Read prompts from config
    local prompt_msg=$(get_config "prompts.update_method.message")
    local prompt_opts=$(get_config "prompts.update_method.options")
    local prompt_default=$(get_config "prompts.update_method.default")
    
    # Ask for update method
    local method
    method=$(prompt_choice "$prompt_msg" "$prompt_opts" "$prompt_default")
    
    if [[ "$method" =~ ^[Ss]$ ]]; then
        build_tmux_from_source "$latest_version"
    else
        # Try package manager update
        if ! update_via_package_manager "tmux"; then
            # Fallback to source build
            local build_prompt=$(get_config "prompts.build_from_source.message")
            if prompt_yes_no "$build_prompt"; then
                build_tmux_from_source "$latest_version"
            else
                # Display build instructions from config
                # ... (see full implementation)
            fi
        fi
    fi
}

update_tmux() {
    # Perform config-driven version check
    if ! config_driven_version_check; then
        return 0
    fi
    
    # If no update needed
    if [ $VERSION_STATUS -ne 2 ]; then
        ask_continue
        return 0
    fi
    
    # Update if needed
    if ! prompt_yes_no "Update tmux?"; then
        print_status "Skipping tmux update"
        ask_continue
        return 0
    fi
    
    print_status "Updating tmux..."
    perform_tmux_update "$LATEST_VERSION"
    
    ask_continue
}

update_tmux
```

**Configuration: `tmux.yaml`**

See [YAML Configuration Schema](#yaml-configuration-schema) Example 2.

---

## Best Practices

### Configuration Management

1. **Use Semantic Versioning**

   ```yaml
   # Version: 0.1.0-alpha  (Major.Minor.Patch-Stage)
   ```

2. **Maintain Version History**

   ```yaml
   # Version History:
   #   0.2.0-alpha (2025-11-25) - Added new feature X
   #   0.1.0-alpha (2025-11-24) - Initial release
   ```

3. **Document Status**

   ```yaml
   # Status: Non-production (Alpha|Beta|RC) | Production
   ```

4. **Use Descriptive Messages**

   ```yaml
   messages:
     install_help: |
       Clear, multi-line instructions
       With installation steps
       And requirements
   ```

### Code Organization

1. **Keep Scripts Minimal**
   - Move reusable logic to libraries
   - Keep application-specific code in scripts

2. **Use Config for All Strings**
   - No hardcoded messages
   - No hardcoded commands
   - No hardcoded regex patterns

3. **Handle Errors Gracefully**

   ```bash
   if ! config_driven_version_check; then
       return 0  # Exit cleanly
   fi
   ```

4. **Document Custom Functions**

   ```bash
   # Build application from source
   # Usage: build_app_from_source "version"
   # Returns: 0 on success, 1 on failure
   build_app_from_source() {
       # ...
   }
   ```

### Version Extraction

1. **Test Regex Patterns**

   ```bash
   # Test with actual output:
   echo "tmux 3.4" | sed -E 's/tmux ([0-9]+\.[0-9]+[a-z]?).*/\1/'
   # Output: 3.4
   ```

2. **Capture Only Version Number**

   ```yaml
   version:
     regex: '.*([0-9]+\.[0-9]+\.[0-9]+).*'
     # Capture group \1 must be the version
   ```

3. **Handle Different Formats**

   ```yaml
   # For: "app v1.2.3-beta"
   regex: '.*v?([0-9]+\.[0-9]+\.[0-9]+).*'
   ```

---

## Creating New Upgrade Scripts

### Step-by-Step Guide

#### Step 1: Create YAML Configuration

```bash
cd src/system_update/upgrade_snippets
touch myapp.yaml
```

**Template:**

```yaml
# MyApp Update Configuration
# 
# Version: 0.1.0-alpha
# Date: $(date +%Y-%m-%d)
# Author: <your_name>
# Repository: https://github.com/<owner>/<repo>
# Status: Non-production (Alpha)
#
# Version History:
#   0.1.0-alpha ($(date +%Y-%m-%d)) - Initial version

# Application identifiers
application:
  name: "myapp"
  command: "myapp"
  display_name: "MyApp"

# Messages
messages:
  checking_updates: "Checking MyApp updates..."
  install_help: "Install: <installation_command>"
  failed_version: "Failed to get current version"
  update_success: "MyApp updated successfully"

# Version extraction
version:
  command: "myapp --version"
  regex: '.*([0-9]+\.[0-9]+\.[0-9]+).*'
  source: "github"  # or "npm"
  github_owner: "<owner>"
  github_repo: "<repo>"

# Update commands
update:
  command: "<update_command>"
  output_lines: 10
```

#### Step 2: Create Shell Script

```bash
touch update_myapp.sh
chmod +x update_myapp.sh
```

**Template:**

```bash
#!/bin/bash
#
# update_myapp.sh - MyApp Update Manager
#
# Handles version checking and updates for MyApp.
#

# Load upgrade utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
source "$LIB_DIR/upgrade_utils.sh"

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/myapp.yaml"

update_myapp() {
    # Perform config-driven version check
    if ! config_driven_version_check; then
        return 0
    fi
    
    # Handle update workflow
    local update_cmd
    update_cmd=$(get_config "update.command")
    local output_lines
    output_lines=$(get_config "update.output_lines")
    local success_msg
    success_msg=$(get_config "messages.update_success")
    local app_name
    app_name=$(get_config "application.name")
    
    if ! handle_update_prompt "$APP_DISPLAY_NAME" "$VERSION_STATUS" \
        "$update_cmd 2>&1 | tail -$output_lines && \
         print_success '$success_msg' && \
         show_installation_info '$app_name' '$APP_DISPLAY_NAME'"; then
        ask_continue
        return 1
    fi
}

update_myapp
```

#### Step 3: Test Configuration

```bash
# Test YAML parsing
yq -r '.application.name' myapp.yaml

# Test version extraction
myapp --version | sed -E 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/'

# Test script syntax
bash -n update_myapp.sh
```

#### Step 4: Test Script Execution

```bash
# Dry run (if supported)
./update_myapp.sh --dry-run

# Actual run
./update_myapp.sh
```

#### Step 5: Document

Update repository README with:

- Application name
- Installation requirements
- Usage instructions

---

## Advanced Features

### Custom Dependencies Check

```bash
update_myapp() {
    # Check custom dependency
    local dep_name=$(get_config "dependencies[0].name")
    local dep_cmd=$(get_config "dependencies[0].command")
    local dep_help=$(get_config "dependencies[0].help")
    
    if ! check_app_installed_or_help "$dep_name" "$dep_cmd" "$dep_help"; then
        return 0
    fi
    
    # Continue with version check...
}
```

### Multiple Update Methods

```yaml
prompts:
  update_method:
    message: "Update method: (p)ackage, (s)ource, (d)ocker?"
    options: "p/s/d"
    default: "p"
```

```bash
perform_update() {
    local method=$(prompt_choice "..." "p/s/d" "p")
    
    case "$method" in
        [Pp])
            update_via_package_manager "myapp"
            ;;
        [Ss])
            build_from_source "$latest_version"
            ;;
        [Dd])
            update_via_docker
            ;;
    esac
}
```

### Conditional Update Logic

```bash
update_myapp() {
    if ! config_driven_version_check; then
        return 0
    fi
    
    # Custom logic based on version status
    if [ $VERSION_STATUS -eq 0 ]; then
        print_success "Already up to date!"
        return 0
    elif [ $VERSION_STATUS -eq 1 ]; then
        print_warning "Current version ($CURRENT_VERSION) is ahead of latest ($LATEST_VERSION)"
        if ! prompt_yes_no "Downgrade to latest stable?"; then
            return 0
        fi
    fi
    
    # Proceed with update...
}
```

### Progress Tracking

```bash
perform_complex_update() {
    print_status "Step 1/4: Backing up configuration..."
    backup_config
    
    print_status "Step 2/4: Downloading update..."
    download_update
    
    print_status "Step 3/4: Installing..."
    install_update
    
    print_status "Step 4/4: Verifying installation..."
    verify_installation
}
```

---

## Troubleshooting

### Common Issues

#### 1. Config File Not Found

**Error:**

```plaintext
Config file not found: /path/to/app.yaml
```

**Solution:**

```bash
# Verify CONFIG_FILE path
echo "$CONFIG_FILE"

# Check file exists
ls -la "$CONFIG_FILE"

# Verify SCRIPT_DIR
echo "$SCRIPT_DIR"
```

#### 2. Version Extraction Fails

**Error:**

```plaintext
Failed to get current version
```

**Solution:**

```bash
# Test version command manually
myapp --version

# Test regex pattern
myapp --version | sed -E 's/your_regex_here/\1/'

# Update YAML config with correct command/regex
```

#### 3. YAML Parsing Error

**Error:**

```plaintext
yq: error parsing YAML
```

**Solution:**

```bash
# Validate YAML syntax
yq . myapp.yaml

# Check for common issues:
# - Incorrect indentation (use spaces, not tabs)
# - Missing quotes around special characters
# - Unclosed strings
```

#### 4. Library Function Not Found

**Error:**

```plaintext
command not found: config_driven_version_check
```

**Solution:**

```bash
# Verify library is sourced
source "$LIB_DIR/upgrade_utils.sh"

# Check LIB_DIR path
echo "$LIB_DIR"
ls -la "$LIB_DIR/upgrade_utils.sh"
```

### Debug Mode

Enable verbose output:

```bash
# Set debug variables
export VERBOSE_MODE=true
export DEBUG=true

# Run script
./update_myapp.sh
```

### Validation Checklist

Before deploying a new upgrade script:

- [ ] YAML syntax validates (`yq . app.yaml`)
- [ ] Shell syntax validates (`bash -n update_app.sh`)
- [ ] Version command works (`app --version`)
- [ ] Regex captures version correctly
- [ ] Config file path is correct
- [ ] Library is sourced successfully
- [ ] All required YAML fields present
- [ ] Update command tested manually
- [ ] Error messages are clear
- [ ] Script exits cleanly on failure

---

## API Reference

### Library Functions

#### `get_config(key, [config_file])`

Read configuration values from YAML files.

**Parameters:**

- `key` (string): YAML path (e.g., "application.name")
- `config_file` (string, optional): Config file path. Defaults to `$CONFIG_FILE`

**Returns:**

- Configuration value or empty string if not found

**Example:**

```bash
app_name=$(get_config "application.name")
version_cmd=$(get_config "version.command" "custom.yaml")
```

#### `config_driven_version_check()`

Performs complete version check workflow using configuration.

**Requires:**

- `CONFIG_FILE` environment variable set

**Sets Global Variables:**

- `CURRENT_VERSION`: Current installed version
- `LATEST_VERSION`: Latest available version
- `VERSION_STATUS`: Comparison result (0=same, 1=ahead, 2=update)
- `APP_DISPLAY_NAME`: Application display name

**Returns:**

- `0`: Success
- `1`: Failure (app not installed, version check failed, etc.)

**Example:**

```bash
CONFIG_FILE="myapp.yaml"
if config_driven_version_check; then
    echo "Current: $CURRENT_VERSION"
    echo "Latest: $LATEST_VERSION"
    echo "Status: $VERSION_STATUS"
fi
```

### Configuration Access Patterns

```bash
# Simple value
name=$(get_config "application.name")

# Nested value
owner=$(get_config "version.github_owner")

# Array element
dep=$(get_config "dependencies[0].name")

# Multi-line value
help=$(get_config "messages.install_help")

# Array to list
deps=$(yq -r '.build_instructions.dependencies[]' "$CONFIG_FILE")
```

---

## Appendix

### A. Complete File Examples

See [Implementation Examples](#implementation-examples) section.

### B. Migration Guide

To migrate an existing hardcoded script:

1. Create YAML config file
2. Extract all strings to config
3. Replace hardcoded values with `get_config()` calls
4. Use `config_driven_version_check()` for version checking
5. Test thoroughly
6. Update documentation

### C. Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-24 | Initial documentation |

### D. Contributing

When contributing new upgrade scripts:

1. Follow the pattern documented here
2. Use semantic versioning for configs
3. Test on multiple environments
4. Document any custom logic
5. Submit with both `.sh` and `.yaml` files

### E. License

This pattern and documentation are part of the mpb_scripts repository.
Licensed under MIT License.

---

## End of Documentation
