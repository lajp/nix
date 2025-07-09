{
  config,
  pkgs,
  ...
}:
let
  gitCfg = config.programs.git;
in
{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = gitCfg.userName;
        email = gitCfg.userEmail;
      };

      ui = {
        pager = ":builtin";
        default-command = "log";
      };

      signing = {
        backend = "gpg";
        behaviour = "own";
        #key = gitCfg.signing.key;
      };
    };
  };

  # Alter settings based on rules, similarly to `programs.git.includes`
  home.file."${config.xdg.configHome}/jj/conf.d/work.toml" = {
    source = (pkgs.formats.toml { }).generate "jujutsu-config" {
      "--when.repositories" = [ "~/git/braiins" ];
      user.email = "luukas.portfors@braiins.cz";
      signing.behaviour = "never";
    };
  };

  home.file."${config.xdg.configHome}/jj/conf.d/aalto.toml" = {
    source = (pkgs.formats.toml { }).generate "jujutsu-config" {
      "--when.repositories" = [
        "~/git/aalto"
        "~/git/work"
      ];
      user.email = "luukas.portfors@aalto.fi";
    };
  };
}
