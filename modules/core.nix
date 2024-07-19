{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options.lajp.core = {
    hostname = mkOption {
      description = "System hostname";
      type = types.str;
    };
  };
}
