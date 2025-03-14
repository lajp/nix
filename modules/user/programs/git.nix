{ osConfig, ... }:
{
  programs.git = {
    enable = true;
    userName = osConfig.lajp.user.realName;
    userEmail = "lajp@iki.fi";

    aliases = {
      br = "branch";
      co = "checkout";
      st = "status";
    };

    includes = [
      {
        contents.user.email = "luukas.portfors@aalto.fi";
        condition = "gitdir:~/git/work/**";
      }
      {
        contents.user.email = "luukas.portfors@aalto.fi";
        condition = "gitdir:~/git/aalto/**";
      }
    ];

    extraConfig = {
      rerere.enabled = true;
      init.defaultBranch = "main";
    };

    signing = {
      signByDefault = true;
      key = null;
    };
  };
}
