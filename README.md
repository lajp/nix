# lajp's Nixfiles

This repository contains my NixOS configuration for various machines
together with my home-manager configuration.

Feel free to utilize my code in your own configuration.

## Overview of the systems

The [flake.nix](./flake.nix) a bunch of different NixOS systems
* nas, My main server for media, hot backups and other related stuff.
* vaasanas, My secondary server.
* t480, My daily-driver laptop with home-manager

## Structure of the configuration

```
.
├── hosts
│   ├── nas
│   ├── t480
│   └── vaasanas
├── images
├── lib
├── modules
│   ├── system
│   │   ├── common
│   │   ├── gui
│   │   ├── hardware
│   │   ├── services
│   │   └── virtualisation
│   └── user
│       ├── programs
│       │   └── neomutt
│       └── services
└── secrets
```

* [/hosts](./hosts) contains hosts-specific configuration
* [/lib](./lib) contains the `mkHost` helper function
* [/modules/system](./modules/system) contains system configuration
* [/modules/user](./modules/user) contains home-manager configuration


## Configuration of interest

### Agenix

I use [agenix](https://github.com/ryantm/agenix) for secret management both with and 
without the home-manager integration, depending on the system.

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

I use Neomutt as my primary email client. My [neomutt configuration]
together with my home-manager [accounts configuration](./modules/user/accounts.nix) 
is quite sophisticated. It supports multiple accounts well and allows authenticating 
to servers with oauth. Helpers for adding outlook and gmail accounts are provided.
Support for PGP is also included.

### YubiKey

I use my YubiKey for signing commits, authenticating through SSH, decrypting my passwords and even for logging into my computer.

### Transmission & Cross-Seed + Jackett + flaresolverr

I run Transmission in a separate network namespace as configured in the [pia-nix flake](https://github.com/Atte/pia-nix).

### Jellyfin & TvHeadend

I have configured Jellyfin to be able to play live-tv through tvheadend.
