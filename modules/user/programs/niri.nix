{
  osConfig,
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = osConfig.lajp.services.niri;
in {
  config = mkIf cfg.enable {
    programs.swaylock.enable = true;
    programs.niri.settings = {
      prefer-no-csd = true;

      input = {
        keyboard = {
          repeat-delay = 250;
          repeat-rate = 20;

          xkb = {
            layout = "fi";
            options = "caps:escape";
          };
        };

        touchpad = {
          dwt = true;
          dwtp = true;
        };

        focus-follows-mouse.enable = true;
      };

      screenshot-path = "~/Pictures/Screenshots/%Y-%m%dT%H:%M:%S.png";

      outputs = {
        "eDP-1" = {
          scale = 1.0;
          position = {
            x = 0;
            y = 0;
          };
        };

        "HP Inc. HP Z27u G3 CN42233KPP" = {
          position = {
            x = 0;
            y = -1440;
          };
        };

        "Philips Consumer Electronics Company Philips FTV 0x01010101" = {
          #scale = 2.0;
          mode = {
            width = 1920;
            height = 1080;
          };
          position = {
            x = 0;
            #y = -2160;
            y = -1080;
          };
        };

        #"HDMI-A-2" = {
        #  scale = 1.0;
        #  position = {
        #    x = 0;
        #    y = -1080;
        #  };
        #};
      };

      layout = {
        focus-ring = {
          enable = true;
          width = 1;
        };

        center-focused-column = "never";

        border = {
          enable = false;
          width = 1;
        };
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };

        gaps = 2;
      };

      animations.slowdown = 0.6;

      spawn-at-startup = [
        {command = ["systemctl" "--user" "restart" "waybar"];}
        {command = ["systemctl" "--user" "restart" "swayidle"];}
        # See https://github.com/YaLTeR/niri/wiki/Xwayland
        {command = ["${lib.getExe pkgs.xwayland-satellite-unstable}" ":25"];}
      ];

      environment = {
        DISPLAY = ":25";
      };

      binds = let
        playerctl = "${pkgs.playerctl}/bin/playerctl";
        wpctl = "${pkgs.wireplumber}/bin/wpctl";
        blmgr = "${inputs.blmgr.packages.${pkgs.system}.default}/bin/blmgr";
      in
        {
          "XF86AudioMute".action.spawn = [wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
          "XF86AudioMicMute".action.spawn = [wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
          "XF86AudioRaiseVolume".action.spawn = [wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
          "XF86AudioLowerVolume".action.spawn = [wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];

          "Mod+P".action.spawn = [playerctl "play-pause"];
          "Mod+Left".action.spawn = [playerctl "previous"];
          "Mod+Right".action.spawn = [playerctl "next"];

          "XF86MonBrightnessUp".action.spawn = [blmgr "+5%"];
          "XF86MonBrightnessDown".action.spawn = [blmgr "-5%"];

          "Mod+Return".action.spawn = ["${pkgs.alacritty}/bin/alacritty"];
          "Mod+W".action.spawn = ["${pkgs.firefox}/bin/firefox"];

          "Print".action.screenshot-screen = [];
          "Mod+Shift+Alt+S".action.screenshot-window = [];
          "Mod+Shift+S".action.screenshot = [];
          "Mod+D".action.spawn = ["${pkgs.fuzzel}/bin/fuzzel"];
          "Mod+Alt+L".action.spawn = ["${pkgs.swaylock}/bin/swaylock"];
          "Mod+Shift+E".action.quit = [];

          "Mod+Q".action.close-window = [];
          "Mod+S".action.switch-preset-column-width = [];
          "Mod+F".action.maximize-column = [];
          "Mod+Shift+F".action.fullscreen-window = [];

          "Mod+Comma".action.consume-window-into-column = [];
          "Mod+Period".action.expel-window-from-column = [];
          "Mod+C".action.center-column = [];

          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Plus".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Plus".action.set-window-height = "+10%";

          "Mod+H".action.focus-column-left = [];
          "Mod+L".action.focus-column-right = [];
          "Mod+J".action.focus-window-or-workspace-down = [];
          "Mod+K".action.focus-window-or-workspace-up = [];

          "Mod+Shift+H".action.move-column-left = [];
          "Mod+Shift+L".action.move-column-right = [];
          "Mod+Shift+J".action.move-window-down-or-to-workspace-down = [];
          "Mod+Shift+K".action.move-window-up-or-to-workspace-up = [];
          "Mod+Tab".action.focus-workspace-previous = [];

          "Mod+Shift+N".action.move-column-to-monitor-up = [];
          "Mod+N".action.focus-monitor-up = [];
          "Mod+Shift+M".action.move-column-to-monitor-down = [];
          "Mod+M".action.focus-monitor-down = [];

          "Mod+Shift+odiaeresis".action.show-hotkey-overlay = [];
        }
        // (lib.attrsets.mergeAttrsList (
          map (x: {
            "Mod+${toString x}".action.focus-workspace = x;
            "Mod+Shift+${toString x}".action.move-column-to-workspace = x;
          })
          (builtins.genList (x: x + 1) 9)
        ));
    };
  };
}
