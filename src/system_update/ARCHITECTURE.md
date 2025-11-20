# System Update Architecture Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     system_update.sh                        │
│                   (Main Orchestrator)                       │
│                                                             │
│  • Argument parsing                                         │
│  • Flow control                                             │
│  • Module coordination                                      │
│  • NO business logic                                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ sources
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    lib/ Core Modules                        │
└─────────────────────────────────────────────────────────────┘
              │
              ├─────────────────────────────────────────┐
              │                                         │
              ▼                                         ▼
┌──────────────────────────┐           ┌──────────────────────────┐
│    core_lib.sh           │           │  Core Package Managers   │
│  (Foundation Layer)      │           │                          │
├──────────────────────────┤           ├──────────────────────────┤
│ • Color definitions      │◄──────────┤ • apt_manager.sh         │
│ • print_* functions      │           │ • pacman_manager.sh      │
│ • ask_continue()         │           │ • dpkg_manager.sh        │
│ • detect_package_mgr()   │           │ • app_managers.sh        │
│ • compare_versions()     │           │   (snippet loader)       │
└──────────────────────────┘           └──────────────────────────┘
                                                 │
                                                 │ loads dynamically
                                                 ▼
                              ┌─────────────────────────────────────┐
                              │  upgrade_snippets/ (Optional)       │
                              ├─────────────────────────────────────┤
                              │ • snap_manager.sh                   │
                              │ • cargo_manager.sh                  │
                              │ • pip_manager.sh                    │
                              │ • npm_manager.sh                    │
                              │ • check_calibre_update.sh           │
                              │ • check_kitty_update.sh             │
                              │ • check_vscode_insiders_update.sh   │
                              │ • update_github_copilot_cli.sh      │
                              └─────────────────────────────────────┘
```

## Layered Architecture

```
┌────────────────────────────────────────────────────────────────┐
│  Layer 4: User Interface (CLI)                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  system_update.sh --quiet --full                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 3: Orchestration Layer                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  system_update.sh (main logic)                           │  │
│  │  • Parse arguments                                       │  │
│  │  • Detect package manager                                │  │
│  │  • Call appropriate manager modules                      │  │
│  │  • Handle flow control                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 2: Business Logic Layer                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Core Package Managers (lib/)                            │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐           │  │
│  │  │ apt_mgr.sh │ │pacman_mgr │ │ dpkg_mgr   │           │  │
│  │  │            │ │    .sh     │ │    .sh     │           │  │
│  │  │ • update   │ │ • update   │ │ • maintain │           │  │
│  │  │ • upgrade  │ │ • upgrade  │ │            │           │  │
│  │  │ • cleanup  │ │ • cleanup  │ │            │           │  │
│  │  └────────────┘ └────────────┘ └────────────┘           │  │
│  │                                                          │  │
│  │  ┌────────────┐                                         │  │
│  │  │  app_mgr   │  (loads upgrade snippets)              │  │
│  │  │    .sh     │                                         │  │
│  │  │ • source_  │                                         │  │
│  │  │   snippets │                                         │  │
│  │  └────────────┘                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Optional Upgrade Snippets (upgrade_snippets/)           │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐           │  │
│  │  │ snap_mgr   │ │  pip_mgr   │ │  npm_mgr   │           │  │
│  │  │    .sh     │ │    .sh     │ │    .sh     │           │  │
│  │  │ • refresh  │ │ • update   │ │ • update   │           │  │
│  │  └────────────┘ └────────────┘ └────────────┘           │  │
│  │                                                          │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐           │  │
│  │  │ cargo_mgr  │ │ check_     │ │ check_     │           │  │
│  │  │    .sh     │ │ kitty...   │ │ calibre... │           │  │
│  │  │ • toolchn  │ │            │ │            │           │  │
│  │  │ • packages │ │            │ │            │           │  │
│  │  └────────────┘ └────────────┘ └────────────┘           │  │
│  │                                                          │  │
│  │  ┌────────────┐ ┌────────────┐                          │  │
│  │  │ check_     │ │ update_    │                          │  │
│  │  │ vscode...  │ │ copilot... │                          │  │
│  │  └────────────┘ └────────────┘                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 1: Foundation Layer (Core Utilities)                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  core_lib.sh                                             │  │
│  │  • Color definitions (RED, GREEN, BLUE, etc.)            │  │
│  │  • Output formatters (print_status, print_error, etc.)   │  │
│  │  • User interaction (ask_continue)                       │  │
│  │  • System utilities (detect_package_manager)             │  │
│  │  • Version comparison (compare_versions)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## Module Dependencies

