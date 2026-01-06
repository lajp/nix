# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS configuration flake for multiple machines with home-manager integration. Uses a custom module system with `lajp.*` options for both system and user configuration.

## Common Commands

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Deploy to remote hosts using deploy-rs
deploy .#<nodename>  # e.g., deploy .#nas, deploy .#ankka

# Rekey secrets after adding new hosts or changing keys
agenix-rekey

# Enter dev shell with required tools (agenix-rekey, deploy-rs, nh)
nix develop
```

Available hosts: `nas`, `vaasanas`, `t480`, `framework`, `proxy-pi`, `ankka`

## Architecture

### Host Configuration Pattern

Hosts are created via `mkHost` function in `lib/system.nix`:

```nix
mkHost {
  system = "x86_64-linux";  # or "aarch64-linux"
  systemConfig = { ... };   # lajp.* system options
  userConfig = { ... };     # lajp.* home-manager options
  extraModules = [ ... ];   # additional NixOS modules
}
```

- `systemConfig` sets `lajp.*` options in system scope
- `userConfig` sets `lajp.*` options in home-manager scope
- Setting `core.server = true` disables home-manager for that host

### Module Structure

- `modules/system/` - NixOS modules with `lajp.*` options
  - `services/` - Service configurations (ssh, tailscale, prometheus, nixarr, etc.)
    - `dashboards/` - Grafana dashboard JSON files (nginx-analytics, etc.)
  - `hardware/` - Hardware-specific configs (zfs, sound, bluetooth, backlight)
  - `common/` - Base system configuration
- `modules/user/` - Home-manager modules with `lajp.*` options
  - `programs/` - User applications (neovim via nixvim, gui apps, neomutt)
  - `services/` - User services

### Secrets Management

Uses agenix with agenix-rekey for secrets. Secrets are stored in `secrets/` with rekeyed versions in `secrets/rekeyed/<hostname>/`.

Master identity: `yubikey.pub` (YubiKey-based)

### Key Flake Inputs

- `nixpkgs` (25.11) and `nixpkgs-unstable` - packages available as `pkgs` and `pkgs-unstable`
- `home-manager` - user environment management (disabled on servers)
- `agenix` + `agenix-rekey` - secret management
- `nixvim` - declarative neovim configuration
- `niri` - Wayland compositor
- `deploy-rs` - remote deployment
- `stylix` - system-wide theming
