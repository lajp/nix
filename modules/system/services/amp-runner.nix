{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.amp-runner;
  home = "/var/lib/amp-runner";
  # 26.05's amp-cli is from July 2025. The package turns off self-updates
  # (AMP_SKIP_UPDATE_CHECK=1); it updates with the weekly flake update.
  amp = pkgs-unstable.amp-cli;
in
{
  options.lajp.services.amp-runner.enable = mkEnableOption "Amp runner";

  config = mkIf cfg.enable {
    users.users.amp-runner = {
      isSystemUser = true;
      group = "amp-runner";
      description = "Amp runner";
      inherit home;
      createHome = true;
      homeMode = "700";
      # A real shell, for `sudo -iu amp-runner` and for the threads' commands.
      shell = pkgs.bashInteractive;
      packages = [ amp ];
    };
    users.groups.amp-runner = { };

    systemd.tmpfiles.rules = [ "d ${home}/src 0700 amp-runner amp-runner -" ];

    systemd.services.amp-runner = {
      description = "Amp runner";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      # What the threads' shell commands find; projects bring the rest with `nix develop`.
      path = [
        amp
        config.nix.package
      ]
      ++ (with pkgs; [
        bashInteractive
        git
        openssh
        rsync
        curl
        jq
        gnutar
        gzip
        procps
        which
      ]);

      serviceConfig = {
        User = "amp-runner";
        Group = "amp-runner";
        # Serves ~/src and every Git checkout cloned into it, picked up as they appear.
        WorkingDirectory = "${home}/src";
        ExecStart = "${lib.getExe amp} --no-tui --runner-id hetzner --amp-env --discover-dirs";
        Restart = "on-failure";
        RestartSec = "30s";

        # Its home is the only writable path. /home, /root and /run/user are
        # hidden, and so are other users' processes.
        ProtectSystem = "strict";
        ReadWritePaths = [ home ];
        ProtectHome = true;
        ProtectProc = "invisible";
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        RestrictSUIDSGID = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        SystemCallArchitectures = "native";
        UMask = "0077";
        # No MemoryDenyWriteExecute: Amp's JavaScript engine needs its JIT.

        # Leaves room for mail, Matrix and Prometheus.
        MemoryHigh = "3G";
        MemoryMax = "4G";
        CPUWeight = 50;
      };
    };
  };
}