```
system_update.sh
├── requires → core_lib.sh
├── requires → app_managers.sh
│   ├── requires → core_lib.sh
│   └── sources → upgrade_snippets/* (dynamically)
│       ├── snap_manager.sh
│       ├── cargo_manager.sh
│       ├── pip_manager.sh
│       ├── npm_manager.sh
│       ├── check_calibre_update.sh
│       ├── check_kitty_update.sh
│       ├── check_vscode_insiders_update.sh
│       └── update_github_copilot_cli.sh
├── requires → apt_manager.sh
│   └── requires → core_lib.sh
├── requires → pacman_manager.sh
│   └── requires → core_lib.sh
└── requires → dpkg_manager.sh
    └── requires → core_lib.sh

Note: Upgrade snippets are optional and loaded dynamically at runtime
      if present in the upgrade_snippets/ directory.
```

## Data Flow

```
User Input
    │
    ▼
┌──────────────────┐
│ Argument Parser  │ (system_update.sh)
└──────────────────┘
    │
    ├─ quiet mode? → Set QUIET_MODE=true
    ├─ full mode?  → Set FULL_MODE=true
    ├─ list mode?  → list_all_packages() → Exit
    └─ cleanup?    → cleanup() → Exit
    │
    ▼
┌──────────────────┐
│ Detect Package   │ (detect_package_manager)
│ Manager          │
└──────────────────┘
    │
    ├─ apt?    → Execute APT workflow
    └─ pacman? → Execute Pacman workflow
    │
    ▼
┌──────────────────┐
│ Execute Package  │
│ Manager Workflow │
└──────────────────┘
    │
    ├─ check_broken_packages()     ──┐
    ├─ check_unattended_upgrades() ──┤
    ├─ update_package_list()       ──┤ Core Package
    ├─ upgrade_packages()          ──┤ Manager
    ├─ maintain_dpkg_packages()    ──┤ (APT/Pacman)
    └─ cleanup()                   ──┘
    │
    ▼
┌──────────────────┐
│ Load Upgrade     │
│ Snippets         │ (app_managers.sh → source_upgrade_snippets())
└──────────────────┘
    │
    ▼
┌──────────────────┐
│ Update Optional  │
│ Package Managers │ (if snippets loaded)
└──────────────────┘
    │
    ├─ update_snap_packages()       (optional)
    ├─ update_rust_packages()       (optional)
    ├─ update_pip_packages()        (optional)
    └─ update_npm_packages()        (optional)
    │
    ▼
┌──────────────────┐
│ Update           │
│ Applications     │ (if snippets loaded)
└──────────────────┘
    │
    ├─ check_kitty_update()         (optional)
    ├─ update_github_copilot_cli()  (optional)
    ├─ check_calibre_update()       (optional)
    └─ check_vscode_insiders_update() (optional)
    │
    ▼
┌──────────────────┐
│ Final Cleanup    │ (if not simple mode)
└──────────────────┘
    │
    ▼
┌──────────────────┐
│ Show Summary     │
└──────────────────┘
    │
    ▼
Exit
```

## Cohesion Analysis

### High Cohesion (Good ✅)

Each module contains **strongly related functions**:

```
apt_manager.sh
├── update_package_list()        ◄─── All APT-specific
├── upgrade_packages()            ◄─── operations grouped
│   (uses apt upgrade)            ◄─── (modern apt command)
├── full_upgrade()                ◄─── 
├── cleanup()                     ◄─── 
└── check_broken_packages()       ◄───  

core_lib.sh
├── print_status()                ◄─── All formatting
├── print_error()                 ◄─── and utility
├── print_success()               ◄─── functions
└── ask_continue()                ◄─── together
```

### Low Coupling (Good ✅)

Modules are **independent** and **loosely coupled**:

