{
  config,
  pkgs,
  ...
}: {
  accounts.email.maildirBasePath = config.xdg.dataHome + "/mail";
  accounts.email.accounts = {
    personal = let
      address = "lajp@lajp.fi";
    in {
      msmtp.enable = true;

      inherit address;
      aliases = ["luukas@portfo.rs"];
      imap.host = "mail.lajp.fi";

      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "maildir";
      };

      gpg = {
        encryptByDefault = true;
        signByDefault = true;
      };

      maildir.path = address;

      neomutt = {
        enable = true;
        extraMailboxes = ["Drafts" "Junk" "Trash" "Sent" "Archive"];
        extraConfig = ''
          # This together with `set reverse_name` allows automatically
          # determening the address from which to reply based on the
          # recipient of the original mail
          alternates luukas@portfo.rs lajp@iki.fi luukas.portfors@iki.fi
        '';
      };

      notmuch = {
        enable = true;
        neomutt.enable = true;
      };

      passwordCommand = "${pkgs.pass}/bin/pass ${address}";

      realName = "Luukas Pörtfors";
      userName = address;
      primary = true;

      smtp = {
        host = "mail.lajp.fi";
        port = 587;
        tls.useStartTls = true;
      };
    };

    # NOTE: this account is for sending only
    # neomutt can use this when using msmtp --read-envelope-from
    iki = let
      address = "lajp@iki.fi";
    in {
      inherit address;
      aliases = ["luukas.portfors@iki.fi"];
      msmtp.enable = true;

      passwordCommand = "${pkgs.pass}/bin/pass ${address}";

      realName = "Luukas Pörtfors";
      userName = address;

      smtp = {
        host = "smtp.iki.fi";
        port = 587;
        tls.useStartTls = true;
      };
    };
  };
}
