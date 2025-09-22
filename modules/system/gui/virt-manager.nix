{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.virt-manager;
in
{
  options.lajp.virt-manager.enable = mkEnableOption "Enable virt-manager";

  config = mkIf cfg.enable {

    virtualisation.libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };

    users.users.${config.lajp.user.username}.extraGroups = [ "libvirtd" ];

    programs.virt-manager.enable = true;
  };
}
