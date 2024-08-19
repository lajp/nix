{
  pkgs,
  config,
  ...
}: let
  passDir = config.xdg.dataHome + "/password-store";
in {
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = passDir;
  };

  services.git-sync = {
    enable = true;
    repositories.password-store = {
      path = passDir;
      uri = "git@lajp.fi:/srv/git/pass.git";
    };
  };
}
