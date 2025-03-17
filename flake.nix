{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix.url = "github:Atte/pia-nix";

    pia.url = "github:Fuwn/pia.nix";

    agenix.url = "github:ryantm/agenix";

    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
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

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    testaustime-nvim = {
      url = "github:Testaustime/testaustime.nvim";
      flake = false;
    };

    vimchant = {
      url = "github:vim-scripts/Vimchant";
      flake = false;
    };

    raspberry-pi-nix.url = "github:nix-community/raspberry-pi-nix";

    lajp-fi = {
      url = "github:lajp/lajp.fi";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs =
    {
      self,
      deploy-rs,
      agenix-rekey,
      ...
    }@inputs:
    let
      user = import ./lib/user.nix { inherit inputs; };
      utils = import ./lib/system.nix { inherit user inputs; };
      inherit (utils) mkHost;
    in
    {
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
            services.tvheadend.enable = false;
            services.transmission.enable = true;
            services.sonarr.enable = true;
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
              users = [
                "lajp"
                "petri"
              ];
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
            services.pia.enable = true;
            hardware.sound.enable = true;
            hardware.bluetooth.enable = true;
            hardware.rtl-sdr.enable = true;
            virtualisation.podman.enable = false;
            hardware.backlight.enable = true;
            rickroll.enable = true;
          };

          userConfig = {
            editors.nvim.enable = true;
          };
        };
        framework = mkHost {
          extraModules = with inputs.nixos-hardware.nixosModules; [
            framework-13-7040-amd
          ];

          systemConfig = {
            core.hostname = "framework";

            services.restic.enable = true;
            services.niri.enable = true;
            services.ssh.enable = true;
            services.pia.enable = true;
            hardware.sound.enable = true;
            hardware.bluetooth.enable = true;
            hardware.rtl-sdr.enable = true;
            hardware.backlight = {
              enable = true;
              gpu = "amd";
            };
            rickroll.enable = true;
          };

          userConfig.editors.nvim.enable = true;
        };
        proxy-pi = mkHost {
          system = "aarch64-linux";

          extraModules = with inputs.raspberry-pi-nix.nixosModules; [
            raspberry-pi
            sd-image
          ];

          systemConfig = {
            core = {
              hostname = "proxy-pi";
              server = true;
            };

            services.ssh.enable = true;
          };
        };
      };

      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
      };

      deploy.nodes = {
        proxy-pi = {
          hostname = "proxy-pi";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.proxy-pi;
          };
        };

        nas = {
          hostname = "nas";
          profiles.system = {
            user = "root";
            interactiveSudo = true;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nas;
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      pi-img = self.nixosConfigurations.proxy-pi.config.system.build.sdImage;
    };
}
