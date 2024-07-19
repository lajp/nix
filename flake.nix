{
  description = "lajp NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    pia-nix.url = "github:Atte/pia-nix";

    agenix.url = "github:ryantm/agenix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    utils = import ./lib/system.nix {inherit inputs;};
    inherit (utils) mkHost;
  in {
    nixosConfigurations.nas = mkHost {
      extraModules = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-pc-ssd
        common-cpu-intel
        common-gpu-nvidia
        inputs.agenix.nixosModules.default
      ];

      systemConfig = {
        core.hostname = "nas";

        services.ssh.enable = true;
        services.jellyfin.enable = true;
        services.transmission.enable = true;
        services.jackett.enable = true;
        hardware.zfs.enable = true;
      };
    };
  };
}
