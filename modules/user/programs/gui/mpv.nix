{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.lajp.gui;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    programs.mpv = {
      enable = true;
      config.hwdec = "auto-safe";

      scripts = [ pkgs.mpvScripts.mpris ];

      extraInput = ''
        n playlist-next
        N playlist-prev
      '';

      profiles.audio = {
        ytdl-format = "bestaudio/best";
        video = false;
        af = "dynaudnorm";
      };
    };
  };
}
