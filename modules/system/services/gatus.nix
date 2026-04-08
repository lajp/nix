{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.gatus;
  port = config.lajp.ports.gatus;
in
{
  options.lajp.services.gatus.enable = mkEnableOption "Enable gatus";

  config = mkIf cfg.enable {
    lajp.portRequests.gatus = true;
    lajp.services.nginx.enable = true;

    age.secrets.gatus-env.rekeyFile = ../../../secrets/gatus-env.age;

    services = {
      gatus = {
        enable = true;
        environmentFile = config.age.secrets.gatus-env.path;

        settings = {
          web.port = port;
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
            to = "lajp+" + "alerts@lajp.fi";
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
              name = "Matrix";
              group = "public";
              url = "https://matrix.lajp.fi/_matrix/federation/v1/version";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Synapse status";
              group = "public";
              url = "https://matrix.lajp.fi/_matrix/client/versions";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Hedgedoc";
              group = "public";
              url = "https://pad.lajp.fi/status";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Headscale";
              group = "public";
              url = "https://headscale.lajp.fi/health";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Element";
              group = "public";
              url = "https://element.lajp.fi/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Grafana";
              group = "public";
              url = "https://grafana.lajp.fi/api/health";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "Attic";
              group = "public";
              url = "https://cache.lajp.fi/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "CHEESE";
              group = "public";
              url = "https://cheese.lajp.fi/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "ESN iCal";
              group = "public";
              url = "https://esn-ical.lajp.fi/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "luuk.as";
              group = "public";
              url = "https://luuk.as/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "IMAP";
              group = "public";
              url = "tls://mail.portfo.rs:993";
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
            {
              name = "lidarr";
              group = "internal";
              url = "http://100.64.0.2:8686/ping";
              conditions = [
                "[STATUS] == 200"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "AdGuard Home";
              group = "internal";
              url = "https://adguard.intra.lajp.fi/";
              conditions = [
                "[STATUS] == 200"
                "[CERTIFICATE_EXPIRATION] > 48h"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "AdGuard DNS";
              group = "internal";
              url = "100.64.0.3";
              interval = "3m";
              dns = {
                query-name = "lajp.fi";
                query-type = "A";
              };
              conditions = [
                "[DNS_RCODE] == NOERROR"
              ];
              alerts = [ { type = "email"; } ];
            }
            {
              name = "CoreDNS";
              group = "internal";
              url = "100.64.0.4";
              interval = "3m";
              dns = {
                query-name = "lajp.fi";
                query-type = "A";
              };
              conditions = [
                "[DNS_RCODE] == NOERROR"
              ];
              alerts = [ { type = "email"; } ];
            }
          ];
        };
      };

      nginx.virtualHosts."status.lajp.fi" = {
        locations."/".proxyPass = "http://localhost:${toString port}";
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
