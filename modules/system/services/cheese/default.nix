{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.cheese;

  privacy-policy = pkgs.runCommand "privacy-policy" { } ''
    ${pkgs.hxtools}/bin/rot13 ${./privacy-policy.txt} > $out
  '';
in
{
  imports = [
    ../../../../nixos/ilmomasiina.nix
  ];

  options.lajp.services.cheese.enable = mkEnableOption "Enable CHEESE";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    age.secrets.cheese-env.rekeyFile = ../../../../secrets/cheese-env.age;

    services.ilmomasiina = {
      enable = true;
      envFile = config.age.secrets.cheese-env.path;

      package =
        (pkgs.ilmomasiina.override {
          BRANDING_HEADER_TITLE_TEXT = "CHEESE Ilmomasiina";
          BRANDING_HEADER_TITLE_TEXT_SHORT = "Ilmomasiina";
          BRANDING_FOOTER_GDPR_TEXT = "Privacy policy";
          BRANDING_FOOTER_GDPR_LINK = "https://cheese.lajp.fi/privacy_policy.txt"; # TODO
          BRANDING_FOOTER_HOME_TEXT = "";
          BRANDING_FOOTER_HOME_LINK = "";
          BRANDING_LOGIN_PLACEHOLDER_EMAIL = "postmaster@lajp.fi";

          css = ./cheese-palette.scss;
          logo = ./logos/cheese_black.svg;
          favicon = ./logos/favicon.ico;
        }).overrideAttrs
          (prev: {
            postPatch = prev.postPatch + ''
              echo "${''
                User-agent: *
                Disallow: /''}" > packages/ilmomasiina-frontend/public/robots.txt

              cp "${privacy-policy}" packages/ilmomasiina-frontend/public/privacy_policy.txt
            '';
          });

      environment = {
        PORT = "3000";
        ENFORCE_HTTPS = "false";
        HOST = "127.0.0.1";

        SIGNUP_CONFIRM_MINS = "30";
        SIGNUP_CONFIRM_AFTER_CLOSE = "true";
        ANONYMIZE_AFTER_DAYS = "30";
        HIDE_EVENT_AFTER_DAYS = "30";
        DELETION_GRACE_PERIOD_DAYS = "14";

        TRUST_PROXY = "true";
        APP_TIMEZONE = "Europe/Prague";
        TZ = "Europe/Prague";

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
