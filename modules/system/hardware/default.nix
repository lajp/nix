{config, ...}: {
  imports = [
    ./zfs.nix
  ];

  services.upower.enable = !config.lajp.core.server;
}
