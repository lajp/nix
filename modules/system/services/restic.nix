{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.restic;
  hostname = config.lajp.core.hostname;
  username = config.lajp.user.username;
  home = config.lajp.user.homeDirectory;
in {
  options.lajp.services.restic.enable = mkEnableOption "Enable restic";
  config = mkIf cfg.enable {
    age = {
      identityPaths = ["${home}/.ssh/id_ed25519"];
      secrets.restic = {
        file = ../../../secrets/restic-${hostname}.age;
        owner = username;
      };
    };

    services.restic.backups = {
      nas = {
        user = username;
        initialize = true;
        passwordFile = config.age.secrets.restic.path;

        paths = [
          "/home/${username}"
        ];
        extraBackupArgs = [
          "--exclude-caches"
        ];
        exclude = [
          "/home/*/.cache"
        ];
        pruneOpts = [
          "--keep-hourly 24"
          "--keep-daily 30"
          "--keep-weekly 4"
          "--keep-monthly 6"
          "--keep-yearly 3"
        ];

        repository = "sftp:${username}@nas:/media/luukas/Backups/${config.lajp.core.hostname}";
        timerConfig = {
          OnCalendar = "00:05";
          RandomizedDelaySec = "5h";
        };
      };
    };
  };
}