```
Core modules (lib/):
apt_manager.sh ────┐
pacman_manager.sh ─┤
dpkg_manager.sh ───├─── Only depend on core_lib.sh
app_managers.sh ───┘    (No cross-dependencies)

Upgrade snippets (optional):
snap_manager.sh ───┐
cargo_manager.sh ──┤
pip_manager.sh ────├─── Dynamically loaded
npm_manager.sh ────┤    (Zero dependencies on each other)
check_*.sh ────────┤    (Only use core_lib.sh functions)
update_*.sh ───────┘

Adding/removing upgrade snippet ≠ Affects core or other snippets ✅
```

## Comparison with Previous Architectures

### Monolithic v0.3.0 (Before) ❌

```
┌─────────────────────────────────────┐
│     system_update.sh (2606 lines)   │
│                                     │
│ Colors + Functions + APT + Pacman + │
│ Snap + Cargo + pip + npm + Apps +   │
│ Main Logic ALL TOGETHER             │
│                                     │
│ Low Cohesion + High Coupling        │
└─────────────────────────────────────┘
```

### Modular v0.4.x (Previous) ⚠️

```
┌──────────────┐
│ Orchestrator │ (390 lines)
└──────┬───────┘
       │
       ├─ core_lib.sh (130 lines)
       ├─ apt_manager.sh (560 lines)
       ├─ pacman_manager.sh (108 lines)
       ├─ snap_manager.sh (52 lines)      ← All in lib/
       ├─ cargo_manager.sh (88 lines)     ← Hard to extend
       ├─ pip_manager.sh (55 lines)       ← without modifying
       ├─ npm_manager.sh (54 lines)       ← core scripts
       └─ app_managers.sh (165 lines)

High Cohesion + Low Coupling
But: Need to modify main script to add features
```

### Modular with Upgrade Snippets v0.5.0 (Current) ✅

```
┌──────────────┐
│ Orchestrator │ (~300 lines)
└──────┬───────┘
       │
       ├─ lib/ (Core - Required)
       │  ├─ core_lib.sh (~130 lines)
       │  ├─ apt_manager.sh (~560 lines)
       │  ├─ pacman_manager.sh (~108 lines)
       │  ├─ dpkg_manager.sh (~42 lines)
       │  └─ app_managers.sh (~165 lines)
       │
       └─ upgrade_snippets/ (Optional - Dynamically loaded)
          ├─ snap_manager.sh (~52 lines)
          ├─ cargo_manager.sh (~88 lines)
          ├─ pip_manager.sh (~55 lines)
          ├─ npm_manager.sh (~54 lines)
          ├─ check_calibre_update.sh (~85 lines)
          ├─ check_kitty_update.sh (~65 lines)
          ├─ check_vscode_insiders_update.sh (~85 lines)
          └─ update_github_copilot_cli.sh (~70 lines)

High Cohesion + Low Coupling + Zero-Modification Extensibility ✅
Add features by creating files, not editing code!
```

## Benefits Summary

| Aspect | v0.5.0 Benefit |
|--------|----------------|
| **Maintainability** | Small, focused files (~40-560 lines); easy to locate bugs |
| **Testability** | Can test modules independently; clear test boundaries |
| **Reusability** | Core functions can be sourced in other scripts |
| **Extensibility** | Add features by dropping files in upgrade_snippets/ |
| **Debugging** | Easy to isolate issues to specific module |
| **Collaboration** | Multiple developers can work on different modules |
| **Understanding** | Clear separation makes code easier to understand |
| **Core Stability** | Essential features in lib/ are stable and tested |
| **Optional Features** | Upgrade snippets can be added/removed without risk |
| **Zero Modification** | Extend functionality without editing core code |

## Extension Example

To add a new package manager (e.g., Flatpak):

```bash
# 1. Create new file in upgrade_snippets/
cat > upgrade_snippets/flatpak_manager.sh << 'EOF'
#!/bin/bash
update_flatpak_packages() {
    print_operation_header "Checking Flatpak updates..."
    if ! command -v flatpak &> /dev/null; then
        print_warning "Flatpak not installed"
        return 0
    fi
    flatpak update -y
    print_success "Flatpak packages updated"
}
EOF

# 2. Make it executable
chmod +x upgrade_snippets/flatpak_manager.sh

# 3. Done! No core code modifications needed
# The script will automatically load it on next run
```

---

**Architecture Version:** 1.0  
**Date:** 2024-11-11  
**Design Pattern:** Modular Architecture with Layered Separation
