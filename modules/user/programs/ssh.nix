{ ... }:
let
  # Forward the gpg-agent socket so the YubiKey can sign/decrypt on the remote.
  gpgAgentForward = {
    StreamLocalBindUnlink = "yes";
    RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
  };

  # home-manager 26.05 deprecated `programs.ssh.matchBlocks` (camelCase options)
  # in favour of `programs.ssh.settings` using upstream OpenSSH directive names.
  # Each attribute name is a `Host` pattern; `settings."*"` is always rendered last.
  hosts = {
    jellyfin = {
      HostName = "jellyfin.lajp.fi";
      ForwardAgent = true;
    } // gpgAgentForward;

    kosh = {
      HostName = "kosh.aalto.fi";
      User = "portfol1";
    };

    tik = {
      HostName = "130.233.48.30";
      ProxyJump = "kosh";
      HostKeyAlgorithms = "ssh-rsa";
      PubkeyAcceptedAlgorithms = "ssh-rsa";
    };

    nas = {
      ForwardAgent = true;
    } // gpgAgentForward;

    vaasanas = {
      ForwardAgent = true;
    } // gpgAgentForward;

    nixos-dev = {
      ForwardAgent = true;
    } // gpgAgentForward;

    nix1 = {
      HostName = "nix1.dev.ii.zone";
      User = "luukas.portfors";
      ForwardAgent = true;
    };
  };
in
{
  programs.ssh = {
    enable = true;

    # home-manager 26.05 deprecated the implicit global ssh defaults. Opt out and
    # restore the previous defaults explicitly (the upstream-documented snippet).
    enableDefaultConfig = false;

    settings = hosts // {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };
}
