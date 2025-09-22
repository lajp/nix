{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix.url = "github:Atte/pia-nix";

    pia.url = "github:Fuwn/pia.nix";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
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

    memegenerator = {
      url = "github:lajp/memegenerator";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";

    nixarr = {
      #url = "github:rasmus-kirk/nixarr/main";
      url = "github:lajp/nixarr/cross-seed-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    golf = {
      url = "github:vuciv/golf";
      flake = false;
    };
  };

  outputs =
    {
      self,
      deploy-rs,
      agenix-rekey,
      flake-utils,
      nixpkgs,
      ...
    }@inputs:
    let
      user = import ./lib/user.nix { inherit inputs; };
      utils = import ./lib/system.nix { inherit user inputs; };
      inherit (utils) mkHost;
    in
    {
      overlays.default = import ./pkgs/default.nix;

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
            services.testaustime-backup.enable = true;
            services.syncthing.enable = true;
            services.samba.enable = true;
            services.vaultwarden.enable = true;
            services.tailscale.enable = true;
            services.smartd.enable = true;
            services.nixarr.enable = true;
            services.nextcloud.enable = true;
            services.dyndns = {
              enable = true;
              domains = [
                "jellyfin.lajp.fi"
                "jellyseerr.lajp.fi"
                "pilvi.lajp.fi"
              ];
            };
            hardware.zfs.enable = true;
            services.zfs-backup = {
              enable = false;
              pool = "naspool";
            };
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
            services.dyndns = {
              enable = true;
              domains = [ "mc.portfo.rs" ];
            };
            services.samba = {
              enable = true;
              users = [
                "lajp"
                "petri"
              ];
            };
            hardware.zfs.enable = true;
            services.tailscale.enable = true;
            services.smartd.enable = true;
          };
        };
        #nixos-dev = mkHost {
        #  extraModules = with inputs.nixos-hardware.nixosModules; [
        #    common-pc
        #    common-cpu-intel
        #  ];

        #  systemConfig = {
        #    core.hostname = "nixos-dev";
        #    services.ssh.enable = true;
        #    services.tailscale.enable = true;
        #  };

        #  userConfig = {
        #    editors.nvim.enable = true;
        #  };
        #};
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
            editors.nvim = {
              enable = true;
              testaustime.enable = true;
            };
            gui.enable = true;
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
            services.tailscale.enable = true;
            services.vpn = {
              braiins.enable = true;
              airvpn.enable = true;
              vaasa = {
                enable = true;
                autostart = true;
              };
            };
            hardware.sound.enable = true;
            hardware.bluetooth.enable = true;
            hardware.rtl-sdr.enable = true;
            hardware.backlight = {
              enable = true;
              gpu = "amd";
            };
            rickroll.enable = true;
            virt-manager.enable = true;
          };

          userConfig = {
            editors.nvim = {
              enable = true;
              testaustime.enable = true;
            };
            gui.enable = true;
          };
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
            services.tailscale.enable = true;
            services.adguardhome.enable = true;
          };
        };
        ankka = mkHost {
          system = "aarch64-linux";

          systemConfig = {
            core = {
              hostname = "ankka";
              server = true;
            };

            services.ssh.enable = true;
            services.gatus.enable = true;
            services.mailserver.enable = true;
            services.headscale.enable = true;
            services.tailscale.enable = true;
            services.website.enable = true;
            #services.memegenerator.enable = true;
            services.formicer-website.enable = false;
            services.cheese.enable = true;
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
            remoteBuild = false;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nas;
          };
        };

        vaasanas = {
          hostname = "vaasanas";
          profiles.system = {
            user = "root";
            sshUser = "lajp";
            interactiveSudo = true;
            remoteBuild = true;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vaasanas;
          };
        };

        nixos-dev = {
          hostname = "nixos-dev";
          profiles.system = {
            user = "root";
            sshUser = "lajp";
            interactiveSudo = true;
            remoteBuild = true;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos-dev;
          };
        };

        ankka = {
          hostname = "ankka";
          profiles.system = {
            user = "root";
            sshUser = "lajp";
            #remoteBuild = true;
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.ankka;
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      pi-img = self.nixosConfigurations.proxy-pi.config.system.build.sdImage;
    }
    // flake-utils.lib.eachDefaultSystem (system: rec {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          agenix-rekey.overlays.default
          self.overlays.default
        ];
      };
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.agenix-rekey
          deploy-rs.packages.${system}.default
        ];
      };
    });
}
