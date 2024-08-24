{pkgs, ...}: {
  services.udev.packages = [pkgs.yubikey-personalization];
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
}
