{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.lajp.hardware.memory;
in
{
  options.lajp.hardware.memory = {
    enable = mkEnableOption "memory optimization for memory-constrained servers";

    zramPercent = mkOption {
      type = types.int;
      default = 50;
      description = "Percentage of RAM to use for zram compressed swap";
    };

    earlyoomPrefer = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Regex patterns for processes earlyoom should prefer killing";
    };

    earlyoomAvoid = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Regex patterns for processes earlyoom should avoid killing";
    };
  };

  config = mkIf cfg.enable {
    # Proactive OOM killer - prevents system freezes
    services.earlyoom = {
      enable = true;
      freeMemThreshold = 5; # SIGTERM at 5% free (~800MB on 16GB)
      freeMemKillThreshold = 2; # SIGKILL at 2% free (~320MB)
      freeSwapThreshold = 10;
      freeSwapKillThreshold = 5;
      enableNotifications = false;
      extraArgs =
        (lib.optionals (cfg.earlyoomPrefer != [ ]) [
          "--prefer"
          "(${lib.concatStringsSep "|" cfg.earlyoomPrefer})"
        ])
        ++ (lib.optionals (cfg.earlyoomAvoid != [ ]) [
          "--avoid"
          "(${lib.concatStringsSep "|" cfg.earlyoomAvoid})"
        ]);
    };

    # Compressed swap in RAM
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = cfg.zramPercent;
      priority = 100; # Higher than disk swap
    };

    # Disable systemd-oomd (conflicts with earlyoom)
    systemd.oomd.enable = false;

    # Kernel memory tuning
    boot.kernel.sysctl = {
      "vm.swappiness" = 180; # Aggressive zram usage (fast)
      "vm.vfs_cache_pressure" = 50; # Keep more FS cache
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.min_free_kbytes" = 131072; # Reserve 128MB for emergencies
    };
  };
}
