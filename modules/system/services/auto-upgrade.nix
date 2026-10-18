{
  config,
  lib,
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
  cfg = config.lajp.services.auto-upgrade;
  inherit (config.lajp.core) server;

  # Switches to the system CI built and published on the deploy branch
  # (.github/workflows/ci.yml). Modelled on nix-community/infra's update.bash.
  script = pkgs.writeShellApplication {
    name = "auto-upgrade";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
      config.nix.package
      config.system.build.nixos-rebuild
      config.systemd.package
    ];
    text = ''
      host=${config.networking.hostName}
      operation=${cfg.operation}
      on_kernel_change=${cfg.onKernelChange}

      # shellcheck disable=SC2329 # invoked via trap
      report() {
        local rc=$? success=true error=
        [ -z "''${SKIP-}" ] || return 0
        [ "$rc" = 0 ] || { success=false; error="exit $rc, see journalctl -u auto-upgrade"; }
        curl -fsS -m 30 --retry 3 -o /dev/null -X POST -G \
          -H "Authorization: Bearer ''${GATUS_AUTO_UPGRADE_TOKEN:-}" \
          --data-urlencode "success=$success" --data-urlencode "error=$error" \
          "https://status.lajp.fi/api/v1/endpoints/auto-upgrade_$host/external" || true
      }
      trap report EXIT

      json=$(curl -fsSL -m 60 --retry 10 --retry-all-errors --retry-delay 15 \
        https://raw.githubusercontent.com/lajp/nix/deploy/hosts.json)
      path=$(jq -er --arg h "$host" '.hosts[$h]' <<<"$json")

      # Don't undo manual deploys of unpushed commits
      for sys in /run/current-system /nix/var/nix/profiles/system; do
        rev=$("$sys/sw/bin/nixos-version" --json | jq -r '.configurationRevision // ""')
        if ! jq -e --arg r "$rev" '.revs | index($r) != null' <<<"$json" >/dev/null; then
          SKIP=1
          echo "skip: $sys runs unpushed revision '$rev'"
          exit 0
        fi
      done

      [ "$(readlink -f /nix/var/nix/profiles/system)" != "$path" ] || exit 0 # already done or staged
      nix-store --realise "$path" --add-root /run/auto-upgrade/system >/dev/null # download only, never builds

      kernel_changed=false
      [ "$(readlink /run/booted-system/kernel-modules)" = "$(readlink "$path/kernel-modules")" ] || kernel_changed=true

      if [ "$operation" = boot ] || { [ "$kernel_changed" = true ] && [ "$on_kernel_change" != switch ]; }; then
        nixos-rebuild boot --no-reexec --store-path "$path"
        if [ "$kernel_changed" = true ] && [ "$on_kernel_change" = reboot ]; then
          shutdown -r +5 "auto-upgrade: rebooting into the new kernel"
        fi
        exit 0
      fi

      prev=$(readlink -f /run/current-system)
      # Fails if any unit fails to (re)start
      if ! nixos-rebuild switch --no-reexec --store-path "$path"; then
        echo "switch failed, rolling back to $prev" >&2
        nixos-rebuild switch --no-reexec --store-path "$prev"
        exit 1
      fi
    '';
  };
in
{
  options.lajp.services.auto-upgrade = {
    enable = mkEnableOption "nightly upgrade to the system published by CI";

    operation = mkOption {
      type = types.enum [
        "switch"
        "boot"
      ];
      default = if server then "switch" else "boot";
    };

    onKernelChange = mkOption {
      type = types.enum [
        "switch"
        "boot"
        "reboot"
      ];
      default = "switch";
      description = ''
        What to do with an update that changes the kernel or its modules (incl.
        nvidia/zfs): switch live and keep running the old kernel until the next
        reboot, only stage it for the next (manual) boot, or stage it and reboot.
      '';
    };

    dates = mkOption {
      type = types.str;
      default = "04:00";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.auto-upgrade-env.rekeyFile = ../../../secrets/auto-upgrade-env.age;

    systemd.services.auto-upgrade = {
      description = "Upgrade to the system published by CI";
      startAt = cfg.dates;

      # Like nixos-upgrade: don't restart or stop the unit while it is switching.
      restartIfChanged = false;
      unitConfig = {
        X-StopOnRemoval = false;
        ConditionPathExists = "!/var/lib/auto-upgrade/pause";
        ConditionACPower = mkIf (!server) true;
      };

      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "nix-gc.service"
      ];

      environment.HOME = "/root";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe script;
        TimeoutStartSec = "2h";
        RuntimeDirectory = "auto-upgrade";
        StateDirectory = "auto-upgrade";
        EnvironmentFile = config.age.secrets.auto-upgrade-env.path;
      };
    };

    systemd.timers.auto-upgrade.timerConfig = {
      RandomizedDelaySec = "30min";
      # Servers skip a missed night rather than catching up during the day.
      Persistent = !server;
    };
  };
}
