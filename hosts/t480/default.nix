{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./boot.nix ./hardware-configuration.nix];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.hostName = config.lajp.core.hostname;
  networking.networkmanager.enable = true;

  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override {enableHybridCodec = true;};
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      rocm-opencl-icd
      rocm-opencl-runtime
      amdvlk
    ];
  };

  environment.systemPackages = with pkgs; [
    rocmPackages.clr
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  hardware.amdgpu = {
    opencl.enable = true;
  };

  #services.xserver.videoDrivers = ["amdgpu"];
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  services.hardware.bolt.enable = true;

  environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";};

  system.stateVersion = "24.05";
}
