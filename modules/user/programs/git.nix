{
  osConfig,
  ...
}:
{
  programs.git = {
    enable = true;
    settings.user = {
      name = osConfig.lajp.user.realName;
      email = "lajp@iki.fi";
    };

    settings.alias = {
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
        contents = {
          user.email = "luukas.portfors@braiins.cz";
          commit.gpgsign = false;
          tag.gpgsign = false;
        };
        condition = "gitdir:~/git/braiins/**";
      }
    ];

    settings.rerere.enabled = true;
    settings.init.defaultBranch = "main";

    settings.merge.tool = "nvimdiff";
    settings."mergetool \"nvimdiff\"".cmd = "nvim -d $LOCAL $MERGED $REMOTE -c 'wincmd l'";

    signing = {
      signByDefault = true;
      key = null;
    };
  };
}
