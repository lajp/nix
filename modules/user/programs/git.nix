{
  osConfig,
  ...
}:
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
      {
        contents.user.email = "luukas.portfors@braiins.cz";
        condition = "gitdir:~/git/braiins/**";
      }
    ];

    extraConfig = {
      rerere.enabled = true;
      init.defaultBranch = "main";

      merge.tool = "nvimdiff";
      "mergetool \"nvimdiff\"".cmd = "nvim -d $LOCAL $MERGED $REMOTE -c 'wincmd l'";
    };

    signing = {
      #signByDefault = true;
      key = null;
    };
  };
}
