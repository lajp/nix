{...}: {
  imports = [
    ./color.nix
  ];

  programs.neomutt = {
    enable = true;
    sidebar.enable = true;
    vimKeys = true;
    sort = "reverse-date";

    extraConfig = ''
      set reverse_name
      set fast_reply
      set fcc_attach
      set forward_quote
      set sidebar_format='%D%?F? [%F]?%* %?N?%N/? %?S?%S?'
      set mail_check_stats
    '';

    binds = [
      {
        map = ["index"];
        key = "l";
        action = "display-message";
      }
      {
        map = ["index"];
        key = "L";
        action = "limit";
      }
      {
        map = ["index" "pager"];
        key = "\\Ck";
        action = "sidebar-prev";
      }
      {
        map = ["index" "pager"];
        key = "\\Cj";
        action = "sidebar-next";
      }
      {
        map = ["index" "pager"];
        key = "\\Co";
        action = "sidebar-open";
      }
    ];

    macros = [
      {
        map = ["index"];
        key = "O";
        action = "<shell-escape>mbsync -a<enter>";
      }
    ];
  };
}
