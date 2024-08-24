{config, ...}: let
  passDir = config.xdg.dataHome + "/password-store";
in {
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = passDir;
  };
}
