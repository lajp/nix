{
  config,
  pkgs-unstable,
  ...
}:
let
  gitCfg = config.programs.git;
in
{
  programs.jujutsu = {
    enable = true;

    package = pkgs-unstable.jujutsu;

    settings = {
      inherit (gitCfg.settings) user;

      ui = {
        diff-editor = ":builtin";
        pager = ":builtin";
        default-command = "log";
        show-cryptographic-signatures = true;
      };

      merge-tools.nvim = {
        edit-args = [
          "-d"
          "$left"
          "$right"
        ];
      };
      merge-tools.nvim-hunk = {
        program = "nvim";
        edit-args = [
          "-c"
          "DiffEditor $left $right $output"
        ];
      };
      merge-tools.mergiraf = {
        program = "${pkgs-unstable.mergiraf}/bin/mergiraf";
        merge-args = [
          "merge"
          "$base"
          "$left"
          "$right"
          "-o"
          "$output"
        ];
        merge-tool-edits-conflict-markers = true;
      };

      signing = {
        backend = "gpg";
        behaviour = "own";
      };

      git.sign-on-push = true;

      "--scope" = [
        {
          "--when".repositories = [
            "~/git/aalto"
            "~/git/work"
          ];
          user.email = "luukas.portfors@aalto.fi";
        }
        {
          "--when".repositories = [ "~/git/braiins" ];
          user.email = "luukas.portfors@braiins.cz";
        }
      ];
    };
  };
}
