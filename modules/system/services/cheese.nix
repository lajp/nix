{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.cheese;
in
{
  imports = [
    ../../../nixos/ilmomasiina.nix
  ];

  options.lajp.services.cheese.enable = mkEnableOption "Enable CHEESE";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    age.secrets.cheese-env.rekeyFile = ../../../secrets/cheese-env.age;

    services.ilmomasiina = {
      enable = true;
      envFile = config.age.secrets.cheese-env.path;

      package = pkgs.ilmomasiina.override {
        BRANDING_HEADER_TITLE_TEXT = "CHEESE Ilmomasiina";
        BRANDING_HEADER_TITLE_TEXT_SHORT = "Ilmomasiina";
        BRANDING_FOOTER_GDPR_TEXT = "Privacy policy";
        BRANDING_FOOTER_GDPR_LINK = ""; # TODO
        BRANDING_FOOTER_HOME_TEXT = "";
        BRANDING_FOOTER_HOME_LINK = "";
        BRANDING_LOGIN_PLACEHOLDER_EMAIL = "postmaster@lajp.fi";

        css = ../../../cheese-palette.scss;
      };

      environment = {
        PORT = "3000";
        ENFORCE_HTTPS = "false";
        HOST = "localhost";

        SIGNUP_CONFIRM_MINS = "30";
        SIGNUP_CONFIRM_AFTER_CLOSE = "true";
        ANONYMIZE_AFTER_DAYS = "180";
        HIDE_EVENT_AFTER_DAYS = "180";
        DELETION_GRACE_PERIOD_DAYS = "14";

        TRUST_PROXY = "true";
        APP_TIMEZONE = "Europe/Prague";

        MAIL_FROM = "CHEESE <no-reply@lajp.fi>";
        MAIL_DEFAULT_LANG = "en";

        SMTP_HOST = "mail.portfo.rs";
        SMTP_PORT = "587";
        SMTP_USER = "no-reply@lajp.fi";
        SMTP_TLS = "false";

        BASE_URL = "https://cheese.lajp.fi";

        BRANDING_MAIL_FOOTER_TEXT = "CHEESE THROWERS";
        BRANDING_MAIL_FOOTER_LINK = "https://cheese.lajp.fi";
        BRANDING_ICAL_CALENDAR_NAME = "Ilmomasiina";
      };
    };

    services.nginx.virtualHosts."cheese.lajp.fi" = {
      locations."/".proxyPass = "http://localhost:3000";
      forceSSL = true;
      enableACME = true;
    };
  };
}
