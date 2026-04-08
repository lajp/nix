# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS configuration flake for 6 machines (4 x86_64-linux, 2 aarch64-linux) with home-manager integration. Uses a custom module system with `lajp.*` options for both system and user configuration. Based on nixpkgs 25.11 and home-manager 25.11.

For a visual infrastructure overview with network diagrams, see [docs/INFRASTRUCTURE.md](./docs/INFRASTRUCTURE.md).

## Common Commands

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Deploy to remote hosts (via deploy-rs)
deploy .#<hostname>

# Rekey secrets after adding new hosts or changing keys
agenix-rekey

# Enter dev shell with required tools (agenix-rekey, age-plugin-yubikey, deploy-rs, nh)
nix develop
```

Available hosts: `nas`, `vaasanas`, `t480`, `framework`, `proxy-pi`, `ankka`

## Hosts

| Host | Arch | Type | Key Role |
|------|------|------|----------|
| `nas` | x86_64 | server | Media/storage: Jellyfin, nixarr, Nextcloud, Syncthing, Samba, Attic cache, ZFS, NVIDIA GPU, UPS |
| `vaasanas` | x86_64 | server | Secondary: NFS server, Samba, ZFS, DynDNS (mc.portfo.rs) |
| `t480` | x86_64 | desktop | ThinkPad T480: Niri compositor, PIA VPN, RTL-SDR |
| `framework` | x86_64 | desktop | Framework 13 AMD: Niri, multiple VPNs, Docker, virt-manager, fingerprint |
| `proxy-pi` | aarch64 | server | Raspberry Pi 4: AdGuard Home DNS, nginx reverse proxy for internal services |
| `ankka` | aarch64 | server | Hetzner VPS: Central Prometheus/Grafana, Headscale, mail server, Matrix, HedgeDoc, Gatus, CoreDNS, website |

Servers (`core.server = true`) have home-manager disabled. Desktops get full home-manager + GUI.

## Architecture

### Host Configuration Pattern

Hosts are created via `mkHost` function in `lib/system.nix`:

```nix
mkHost {
  system = "x86_64-linux";  # or "aarch64-linux"
  systemConfig = { ... };   # lajp.* system options
  userConfig = { ... };     # lajp.* home-manager options
  extraModules = [ ... ];   # additional NixOS modules (e.g. nixos-hardware)
}
```

- `systemConfig` sets `lajp.*` options in system scope
- `userConfig` sets `lajp.*` options in home-manager scope
- Setting `core.server = true` disables home-manager for that host
- `pkgs-unstable` and `pkgs-nur` are passed as special args to all modules

### Module Structure

```
modules/system/                  NixOS modules (lajp.* options)
  core.nix                       hostname, server flag
  ports.nix                      port allocation system
  rickroll.nix                   rickroll easter egg
  dreamlauncher.nix              dream launcher
  common/                        base config (nix settings, user account, shell)
  services/                      46 service modules (see below)
    dashboards/                  11 Grafana dashboard JSONs
  hardware/                      zfs, sound, bluetooth, rtl-sdr, backlight, memory
  gui/                           fonts, keyboard, theme (stylix), virt-manager
  virtualisation/                podman

modules/user/                    Home-manager modules (lajp.* options)
  default.nix                    base home-manager config, XDG, cursor, nix registry
  accounts.nix                   email accounts (lajp.fi, iki.fi, aalto, hy, otanix, helsec)
  programs/                      neovim, fish, git, gpg, jujutsu, ssh, pass, zsh, testaustime, mail
    gui/                         firefox, mpv, niri, + desktop apps (discord, signal, telegram, etc.)
    neomutt/                     neomutt email client config
  services/                      waybar, swayidle, dwm-status, gpg-agent, dunst, picom
