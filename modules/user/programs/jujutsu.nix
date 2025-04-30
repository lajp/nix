{
  config,
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

      signing = {
        backend = "gpg";
        behaviour = "own";
        #key = gitCfg.signing.key;
      };
    };
  };
}
