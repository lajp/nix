{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
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

    lajp-fi = {
      url = "github:lajp/lajp.fi";
    };

    esn-ical.url = "github:lajp/esn-ical";

    memegenerator = {
      url = "github:lajp/memegenerator";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";

    nixarr = {
      #url = "github:rasmus-kirk/nixarr/main";
      url = "github:lajp/nixarr/cross-seed-fix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    golf = {
      url = "github:vuciv/golf";
      flake = false;
    };

    tree-sitter-stlcpp = {
      url = "github:aalto-opencs/tree-sitter-stlcpp";
      flake = false;
    };

    yensid.url = "github:garnix-io/yensid";
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
            services.prometheus.enable = true;
            services.resourceLimits.enable = true;
            hardware.memory = {
              enable = true;
              zramPercent = 50;
              earlyoomPrefer = [
                "jellyfin"
                "radarr"
                "sonarr"
                "lidarr"
                "prowlarr"
                "bazarr"
                "transmission"
                "jellyseerr"
              ];
              earlyoomAvoid = [
                "sshd"
                "nginx"
                "prometheus"
              ];
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
            services.prometheus = {
              enable = true;
              role = "nas";
              location = "vaasa";
            };
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
            services.ssh = {
              enable = true;
              port = 2222;
            };
            services.tailscale.enable = true;
            services.vpn = {
              braiins.enable = true;
              airvpn.enable = true;
              vaasa = {
                enable = true;
                autostart = true;
              };
              vaasa2 = {
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
            dreamlauncher.enable = true;
            virt-manager.enable = true;
            services.yensid.enable = true;
            services.typst-collab = {
              enable = true;
              sourcePath = "/home/lajp/git/work/mepl/mepl-typst";
              authorizedKeys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0xmxXd5K3pgTCrwMmKwILyOJb9KD9PWvQfbzncPUJLpb7XSoPS8Iwnrn9+VdXHFLKQvQBI33Bk+l7Yj0AQJX1/wOoMnNmfxq/fzKCCSvBocu/x8SJVyqRCksLtHTrf0xfcFM9YSpMouIrpWqXGEz1qDt7j8v4nYmp1NrS8Sw2IW99m7RMtzPjB49OzRe1sggqCpDfaqysAjm7VjnLuib8CdrhaGnQ3z7Jl8Dt2IWXyfk/SVZAqJzjcBF9aVnYfskn4Kes0D9bO/+dTHoWmVqYokjOYKMvx+o8s6Ydk3S2Ej+/RMEPTRoTez0cXvjXrpQG9Ke0PMPt3EjvvdpxmWbL6/+OZoQ1dxOpqtc5S6hQ9TLR1j6FrhvvJRf5mHPr8DV+a1Sg/ptiZ+8RK+WDN0RlIsLO+GnKS0gyzzqfrP41lDt1jSD2JTnAv2ACT25TANGIiYU9GNHsyuph1NEeTJICeyIOqkB8+ABKBKRH5JjdOROgwxcomEdBcuXGcgP8VbQaE6hWA30AVOGt5klRFA3bE4zhdLNnp7Hn26A43gBgbZp33xVhbqoNyW+qWb32A7Nd5KWMqa0p3ZllYsNRSOgOhqciNzQjsfolYXP8vUG3sCWkwtZBk4A5Cvm+Jhd0v+SFSm9rDyosbc7v0MN6rgBxZIYfYlMLvaMiyPWuxNZ6wQ=="
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiDxF/PZcYfX6N3CQOdQdW0PTPN7tgmwL6RPFDBlJURsxiTlmlRygjMVjrnxbIN9KGIP2p3hUKxensm0ftbl3fvdBG3nUnreGZAUQ7prSrli3tv+WITPFdONtDqcrMlYXbBy51/kFLUQMV7wBYurM/4bW/BOXtNZdk8/dLyCqAr1ynZmXFFHEB3APtlxaLlsyHEER5Nj7WDlxpFUxOqzasPg8MMGKQeN+d2TbUq1s0YDVwmk4F+Zqfj0H9AAYYt4zkiKbCkzTrJXk9snBPAyUot8jkAjZW5nu7quVoiHvWY3335iaa4o2JWDkm6/QEXYzKIbi865jOr3A5DRFytNFQJ7nmXfSNWAJmblSlatlszQLwmTLP5wkV+3zbRHv7WuvWivR76Xy0uyK331UvqrRbNha+EbVoWP5DyFnichBH7B/IgHkLHQJIuYiQBZ2ZwTuVpEoxyCUyl9acDtmUZvuomTAEjLRQElnhRo8iyDf92dl19Q9dG/1RWqLXUEDVBcLrlk89aEnIk7DuwvmVWzWM+On9S8ojH04TgRJM5ZkbQLAIqW5AkLqY6CP5Gzknsh7F4fl5Mq0FZlCOtFzxR+YgIn4IGndonm8/iqDQjJNOWVysFdNRPisPSR5AO5TiuxZSOcCuRkS56cZTHKjdqZS8CxiCfs2ZPlzMnzKJSNDXxQ=="
              ];
            };
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

          extraModules = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ];

          systemConfig = {
            core = {
              hostname = "proxy-pi";
              server = true;
            };

            services.ssh.enable = true;
            services.tailscale.enable = true;
            services.adguardhome.enable = true;
            services.prometheus = {
              enable = true;
              role = "proxy";
            };
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
            services.emailTelegramBridge.enable = true;
            services.headscale.enable = true;
            services.hedgedoc.enable = true;
            services.tailscale.enable = true;
            services.website.enable = true;
            #services.memegenerator.enable = true;
            services.formicer-website.enable = false;
            services.cheese.enable = true;
            # NOTE: vulnerable and dropped from nixpkgs
            # services.crabfit.enable = true;
            services.prometheus = {
              enable = true;
              central = true;
              location = "hetzner";
            };
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

        #nixos-dev = {
        #  hostname = "nixos-dev";
        #  profiles.system = {
        #    user = "root";
        #    sshUser = "lajp";
        #    interactiveSudo = true;
        #    remoteBuild = true;
        #    path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos-dev;
        #  };
        #};

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
          pkgs.nh
        ];
      };
    });
}