```

### Service Modules (`modules/system/services/`)

ssh, jellyfin, jackett, prowlarr, transmission, cross-seed, tvheadend, threadfin, testaustime-backup, syncthing, samba, xserver, gpg, vaultwarden, restic, backup-notify, niri, pia, website, sonarr, uptime-kuma, mailserver, dyndns, smartd, formicer-website, nixarr, gatus, headscale, hedgedoc, tailscale, nginx, zfs-backup, vpn, adguardhome, coredns, nextcloud, memegenerator, cheese, crabfit, yensid, prometheus, typst-collab, resource-limits, email-telegram-bridge, attic, matrix

### Grafana Dashboards (`modules/system/services/dashboards/`)

email, gpu, headscale, hedgedoc, nginx-analytics, nginx, nixos-nodes, smart, synapse, ups, zfs

## Port Management

Custom port allocation system in `modules/system/ports.nix`. Services request ports via `lajp.portRequests` -- either as an explicit number or `true` for auto-allocation (starting from 3000). Allocated ports are available via `lajp.ports.<service>`. Detects collisions with source location reporting.

## Secrets Management

Uses agenix with **agenix-rekey** (not plain agenix). There is no `secrets.nix` file -- each module declares its own `age.secrets.*.rekeyFile` pointing to files in `secrets/*.age`.

- Master identity: `yubikey.pub` (YubiKey-based)
- Encrypted secrets: `secrets/*.age` (~35 files)
- Per-host rekeyed secrets: `secrets/rekeyed/<hostname>/`
- Rekey command: `agenix-rekey` (available in dev shell)

## Networking & DNS

- **Headscale** on ankka manages the Tailscale mesh VPN (base domain: `tailnet.lajp.fi`)
- Known tailnet IPs: nas=`100.64.0.2`, proxy-pi=`100.64.0.3`, ankka=`100.64.0.4`
- **CoreDNS** on ankka (`100.64.0.4:53`) -- Headscale configures this as the tailnet nameserver. Forwards sequentially: first to AdGuard Home, falls back to 1.1.1.1
- **AdGuard Home** on proxy-pi (`100.64.0.3:53`) -- ad-blocking/filtering DNS, upstream to 1.1.1.1 and 8.8.8.8
- **Cloudflare DynDNS** on nas (jellyfin, jellyseerr, pilvi, cache) and vaasanas (mc.portfo.rs)
- **nginx** reverse proxy on ankka (public `*.lajp.fi`), nas (DynDNS domains), and proxy-pi (internal `*.intra.lajp.fi`) with ACME/Let's Encrypt

## Monitoring

- **Central Prometheus** on ankka (port 9090, 8GB retention cap, remote write receiver enabled)
- **Agent-mode Prometheus** on nas, vaasanas, proxy-pi -- pushes metrics via `remote_write` to `100.64.0.4:9090` (framework and t480 do not run prometheus)
- **Grafana** on ankka with auto-provisioned dashboards from `services/dashboards/`
- **Gatus** on ankka (`status.lajp.fi`) -- monitors 30+ endpoints with email alerting (via email-telegram bridge to Telegram)
- Exporters: node, nginx, nginx-log, smartctl, zfs, nvidia-gpu, apcupsd, dovecot, rspamd, postfix, synapse, hedgedoc, headscale, exportarr (sonarr/radarr/prowlarr)

## Deployment

### deploy-rs

Remote deployment via deploy-rs for 4 hosts:

| Host | SSH User | Remote Build | Interactive Sudo |
|------|----------|-------------|-----------------|
| `nas` | root | no | yes |
| `vaasanas` | lajp | yes | yes |
| `proxy-pi` | root | no | no |
| `ankka` | lajp | no | no |

`t480` and `framework` are local machines -- not in deploy-rs nodes.

### CI/CD (GitHub Actions)

- **`ci.yml`**: Builds all hosts except `t480` on push. ARM hosts (ankka, proxy-pi) on `ubuntu-24.04-arm`, x64 hosts on `ubuntu-latest`. Uses Attic binary cache (`cache.lajp.fi/ci`) for push/pull.
- **`update.yml`**: Weekly (Monday) automated `nix flake update`, creates PR if inputs changed.

## Backups

- **Restic**: framework + t480 home dirs -> SFTP to nas (`/media/luukas/Backups/<hostname>`), daily with random 5h delay, retention: 24h/30d/4w/6m/3y
- **ZFS**: nas pool snapshots -> Google Drive via rclone (daily incremental + quarterly full)
- **Syncthing**: continuous sync on nas

## Key Flake Inputs

- `nixpkgs` (25.11), `nixpkgs-unstable` -- available as `pkgs` and `pkgs-unstable`
- `home-manager` (25.11), `stylix` (25.11) -- user env and theming
- `nixos-hardware` -- hardware-specific optimizations
- `nixvim` -- declarative neovim (follows nixpkgs-unstable)
- `niri` -- Wayland compositor
- `agenix` + `agenix-rekey` -- secret management
- `deploy-rs` -- remote deployment
- `simple-nixos-mailserver` (25.11) -- mail server on ankka
- `nixarr` (custom fork: lajp/nixarr, cross-seed-fix branch) -- media stack
- `pia-nix`, `pia` -- PIA VPN integration
- `nur`, `nix-index-database` -- community packages and command lookup
- `yensid` -- build system proxy with load balancing across builders
- Custom projects: `lajp-fi` (website), `esn-ical` (calendar), `memegenerator`, `blmgr` (backlight)
- Editor plugins (non-flake): `testaustime-nvim`, `vimchant`, `tree-sitter-stlcpp`, `jj-nvim`, `golf`
- `dwm` (non-flake) -- dynamic window manager

## Notes

- When creating a service, always check if it can be added to prometheus and grafana
- Similarly, always check if it should be monitored by gatus
- Kernel upgrade on nas requires reboot, otherwise CUDA in jellyfin fails
- Secret management is done with agenix **rekey**, no `secrets.nix` like in plain agenix
- nixarr uses a custom fork (`cross-seed-fix` branch) for cross-seed support
- `t480` is not built in CI
- `monitoring-agent.nix` exists in services/ but is not imported — it's dead code. The active monitoring logic is in `prometheus.nix` (handles both central and agent modes via the `central` flag)
