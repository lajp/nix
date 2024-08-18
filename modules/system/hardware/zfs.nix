{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.hardware.zfs;
in {
  options.lajp.hardware.zfs.enable = mkEnableOption "Enable ZFS support";
  config = mkIf cfg.enable {
    services.zfs.autoScrub.enable = true;

    boot = {
      supportedFilesystems = ["zfs"];
      zfs.forceImportRoot = false;
      kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      kernelParams = ["zfs.zfs_arc_max=12884901888"];
      extraModprobeConfig = ''
        options zfs l2arc_noprefetch=0 l2arc_write_boost=33554432 l2arc_write_max=16777216 zfs_arc_max=2147483648
      '';
    };

    environment.systemPackages = with pkgs; [
      zfs
    ];
  };
}
