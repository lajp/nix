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
      kernelParams = [ "zfs.zfs_arc_max=12884901888" ];
      extraModprobeConfig = ''
        options zfs l2arc_noprefetch=0 l2arc_write_boost=33554432 l2arc_write_max=16777216 zfs_arc_max=2147483648
      '';
    };

    environment.systemPackages = with pkgs; [
      zfs
    ];
  };
}
