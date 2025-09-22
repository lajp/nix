{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mkPackageOption
    ;
  cfg = config.services.ilmomasiina;
in
{
  options.services.ilmomasiina = {
    enable = mkEnableOption "Enable ilmomasiina";

    user = mkOption {
      default = "ilmomasiina";
      example = "signups";
      description = "The user that runs the service";
      type = types.str;
    };

    createDatabase = mkOption {
      default = true;
      example = false;
      description = "Create the database locally";
      type = types.bool;
    };

    package = mkPackageOption pkgs "ilmomasiina" { };

    envFile = mkOption {
      example = "/var/ilmomasiina/env";
      description = "The .env file containing the configuration, should be used to set secrets, see https://github.com/Tietokilta/ilmomasiina/blob/dev/.env.example for more details";
      type = types.path;
    };

    environment = mkOption {
      example = {
        PORT = "3000";
        ENFORCE_HTTPS = "false";

        SIGNUP_CONFIRM_MINS = "30";
        SIGNUP_CONFIRM_AFTER_CLOSE = "true";
        ANONYMIZE_AFTER_DAYS = "180";
        HIDE_EVENT_AFTER_DAYS = "180";
        DELETION_GRACE_PERIOD_DAYS = "14";

        TRUST_PROXY = "true";
        APP_TIMEZONE = "Europe/Helsinki";

        MAIL_FROM = "Ilmomasiina <no-reply@example.org>";
        MAIL_DEFAULT_LANG = "en";

        BASE_URL = "https://example.com";
      };
      description = "App runtime environment, can be used to set configuration, see https://github.com/Tietokilta/ilmomasiina/blob/dev/.env.example for more details";
      default = { };
      type = types.attrsOf types.str;
    };
  };

  config = mkIf cfg.enable {
    services.postgresql = mkIf cfg.createDatabase {
      enable = true;

      ensureUsers = [
        {
          name = "${cfg.user}";
          ensureDBOwnership = true;
        }
      ];

      ensureDatabases = [ "${cfg.user}" ];
    };

    systemd.services.ilmomasiina = {
      enable = true;
      description = "ilmomasiina";

      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];

      environment = (
        {
          NODE_ENV = "production";
          DB_HOST = "/run/postgresql";
          DB_DIALECT = "postgres";
          DB_USER = cfg.user;
          DB_PASSWORD = "";
          DB_DATABASE = cfg.user;
        }
        // cfg.environment
      );

      serviceConfig = {
        DynamicUser = true;
        User = cfg.user;
        ExecStart = "${cfg.package}/bin/ilmomasiina";
        EnvironmentFile = cfg.envFile;
        Restart = "always";
      };
    };
  };
}
