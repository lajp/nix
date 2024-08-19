{ 
  config,
  pkgs,
  ... 
}: {
  accounts.email.maildirBasePath = config.xdg.dataHome + "/mail";
  accounts.email.accounts = {
    iki = let 
      address = "lajp@iki.fi";
    in {
      inherit address;
      aliases = [ "luukas.portfors@iki.fi" ];
      msmtp.enable = true;

      inherit (config.accounts.email.accounts.personal) imap;

      neomutt.enable = true;
      notmuch = {
        enable = true;
        neomutt.enable = true;
      };

      maildir.path = "lajp@lajp.fi";

      passwordCommand = "${pkgs.pass}/bin/pass ${address}";

      primary = true;
      realName = "Luukas Pörtfors";
      userName = address;

      smtp = {
        host = "smtp.iki.fi";
        port = 587;
      };
    };

    personal = let
      address = "lajp@lajp.fi";
    in {
      inherit address;
      aliases = [ "luukas@portfo.rs" ];
      imap.host = "mail.lajp.fi";

      mbsync = {
        enable = true;
        create = "both";
        expunge = "both";
      };

      neomutt.enable = true;
      notmuch = {
        enable = true;
        neomutt.enable = true;
      };

      passwordCommand = "${pkgs.pass}/bin/pass ${address}";

      realName = "Luukas Pörtfors";
      userName = address;

      smtp = {
        host = "mail.lajp.fi";
        port = 587;
        tls.useStartTls = true;
      };
    };
  };
}
