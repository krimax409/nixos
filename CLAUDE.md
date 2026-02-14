# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is FrostPhoenix's modular NixOS configuration repository using Nix Flakes, designed around a Hyprland-based desktop environment with Gruvbox theming. The configuration supports multiple host types (desktop, laptop, vm) with shared core modules and host-specific optimizations.

## Common Commands

### System Management
- `nh os test` - Test configuration without switching (alias: `nix-test`)
- `nh os switch` - Apply configuration (alias: `nix-switch`)
- `nh os switch --update` - Update flake inputs and apply (alias: `nix-update`)
- `nh clean all --keep 5` - Clean old generations, keep 5 (alias: `nix-clean`)
- `nh search <package>` - Search for packages (alias: `nix-search`)

**IMPORTANT: Claude Code has passwordless sudo access** for system rebuild commands. You can directly run:
- `sudo nixos-rebuild switch --flake .#desktop` - Apply configuration for desktop
- `sudo nixos-rebuild test --flake .#desktop` - Test configuration without making it default
- `sudo nh os switch` - Apply using nh helper
- `sudo nh os test` - Test using nh helper
- `sudo systemctl restart home-manager-k.service` - Restart home-manager service

Sudo is configured in `modules/core/sudo.nix` to allow these commands without password prompts.

### Development Workflow
- `treefmt` - Format Nix and shell files according to treefmt.toml
- `cd ~/nixos-config && codium ~/nixos-config` - Quick access to config (alias: `cdnix`)
- `nixos-rebuild switch --flake .#<host>` - Manual rebuild for specific host (desktop/laptop/vm)

### Installation
- `./install.sh` - Automated first-time setup script that handles username replacement and host selection

## Architecture

### Module Organization
```
modules/
├── core/           # System-level NixOS modules
│   ├── default.nix # Aggregates all core modules
│   ├── hardware.nix, network.nix, pipewire.nix, etc.
│   └── nvidia.nix, steam.nix, virtualization.nix
└── home/           # User-level Home Manager modules  
    ├── default.nix # Aggregates all home modules
    ├── packages/   # Package collections by category
    ├── programs/   # Application configurations
    └── services/   # User services and desktop environment
```

### Host Configurations
- `hosts/desktop/` - Desktop with performance CPU governor
- `hosts/laptop/` - Laptop with TLP power management and battery optimization  
- `hosts/vm/` - Virtual machine configuration

Each host imports `hardware-configuration.nix` and core modules, then applies host-specific settings.

### Key Technologies Stack
- **Window Manager**: Hyprland (Wayland compositor) + KDE Plasma 6
- **Terminal**: Kitty (primary) + Ghostty (alternative)
- **Shell**: Zsh with Powerlevel10k
- **Editor**: VSCode + Neovim
- **Theme**: Gruvbox Dark Hard
- **Audio**: PipeWire
- **Package Management**: Nix Flakes + Home Manager + selective Flatpak use
- **Proxy Apps**: Spotify and Claude Code configured with HTTP proxy (127.0.0.1:2080)

### Import Hierarchy
1. `flake.nix` defines outputs for three host configurations
2. Host configs import hardware-configuration.nix and `modules/core/default.nix`
3. Core modules aggregate system-level configurations
4. Home Manager modules aggregate user-level configurations via `modules/home/default.nix`
5. Package modules organize by category (CLI, GUI, dev, gaming, custom)

## Development Notes

### Custom Packages
- Custom packages are defined in `pkgs/` and built from source
- Currently includes a custom 2048 CLI game from FrostPhoenix's repository

### Configuration Patterns
- All modules follow standard NixOS module structure with imports, options, and config
- Home Manager modules use `programs.*` and `services.*` for application configuration
- Packages are organized by functional category in `modules/home/packages/`
- Shell aliases and functions are centralized for productivity

### Host-Specific Considerations
- Laptop configuration includes TLP for power management and CPU frequency scaling
- Desktop uses performance CPU governor for maximum performance
- VM configuration is minimal and virtualization-optimized
- NVIDIA drivers are conditionally enabled based on host hardware

### Formatting and Style
- Use `treefmt` before committing changes - configured in `treefmt.toml`
- Nix files follow nixpkgs formatting conventions
- Shell scripts follow bash best practices with proper error handling

### Special Features
- **KDE Plasma Manager**: Declarative KDE configuration in `modules/home/plasma.nix`
  - Dark theme by default
  - Bottom panel with auto-hide on mouse hover
  - Configured using plasma-manager Home Manager module
- **Proxy Configuration**: Applications requiring proxy are wrapped with environment variables
  - Pattern: `writeShellApplication` wrapper with HTTPS_PROXY/HTTP_PROXY exports
  - Examples: `modules/home/spotify.nix`, `modules/home/claude.nix`
- **Automatic Backup Cleanup**: Home Manager configured to auto-remove old backup files
  - See `home.activation.cleanupBackups` in `modules/core/user.nix`