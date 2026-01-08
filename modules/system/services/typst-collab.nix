{
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
    ;
  cfg = config.lajp.services.typst-collab;
  homeDir = "/var/lib/typst-collab";
  dataDir = "${homeDir}/data";
in
{
  options.lajp.services.typst-collab = {
    enable = mkEnableOption "Enable typst-collab SSHFS access";

    sourcePath = mkOption {
      description = "Source path to bind mount for SSHFS access";
      type = types.path;
      example = "/home/lajp/git/typst-project";
    };

    authorizedKeys = mkOption {
      description = "SSH public keys authorized to connect as typst-collab";
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    users.users.typst-collab = {
      isSystemUser = true;
      group = "typst-collab";
      home = homeDir;
      createHome = false; # Don't auto-create; chroot requires root ownership
      shell = "/run/current-system/sw/bin/nologin";
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    users.groups.typst-collab = { };

    # Bind mount the source path to the user's data directory (read-only)
    fileSystems.${dataDir} = {
      device = cfg.sourcePath;
      options = [ "bind" "ro" ];
    };

    # Configure OpenSSH to restrict typst-collab to SFTP-only with chroot
    services.openssh.extraConfig = ''
      Match User typst-collab
        ForceCommand internal-sftp
        ChrootDirectory ${homeDir}
        AllowTcpForwarding no
        X11Forwarding no
        PermitTunnel no
        AllowAgentForwarding no
    '';

    # Ensure proper ownership for chroot (root must own the chroot directory)
    systemd.tmpfiles.rules = [
      "d ${homeDir} 0755 root root -"
      "d ${dataDir} 0755 typst-collab typst-collab -"
    ];
  };
}
