{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.rickroll;

  kernel = config.boot.kernelPackages.kernel;
  rickroll = pkgs.stdenv.mkDerivation {
    pname = "rickroll";
    version = "1.0";

    src = pkgs.fetchFromGitHub {
      owner = "lajp";
      repo = "dev_rickroll";
      rev = "f152e1a41e24f7c547d55ac5c2da1522ef1f83fb";
      hash = "sha256-mu2DbgvnamdrW7sSjSgjkYnAxNhIsHuIwR3MOm5HDq8=";
    };

    hardeningDisable = ["pic" "format"];
    nativeBuildInputs = kernel.moduleBuildDependencies;

    makeFlags = [
      "KERNELRELEASE=${kernel.modDirVersion}"
      "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "INSTALL_MOD_PATH=$(out)"
    ];
  };
in {
  options.lajp.rickroll.enable = mkEnableOption "Enable /dev/rickroll device";

  config = mkIf cfg.enable {
    boot.extraModulePackages = [rickroll];
  };
}
