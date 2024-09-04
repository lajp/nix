{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./color.nix
  ];

  xdg.configFile."neomutt/mailcap".text = ''
    text/html; ${pkgs.firefox}/bin/firefox %s
    text/html; ${pkgs.w3m}/bin/w3m -I %{charset} -T text/html; copiousoutput;
    application/pdf; ${pkgs.xdg-utils}/bin/xdg-open %s &
    image/*; ${pkgs.xdg-utils}/bin/xdg-open %s &
  '';

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
      set mailcap_path=${config.xdg.configHome}/neomutt/mailcap
      set mark_old = no
      set pgp_default_key = '24E8E4CC0295F4EDB9E0B4A6C9139B8DEA65BD82'
      auto_view text/html
    '';

    binds = [
      {
        map = ["index"];
        key = "l";
        action = "display-message";
      }
      {
        map = ["pager"];
        key = "l";
        action = "view-attachments";
      }
      {
        map = ["attach"];
        key = "l";
        action = "view-mailcap";
      }
      {
        map = ["pager" "attach"];
        key = "h";
        action = "exit";
      }
      {
        map = ["index"];
        key = "h";
        action = "noop";
      }
      {
        map = ["index"];
        key = "L";
        action = "limit";
      }
      {
        map = ["index"];
        key = "N";
        action = "toggle-new";
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
        key = "o";
        action = "<shell-escape>mbsync -a<enter>";
      }
      {
        map = ["index"];
        key = "\\Cf";
        action = "<vfolder-from-query>";
      }
    ];
  };
}
