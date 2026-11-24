{ config, pkgs, ... }:
{
  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Filesystem configuration for SD card
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };

  # Useful Pi utilities
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  security.sudo.wheelNeedsPassword = false;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGMNPji+648seLfAjRRB+GUGGWn0d84E8onbyDEZPHdt";

  age.secrets.cloudflare-env.rekeyFile = ../../secrets/cloudflare-env.age;

  security.acme = {
    acceptTerms = true;
    defaults.email = "lajp@iki.fi";

    certs."intra.lajp.fi" = {
      inherit (config.services.nginx) group;

      domain = "intra.lajp.fi";
      extraDomainNames = [ "*.intra.lajp.fi" ];
      dnsProvider = "cloudflare";
      dnsResolver = "carla.ns.cloudflare.com";
      webroot = null;
      environmentFile = config.age.secrets.cloudflare-env.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "ilo.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "https://192.168.8.107";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "router.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "https://192.168.8.1";
          proxyWebsockets = true;
          # GL.iNet firmware (oui-access.lua) answers 403 to any Host header
          # it doesn't recognise, so present the request as if made to the
          # LAN IP. The recommended settings would add a second `Host $host`.
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Host 192.168.8.1;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "miniminer.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.8.225";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "vault.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.8.104:8222";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "adguard.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.lajp.ports.adguardhome}";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "chat.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.8.104:8223";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "searx.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.8.104:8888";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };
    };
  };

  system.stateVersion = "25.11";
}
