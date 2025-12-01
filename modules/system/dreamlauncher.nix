{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.rickroll;

  kernel = config.boot.kernelPackages.kernel;
  dreamlauncher = pkgs.stdenv.mkDerivation {
    pname = "dreamlauncher";
    version = "1.0";

    src = pkgs.fetchFromGitHub {
      owner = "17twenty";
      repo = "dreamlauncher";
      rev = "0ab2cb7ac3bf9b01c3b42a121d444a60b8dec0a0";
      hash = "sha256-2AlPEpgsz3JKMppkGSPuDOF6zERBT3UP3IilU9OqzSA=";
    };

    patches = [
      ./0001-fix-build-for-modern-kernel.patch
    ];

    hardeningDisable = [
      "pic"
      "format"
    ];
    nativeBuildInputs = kernel.moduleBuildDependencies;

    makeFlags = [
      "KERNELRELEASE=${kernel.modDirVersion}"
      "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "INSTALL_MOD_PATH=$(out)"
    ];
  };
in
{
  options.lajp.dreamlauncher.enable = mkEnableOption "Enable dreamlauncher device";

  config = mkIf cfg.enable {
    boot.extraModulePackages = [ dreamlauncher ];
    services.udev.extraRules = ''
      KERNEL=="launcher?*",MODE="0666",GROUP="wheel"
    '';
  };
}
