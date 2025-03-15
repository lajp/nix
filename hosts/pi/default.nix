{
  raspberry-pi-nix = {
    board = "bcm2711";
    libcamera-overlay.enable = false;
    serial-console.enable = false;
  };

  sdImage.compressImage = false;

  services.nginx = {
    enable = true;

    virtualHosts = {
      "ilo.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.1.38";
          proxyWebsockets = true;
        };
      };

      "router.intra.lajp.fi" = {
        locations."/" = {
          proxyPass = "http://192.168.1.1";
          proxyWebsockets = true;
        };
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;
  services.tailscale.enable = true;
}
