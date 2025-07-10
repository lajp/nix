{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.lajp.services.nextcloud;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.lajp.services.nextcloud.enable = mkEnableOption "Enable nextcloud";

  config = mkIf cfg.enable {
    age.secrets.nextcloud.rekeyFile = ../../../secrets/nextcloud.age;
    age.secrets.nextcloud-secrets.rekeyFile = ../../../secrets/nextcloud-secrets.age;

    services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
      forceSSL = true;
      enableACME = true;
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      extraApps = {
        inherit (pkgs.nextcloud31Packages.apps) forms;
      };
      hostName = "pilvi.lajp.fi";
      https = true;
      config = {
        dbtype = "sqlite";
        adminpassFile = config.age.secrets.nextcloud.path;
      };
      maxUploadSize = "5G";

      settings = {
        mail_from_address = "nextcloud";
        mail_domain = "lajp.fi";
        mail_smtpmode = "smtp";
        mail_sendmailmode = "smtp";
        mail_smtpauthtype = "PLAIN";
        mail_smtpauth = 1;
        mail_smtphost = "mail.portfo.rs";
        mail_smtpport = "587";
        mail_smtpsecure = "tls";
        mail_smtpname = "nextcloud@lajp.fi";
      };

      secretFile = config.age.secrets.nextcloud-secrets.path;
    };
  };
}
