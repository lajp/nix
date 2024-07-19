{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./user.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.firewall.enable = true;

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fi";
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    rsync
    tmux
    htop
    killall
    fd
    nnn
    inputs.agenix.packages."${system}".default
  ];

  environment.variables.EDITOR = "vim";
}
