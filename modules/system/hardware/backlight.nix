{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  cfg = config.lajp.hardware.backlight;
in
{
  options.lajp.hardware.backlight = {
    enable = mkEnableOption "Enable backlight control";

    gpu = mkOption {
      description = "The GPU either intel (default) or amd";
      type = types.enum [
        "intel"
        "amd"
      ];
      default = "intel";
    };

    package = mkOption {
      description = "Package used for blmgr";
      type = types.package;
      default = inputs.blmgr.packages.${pkgs.system}.default.override { amdgpu = cfg.gpu == "amd"; };
    };
  };

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.light ];

    environment.systemPackages = [
      cfg.package
    ];
  };
}
