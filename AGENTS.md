# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS configuration flake for multiple machines with home-manager integration. Uses a custom module system with `lajp.*` options for both system and user configuration.

## Common Commands

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Deploy to remote hosts
nixos-rebuild switch --target-host <hostname> --sudo --flake .#<hostname>
# e.g., nixos-rebuild switch --target-host nas --sudo --flake .#nas

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
    - `dashboards/` - Grafana dashboard JSON files (email, gpu, hedgedoc, nginx-analytics, nginx, nixos-nodes, smart, ups, zfs)
  - `hardware/` - Hardware-specific configs (zfs, sound, bluetooth, backlight, memory, rtl-sdr)
  - `common/` - Base system configuration
  - `gui/` - GUI-related configs (fonts, keyboard, theme, virt-manager)
  - `virtualisation/` - Virtualisation configs (podman)
- `modules/user/` - Home-manager modules with `lajp.*` options
  - `programs/` - User applications (neovim via nixvim, fish, git, gpg, jujutsu, mail, neomutt, pass, ssh, testaustime, zsh)
    - `gui/` - GUI applications (firefox, mpv, niri)
  - `services/` - User services (dwm-status, swayidle, waybar)

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
- `nixarr` - media stack (Jellyfin, transmission, *arr suite)
- `nixos-hardware` - hardware-specific optimizations

### Port Management

Custom port allocation system in `modules/system/ports.nix`. Services request ports via `lajp.portRequests` — either as an explicit number or `true` for auto-allocation (starting from 3000). Allocated ports are available via `lajp.ports.<service>`. Detects collisions with source location reporting.

### Notes

- When creating a service, always check if it can be added to prometheus and grafana
- Kernel upgrade on nas requires reboot, otherwise cuda in jellyfin fails
- Secret management is done with agenix *rekey*, no secrets.nix like in agenix
