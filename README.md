# lajp's Nixfiles

This repository contains my NixOS configuration for various machines
together with my home-manager configuration.

Feel free to utilize my code in your own configuration.

For a detailed infrastructure overview with network diagrams, see [docs/INFRASTRUCTURE.md](./docs/INFRASTRUCTURE.md).

## Overview of the systems

The [flake.nix](./flake.nix) defines the following NixOS systems:
* **nas** — Main server for media, backups, and storage (Jellyfin, nixarr, Nextcloud, Syncthing, Samba, Vaultwarden, Attic cache, ZFS)
* **vaasanas** — Secondary server (NFS, Samba, ZFS)
* **t480** — ThinkPad T480 laptop with home-manager
* **framework** — Framework 13 AMD laptop with home-manager (daily driver)
* **proxy-pi** — Raspberry Pi 4 running AdGuard Home DNS and nginx reverse proxy for internal services
* **ankka** — Hetzner aarch64 server (central Prometheus/Grafana, Headscale, mail server, Matrix, HedgeDoc, Gatus, CoreDNS, CHEESE Ilmomasiina, website)

## Structure of the configuration

```
.
├── docs
│   └── INFRASTRUCTURE.md
├── hosts
│   ├── ankka
│   ├── framework
│   ├── nas
│   ├── proxy-pi
│   ├── t480
│   └── vaasanas
├── images
├── lib
├── modules
│   ├── system
│   │   ├── common
│   │   ├── gui
│   │   ├── hardware
│   │   ├── services
│   │   │   └── dashboards
│   │   └── virtualisation
│   └── user
│       ├── programs
│       │   ├── gui
│       │   └── neomutt
│       └── services
├── nixos
├── pkgs
└── secrets
```

* [/docs](./docs) contains infrastructure documentation and diagrams
* [/hosts](./hosts) contains host-specific configuration
* [/lib](./lib) contains the `mkHost` helper function
* [/modules/system](./modules/system) contains NixOS system modules (`lajp.*` options)
* [/modules/user](./modules/user) contains home-manager modules (`lajp.*` options)
* [/nixos](./nixos) contains standalone NixOS modules
* [/pkgs](./pkgs) contains custom package definitions


## Configuration of interest

### Agenix-rekey

I use [agenix-rekey](https://github.com/oddlama/agenix-rekey) for secret management.
Secrets are encrypted with a YubiKey-based master identity.

### Neovim

My [Neovim configuration](./modules/user/programs/neovim.nix)
is probably the single largest component of this repository.
I use [Nixvim](https://github.com/nix-community/nixvim) for configuring it.

It features:
* Finnish spell-checking with [Voikko](https://github.com/voikko)
* LSP-configuration
* [Testaustime-plugin](https://github.com/Testaustime/testaustime.nvim)
* and a bunch of other things

### Niri

I've recently adopted the [Niri](https://github.com/YaLTeR/niri) tiling and
scrolling Wayland compositor. I configure it through the
[niri-flake](https://github.com/sodiboo/niri-flake).

### Neomutt

I use Neomutt as my primary email client. My [neomutt configuration](./modules/user/programs/neomutt/)
together with my home-manager [accounts configuration](./modules/user/accounts.nix)
is quite sophisticated. It supports multiple accounts well and allows authenticating
to servers with oauth. Helpers for adding outlook and gmail accounts are provided.
Support for PGP is also included.

### YubiKey

I use my YubiKey for signing commits, authenticating through SSH, decrypting my passwords and even for logging into my computer and unlocking the disk encryption.

### Nixarr

I use [nixarr](https://github.com/rasmus-kirk/nixarr) to manage my media stack.
It runs Jellyfin, Transmission (in a VPN namespace), Sonarr, Radarr, Lidarr, Prowlarr,
Bazarr, Jellyseerr, and cross-seed for cross-seeding between private trackers.

### Monitoring

Distributed Prometheus monitoring across servers. The nas, vaasanas, and proxy-pi
hosts run Prometheus in agent mode, pushing metrics via remote write to the central
Prometheus instance on ankka. Grafana dashboards are provisioned for nginx, ZFS,
SMART, GPU, email, UPS, Headscale, HedgeDoc, and Matrix Synapse. Gatus provides
a public status page with email alerting.

### Port Management

A custom [port allocation system](https://discourse.nixos.org/t/nixos-port-allocation/74953)
(`modules/system/ports.nix`) that prevents port collisions across services. Ports can
be explicitly assigned or auto-allocated starting from 3000. Conflicts are reported
with source locations.

### Attic Binary Cache

A self-hosted [Attic](https://github.com/zhaofengli/attic) Nix binary cache running
on nas. CI builds are pushed to it, speeding up subsequent builds across the infrastructure.

### Headscale

Self-hosted [Headscale](https://github.com/juanfont/headscale) coordination server
on ankka, providing a private alternative to the Tailscale SaaS control plane.

### ZFS Cloud Backup

Incremental ZFS snapshot backup to cloud storage via rclone. Uses ZFS holds to track
backup state and only sends new data. Currently not operational.
