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

      export SSH_AUTH_SOCK=(gpgconf --list-dirs agent-ssh-socket)
    '';

    shellAbbrs = {
      tempdir = "cd $(mktemp -d)";
    };
  };
}
