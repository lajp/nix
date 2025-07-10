{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.gatus;
in
{
  options.lajp.services.gatus.enable = mkEnableOption "Enable gatus";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    age.secrets.gatus-env.rekeyFile = ../../../secrets/gatus-env.age;

    services = {
      gatus = {
        enable = true;
        environmentFile = config.age.secrets.gatus-env.path;

        settings = {
          ui = {
            logo = "https://lajp.fi/static/apple-touch-icon.png";
            title = "lajp | status";
            description = "A status page for my services";
          };

          alerting.email = {
            from = "alerts@lajp.fi";
            username = "alerts@lajp.fi";
            password = "\${EMAIL_PASSWORD}";
            host = "mail.portfo.rs";
            port = 587;
            to = "lajp" + "@lajp.fi";
            default-alert = {
              enabled = true;
              send-on-resolved = true;
            };
          };

          endpoints = [
            {
              name = "website";
              group = "public";
              url = "https://lajp.fi";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Jellyfin";
              group = "public";
              url = "https://jellyfin.lajp.fi/health";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Jellyseerr";
              group = "public";
              url = "https://jellyseerr.lajp.fi/api/v1/status";
              client.timeout = "20s";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Nextcloud";
              group = "public";
              url = "https://pilvi.lajp.fi/status.php";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "mailserver";
              group = "public";
              url = "starttls://mail.portfo.rs:587";
              interval = "3m";
              client.timeout = "5s";
              conditions = [
                "[CONNECTED] == true"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Vaultwarden";
              group = "internal";
              url = "https://vault.intra.lajp.fi/api/alive";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "iLO";
              group = "internal";
              url = "https://ilo.intra.lajp.fi";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "router";
              group = "internal";
              url = "https://router.intra.lajp.fi";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            # TODO: add nixarr services
            {
              name = "sonarr";
              group = "internal";
              url = "http://100.64.0.2:8989/ping";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "prowlarr";
              group = "internal";
              url = "http://100.64.0.2:9696/ping";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "radarr";
              group = "internal";
              url = "http://100.64.0.2:7878/ping";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "bazarr";
              group = "internal";
              url = "http://100.64.0.2:6767";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [ { type = "email"; } ];
            }
          ];
        };
      };

      nginx.virtualHosts."status.lajp.fi" = {
        locations."/".proxyPass = "http://localhost:${toString config.services.gatus.settings.web.port}";
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
