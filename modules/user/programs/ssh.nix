{ ... }:
let
  hosts = {
    jellyfin = {
      hostname = "jellyfin.lajp.fi";
      forwardAgent = true;
      extraOptions = {
        StreamLocalBindUnlink = "yes";
        RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
      };
    };

    kosh = {
      hostname = "kosh.aalto.fi";
      user = "portfol1";
    };

    tik = {
      hostname = "130.233.48.30";
      proxyJump = "kosh";
      extraOptions = {
        HostKeyAlgorithms = "ssh-rsa";
        PubkeyAcceptedAlgorithms = "ssh-rsa";
      };
    };

    nas = {
      forwardAgent = true;
      extraOptions = {
        StreamLocalBindUnlink = "yes";
        RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
      };
    };

    vaasanas = {
      forwardAgent = true;
      extraOptions = {
        StreamLocalBindUnlink = "yes";
        RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
      };
    };
  };
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = hosts;
  };
}
