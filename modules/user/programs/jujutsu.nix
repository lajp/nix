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
        show-cryptographic-signatures = true;
      };

      signing = {
        backend = "gpg";
        behaviour = "own";
        #key = gitCfg.signing.key;
      };

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
