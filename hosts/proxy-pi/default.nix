{ config, ... }:
{
  raspberry-pi-nix = {
    board = "bcm2711";
    libcamera-overlay.enable = false;
    serial-console.enable = false;
  };

  sdImage.compressImage = false;

  security.sudo.wheelNeedsPassword = false;
  services.tailscale.enable = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmHiYwlEQEFvgn1RYWaFhQroCjPUwKKHrahR9UhrgCB";

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
          proxyPass = "https://192.168.1.38";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "router.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.1.1";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };

      "vault.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.1.35:8222";
          proxyWebsockets = true;
        };

        forceSSL = true;
        useACMEHost = "intra.lajp.fi";
      };
    };
  };
}
