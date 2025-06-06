{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
  cfg = config.lajp.user;
in
{
  options.lajp.user = {
    username = mkOption {
      description = "Username";
      type = types.str;
      default = "lajp";
    };
    homeDirectory = mkOption {
      description = "Home directory";
      type = types.str;
      default = "/home/${cfg.username}";
    };

    realName = mkOption {
      description = "Real (not fake) name";
      type = types.str;
      default = "Luukas Pörtfors";
    };

    key = mkOption {
      description = "User PGP key fingerprint";
      type = types.str;
      default = "24E8E4CC0295F4EDB9E0B4A6C9139B8DEA65BD82";
    };
  };

  config = {
    users = {
      users.${cfg.username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "docker"
        ];
      };

      defaultUserShell = pkgs.zsh;
    };

    programs.fish.enable = true;
    programs.kdeconnect.enable = !config.lajp.core.server;
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      setOptions = [
        "HIST_IGNORE_DUPS"
        "HIST_IGNORE_SPACE"
      ];

      histSize = 9999999999;
    };
    environment.shells = with pkgs; [
      fish
      zsh
    ];
  };
}
