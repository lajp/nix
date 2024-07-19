{inputs, ...}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in {
  mkHost = {
    extraModules ? [],
    systemConfig,
    userConfig ? {},
  }: let
    inherit (systemConfig.core) hostname;
  in
    nixosSystem {
      specialArgs = {
        inherit inputs;
      };

      system = "x86_64-linux";

      modules =
        [
          ({config, ...}: {
            imports = [
              ../hosts/${hostname}
              ../modules
            ];

            lajp = systemConfig;
          })
        ]
        ++ extraModules;
    };
}
