{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    pia-nix.url = "github:Atte/pia-nix";

    agenix.url = "github:ryantm/agenix";

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
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
            server = false;
          };

          services.ssh.enable = true;
          services.jellyfin.enable = true;
          services.tvheadend.enable = true;
          services.transmission.enable = true;
          services.jackett.enable = true;
          services.testaustime-backup.enable = true;
          services.syncthing.enable = true;
          services.samba.enable = true;
          hardware.zfs.enable = true;
        };

        userConfig = {
          editors.nvim.enable = true;
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
    };
  };
}
