{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix.url = "github:Atte/pia-nix";

    agenix.url = "github:ryantm/agenix";

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blmgr = {
      url = "github:lajp/blmgr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dwm = {
      url = "github:lajp/dwm";
      flake = false;
    };

    niri.url = "github:sodiboo/niri-flake";

    testaustime-nvim = {
      url = "github:Testaustime/testaustime.nvim";
      flake = false;
    };

    vimchant = {
      url = "github:vim-scripts/Vimchant";
      flake = false;
    };
  };

  outputs = {
    ...
  } @ inputs: let
    user = import ./lib/user.nix {inherit inputs;};
    utils = import ./lib/system.nix {inherit user inputs;};
    inherit (utils) mkHost;
  in {
    nixosConfigurations = {
      nas = mkHost {
        extraModules = with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-pc-ssd
          common-cpu-intel
          common-gpu-nvidia
        ];

        systemConfig = {
          core = {
            hostname = "nas";
            server = true;
          };

          services.ssh.enable = true;
          services.jellyfin.enable = true;
          services.tvheadend.enable = true;
          services.transmission.enable = true;
          services.jackett.enable = true;
          services.cross-seed.enable = true;
          services.testaustime-backup.enable = true;
          services.syncthing.enable = true;
          services.samba.enable = true;
          services.vaultwarden.enable = false;
          hardware.zfs.enable = true;
        };
      };
      vaasanas = mkHost {
        extraModules = with inputs.nixos-hardware.nixosModules; [
          common-pc
          common-cpu-intel
        ];

        systemConfig = {
          core = {
            hostname = "vaasanas";
            server = true;
          };

          services.ssh.enable = true;
          services.samba = {
            enable = true;
            users = ["lajp" "petri"];
          };
          hardware.zfs.enable = true;
        };
      };
      t480 = mkHost {
        extraModules = with inputs.nixos-hardware.nixosModules; [
          lenovo-thinkpad-t480
        ];

        systemConfig = {
          core = {
            hostname = "t480";
          };

          services.restic.enable = true;
          services.niri.enable = true;
          hardware.sound.enable = true;
          hardware.bluetooth.enable = true;
          hardware.rtl-sdr.enable = true;
        };

        userConfig = {
          editors.nvim.enable = true;
        };
      };
    };
  };
}
