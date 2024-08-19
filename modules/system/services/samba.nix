{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf types mkOption;
  cfg = config.lajp.services.samba;
in {
  options.lajp.services.samba = {
    enable = mkEnableOption "Enable samba";
    users = mkOption {
      description = "Users allowed to access /media through SMB";
      type = types.listOf types.str;
      default = [config.lajp.user.username];
    };
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      securityType = "user";
      openFirewall = true;
      extraConfig = ''
        workgroup = WORKGROUP
        server string = ${config.lajp.core.hostname}
        netbios name = ${config.lajp.core.hostname}
        security = user
        guest account = nobody
        map to guest = bad user
      '';

      shares = {
        media = {
          path = "/media";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = toString cfg.users;
          "force user" = "${config.lajp.user.username}";
          "force group" = "users";
        };
      };
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    environment.systemPackages = [pkgs.samba];
  };
}
