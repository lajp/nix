{...}: let
  hosts = {
    jellyfin = {
      hostname = "jellyfin.lajp.fi";
      forwardAgent = true;
      extraOptions = {
        StreamLocalBindUnlink = "yes";
        RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
      };
    };
  };
in {
  programs.ssh = {
    enable = true;
    matchBlocks = hosts;
  };
}
