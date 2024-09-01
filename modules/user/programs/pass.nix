{
  config,
  pkgs,
  ...
}: let
  passDir = config.xdg.dataHome + "/password-store";
in {
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [exts.pass-otp]);
    settings.PASSWORD_STORE_DIR = passDir;
  };
}
