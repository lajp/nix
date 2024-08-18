_: {
  mkConfig = {userConfig, ...}: {
    lajp = userConfig;

    imports = [../modules/user];
  };
}
