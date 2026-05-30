{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.screego;
  port = config.lajp.ports.screego;
in
{
  options.lajp.services.screego.enable = mkEnableOption "Enable screego";

  config = mkIf cfg.enable {
    lajp.portRequests.screego = true;
    lajp.services.nginx.enable = true;

    age.secrets.screego-users.rekeyFile = ../../../secrets/screego-users.age;
    age.secrets.screego-metrics-password = {
      rekeyFile = ../../../secrets/screego-metrics-password.age;
      owner = "prometheus";
      group = "prometheus";
      mode = "0400";
    };

    services.screego = {
      enable = true;
      openFirewall = true;
      settings = {
        SCREEGO_SERVER_ADDRESS = "127.0.0.1:${toString port}";
        SCREEGO_EXTERNAL_IP = "dns:screego.lajp.fi";
        SCREEGO_AUTH_MODE = "turn";
        SCREEGO_CLOSE_ROOM_WHEN_OWNER_LEAVES = "true";
        SCREEGO_PROMETHEUS = "true";
        SCREEGO_USERS_FILE = "%d/users";
      };
    };

    systemd.services.screego.serviceConfig.LoadCredential =
      "users:${config.age.secrets.screego-users.path}";

    services.nginx.virtualHosts."screego.lajp.fi" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };
      locations."/metrics" = {
        return = "404";
      };
    };
  };
}
