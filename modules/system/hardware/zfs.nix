{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.hardware.zfs;
in
{
  options.lajp.hardware.zfs.enable = mkEnableOption "Enable ZFS support";
  config = mkIf cfg.enable {
    age.secrets.alerts-email.rekeyFile = ../../../secrets/alerts-email.age;

    services.zfs = {
      autoScrub.enable = true;
      autoSnapshot.enable = true;
      zed = {
        enableMail = true;
        settings = {
          ZED_EMAIL_ADDR = "lajp@lajp.fi";
        };
      };
    };

    programs.msmtp = {
      enable = true;
      defaults = {
        port = 587;
        tls = true;
      };

      accounts.default = {
        user = "alerts@lajp.fi";
        host = "mail.portfo.rs";
        from = "alerts@lajp.fi";
        auth = true;
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.age.secrets.alerts-email.path}";
      };
    };

    boot = {
      supportedFilesystems = [ "zfs" ];
      zfs.forceImportRoot = false;
      kernelParams = [ "zfs.zfs_arc_max=2147483648" ]; # 2 GB
      extraModprobeConfig = ''
        # Disable prefetching (saves memory at cost of sequential read speed)
        options zfs zfs_prefetch_disable=1

        # Make sure no ARC inflation happens via module options
        options zfs zfs_arc_min=16777216   # 16 MB min ARC
        options zfs zfs_arc_meta_limit=268435456  # 256 MB metadata limit

        # Disable any L2ARC overhead unless you actually add an SSD cache
        options zfs l2arc_noprefetch=1
        options zfs l2arc_feed_again=0
        options zfs l2arc_write_max=0
        options zfs l2arc_write_boost=0
      '';
    };

    environment.systemPackages = with pkgs; [
      zfs
    ];
  };
}
