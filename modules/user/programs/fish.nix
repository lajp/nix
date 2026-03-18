{ config, ... }:
let
  gpgConnectAgent = "${config.programs.gpg.package}/bin/gpg-connect-agent";
  gpgConf = "${config.programs.gpg.package}/bin/gpgconf";
in
{
  programs.fish = {
    enable = true;
    shellInit = ''
      set -U fish_greeting

      fish_vi_key_bindings
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      export SSH_AUTH_SOCK=(${gpgConf} --list-dirs agent-ssh-socket)
    '';

    functions.lajp_update_gpg_startup_tty = {
      body = ''
        ${gpgConnectAgent} --quiet updatestartuptty /bye >/dev/null
      '';
      onEvent = "fish_preexec";
    };

    shellAbbrs = {
      tempdir = "cd $(mktemp -d)";
    };
  };
}
