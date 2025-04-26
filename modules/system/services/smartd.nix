{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.smartd;
in
{
  options.lajp.services.smartd.enable = mkEnableOption "Enable smartd monitoring";

  config = mkIf cfg.enable {
    age.secrets.alerts-email.rekeyFile = ../../../secrets/alerts-email.age;

    services.smartd = {
      enable = true;
      autodetect = true;
      notifications.mail = {
        enable = true;
        sender = "alerts@lajp.fi";
        recipient = "lajp@lajp.fi";
      };
      notifications.test = true;
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
  };
}
