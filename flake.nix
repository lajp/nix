{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pia-nix.url = "github:Atte/pia-nix";

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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
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

    jj-nvim = {
      url = "github:NicolasGB/jj.nvim";
      flake = false;
    };
  };

  outputs =
    {
      self,
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
      nixosModules.k9mail-link = import ./nixos/k9mail-link.nix;

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
            services.attic.enable = true;
            # Hosts the cache, so it upgrades first. Kernel/nvidia changes break
            # CUDA until a (manual, ZFS unlock) reboot, so those are only staged.
            services.auto-upgrade = {
              enable = true;
              dates = "03:00";
              stageKernel = true;
            };
            services.dyndns = {
              enable = true;
              domains = [
                "jellyfin.lajp.fi"
                "jellyseerr.lajp.fi"
                "pilvi.lajp.fi"
                "cache.lajp.fi"
              ];
            };
            hardware.zfs.enable = true;
            services.zfs-backup = {
              enable = true;
              pool = "naspool";
            };
            services.prometheus.enable = true;
            services.resourceLimits.enable = true;
            services.k9mail-link.enable = true;
            services.open-webui.enable = true;
            services.searx.enable = true;
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
                "seerr"
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
            services.auto-upgrade.enable = true;
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
            services.backup-notify.enable = true;
            services.auto-upgrade.enable = true;
            services.automatic-timezone.enable = true;
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
            #hardware.rtl-sdr.enable = true;
            hardware.backlight = {
              enable = true;
              gpu = "amd";
            };
            rickroll.enable = true;
            dreamlauncher.enable = true;
            #virt-manager.enable = true;
            services.yensid.enable = true;
          };

          userConfig = {
            editors.nvim = {
              enable = true;
              testaustime.enable = true;
            };
            gui = {
              enable = true;
              minecraft.enable = true;
            };
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
            services.auto-upgrade.enable = true;
          };
        };
        minecraft = mkHost {
          extraModules = with inputs.nixos-hardware.nixosModules; [
            common-pc
            common-cpu-intel
          ];

          systemConfig = {
            core = {
              hostname = "minecraft";
              server = true;
            };

            services.ssh.enable = true;
            services.tailscale.enable = true;
            # Disabled for now; world data and the service account are kept.
            services.minecraft = {
              enable = false;
              serverPort = 22305;
              serverProperties.white-list = true;
              whitelist.Luukasa_ = "edc99f1e-d09b-4da6-be52-97fbdf2cf375";
              operators.Luukasa_ = "edc99f1e-d09b-4da6-be52-97fbdf2cf375";
            };
            services.valheim.enable = true;
            services.dyndns = {
              enable = true;
              domains = [ "mc.portfo.rs" ];
            };
            services.prometheus = {
              enable = true;
              role = "minecraft";
              location = "jmt";
            };
            services.auto-upgrade.enable = true;
          };
        };
        ankka = mkHost {
          system = "aarch64-linux";

          systemConfig = {
            core = {
              hostname = "ankka";
              server = true;
            };

            hardware.memory.enable = true;

            services.ssh.enable = true;
            services.gatus.enable = true;
            services.mailserver.enable = true;
            services.webmail.enable = true;
            services.emailTelegramBridge.enable = true;
            services.headscale.enable = true;
            services.hedgedoc.enable = true;
            services.tailscale.enable = true;
            services.website.enable = true;
            services.ip-echo.enable = true;
            services.formicer-website.enable = false;
            services.cheese.enable = true;
            services.matrix.enable = true;
            services.screego.enable = true;
            services.coredns.enable = true;
            services.prometheus = {
              enable = true;
              central = true;
              location = "hetzner";
            };
            services.slop.enable = true;
            services.thelounge.enable = true;
            # Runs an hour after proxy-pi so the two DNS hosts never switch together.
            services.auto-upgrade = {
              enable = true;
              dates = "05:00";
            };
          };
        };
      };

      agenix-rekey = agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.nixosConfigurations;
      };

      checks =
        let
          testPkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        {
          x86_64-linux = {
            zfs-backup = testPkgs.callPackage ./tests/zfs-backup.nix { };
            ankka-webmail-config =
              let
                lib = nixpkgs.lib;
                cfg = self.nixosConfigurations.ankka.config;
                address = local: domain: local + "@" + domain;
                expectedIdentities = [
                  (address "lajp" "lajp.fi")
                  (address "luukas" "portfo.rs")
                  (address "lajp" "portfo.rs")
                  (address "luukas" "portfors.fi")
                  (address "lajp" "portfors.fi")
                  (address "portfors" "formicer.com")
                  (address "luukas" "formicer.com")
                  (address "lajp" "iki.fi")
                  (address "luukas.portfors" "iki.fi")
                ];
                senderLoginMaps = "hash:/etc/postfix/vaccounts,hash:/etc/postfix/webmail_sender_login";
                check = assertion: message: if assertion then true else throw message;
                valid = lib.all (x: x) [
                  (check cfg.lajp.services.webmail.enable "ankka webmail module is not enabled")
                  (check cfg.services.roundcube.enable "roundcube is not enabled")
                  (check (cfg.services.roundcube.hostName == "webmail.lajp.fi") "roundcube hostname is wrong")
                  (check (lib.elem "virtuser_file" cfg.services.roundcube.plugins) "roundcube virtuser_file plugin is not enabled")
                  (check (
                    cfg.lajp.services.webmail.senderIdentities == expectedIdentities
                  ) "webmail sender identities changed unexpectedly")
                  (check (builtins.hasAttr "webmail.lajp.fi" cfg.services.nginx.virtualHosts) "webmail nginx vhost is missing")
                  (check (builtins.hasAttr "iki-smtp-password" cfg.age.secrets) "iki SMTP secret is missing")
                  (check (
                    cfg.services.postfix.submissionOptions.smtpd_sender_login_maps == senderLoginMaps
                  ) "submission sender login maps are wrong")
                  (check (
                    cfg.services.postfix.submissionsOptions.smtpd_sender_login_maps == senderLoginMaps
                  ) "submissions sender login maps are wrong")
                  (check (lib.any (
                    endpoint: endpoint.name == "Webmail" && endpoint.url == "https://webmail.lajp.fi/"
                  ) cfg.services.gatus.settings.endpoints) "Gatus webmail endpoint is missing")
                ];
              in
              testPkgs.runCommand "ankka-webmail-config" { inherit valid; } ''
                mkdir -p $out
              '';
          };
        };

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
          pkgs.age-plugin-yubikey
          pkgs.nh
        ];
      };
    });
}
