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
  cfg = config.services.k9mail-link;
in
{
  options.services.k9mail-link = {
    enable = mkEnableOption "k9mail-link Telegram bot";

    package = mkPackageOption pkgs "k9mail-link" { };

    envFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/k9mail-link.env";
      description = ''
        Environment file for the service. Must contain `TELOXIDE_TOKEN=...`.
      '';
    };

    newPrefix = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://example.com/";
      description = ''
        Prefix used to rewrite messages that start with `https://localhost/`.
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        RUST_LOG = "info";
      };
      description = "Additional environment variables for the service.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.envFile != null;
        message = "services.k9mail-link.envFile must be set when services.k9mail-link.enable = true";
      }
      {
        assertion = cfg.newPrefix != null && cfg.newPrefix != "";
        message = "services.k9mail-link.newPrefix must be a non-empty string when services.k9mail-link.enable = true";
      }
    ];

    systemd.services.k9mail-link = {
      enable = true;
      description = "k9mail-link Telegram bot";

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = { NEW_PREFIX = cfg.newPrefix; } // cfg.environment;

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/k9mail-link";
        EnvironmentFile = cfg.envFile;
        Restart = "always";
        RestartSec = "5s";

        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };
  };
}
