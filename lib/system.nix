{
  inputs,
  user,
  ...
}: let
  inherit (inputs.nixpkgs.lib) nixosSystem;
in {
  mkHost = {
    systemConfig,
    userConfig ? {},
    extraModules ? [],
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
          ({config, ...}: let
            inherit (config.lajp.user) username;
            inherit (config.lajp.core) server;
          in {
            imports = [
              ../hosts/${hostname}
              ../modules/system
            ];

            lajp = systemConfig;

            home-manager =
              if !server
              then {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                };
                users.${username} = user.mkConfig {inherit userConfig;};
              }
              else {};
          })

          inputs.home-manager.nixosModule
          inputs.agenix.nixosModules.default
          inputs.stylix.nixosModules.stylix
        ]
        ++ extraModules;
    };
}
