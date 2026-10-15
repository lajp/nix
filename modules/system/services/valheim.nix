{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.lajp.services.valheim;

  stateDir = "/var/lib/valheim";
  installDir = "${stateDir}/server";
  # Steam app ID of the dedicated server; the game itself is 892970, which the
  # server binary expects in $SteamAppId at runtime.
  serverAppId = "896660";
  gameAppId = "892970";

  startScript = pkgs.writeShellScript "valheim-start" ''
    set -eu
    cd ${installDir}
    export LD_LIBRARY_PATH=${installDir}/linux64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export SteamAppId=${gameAppId}
    exec ./valheim_server.x86_64 \
      -nographics -batchmode \
      -name ${lib.escapeShellArg cfg.serverName} \
      -world ${lib.escapeShellArg cfg.worldName} \
      -port ${toString cfg.port} \
      -public ${if cfg.public then "1" else "0"} \
      -savedir ${stateDir}/save \
      -password "$(< "$CREDENTIALS_DIRECTORY/password")" \
      ${lib.optionalString cfg.crossplay "-crossplay"}
  '';
in
{
  options.lajp.services.valheim = {
    enable = mkEnableOption "Valheim dedicated server (installed and updated via steamcmd)";

    serverName = mkOption {
      description = "Name shown in the server browser. The password must not contain it.";
      type = types.str;
      default = "Vaasa";
    };

    worldName = mkOption {
      description = "World to load from (or create in) the save directory.";
      type = types.str;
      default = "Sepänkylä";
    };

    port = mkOption {
      description = "UDP port the server listens on. The server also uses port + 1 for Steam queries.";
      type = types.port;
      default = 2456;
    };

    public = mkOption {
      description = "List the server in the in-game community server browser.";
      type = types.bool;
      default = false;
    };

    crossplay = mkOption {
      description = "Enable crossplay (PlayFab relay). Lets Xbox/Game Pass players join and works without a port forward.";
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.enable {
    lajp.portRequests.valheim = cfg.port;
    lajp.portRequests.valheim-query = cfg.port + 1;

    age.secrets.valheim-password.rekeyFile = ../../../secrets/valheim-password.age;

    users.users.valheim = {
      description = "Valheim server service user";
      isSystemUser = true;
      group = "valheim";
      home = stateDir;
    };
    users.groups.valheim = { };

    networking.firewall.allowedUDPPorts = [
      cfg.port
      (cfg.port + 1)
    ];

    systemd.services.valheim = {
      description = "Valheim dedicated server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # steamcmd keeps its Steam root under ~/.local/share/Steam
      environment.HOME = stateDir;

      serviceConfig = {
        User = "valheim";
        Group = "valheim";
        StateDirectory = "valheim";
        WorkingDirectory = stateDir;
        LoadCredential = "password:${config.age.secrets.valheim-password.path}";

        # Install or update to the latest build on every start. Clients refuse to
        # join a server running a different version, so a pinned fixed-output
        # derivation would break on every Valheim patch until its hash is bumped.
        ExecStartPre = "${pkgs.steamcmd}/bin/steamcmd +force_install_dir ${installDir} +login anonymous +app_update ${serverAppId} validate +quit";
        # The server binary is a generic-Linux Unity build, so it needs an FHS env.
        ExecStart = "${pkgs.steam-run}/bin/steam-run ${startScript}";

        # The server only saves the world when interrupted with SIGINT.
        KillSignal = "SIGINT";
        # The first start downloads ~1 GB through steamcmd.
        TimeoutStartSec = "15min";
        TimeoutStopSec = "2min";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
  };
}
