{
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (osConfig.lajp.user) realName;
  mkSchool =
    {
      name,
      address,
      userName ? address,
    }:
    {
      inherit address userName realName;
      msmtp = {
        enable = true;
        extraConfig.auth = "xoauth2";
      };

      # NOTE: setup the oauth with the mutt_oauth2.py script
      # https://www.vanormondt.net/~peter/blog/2021-03-16-mutt-office365-mfa.html
      # Using the (old) Thunderbird oauth app
      # client_id = 08162f7c-0fd2-4200-a84a-f25a4db0b584
      # client_secret = TxRBilcHdC6WGBee]fs?QR:SJ8nI[g82
      # use -t $PASSWORD_STORE_DIR/$address.gpg to get the path correct (for pass)
      passwordCommand =
        let
          python = "${pkgs.python3}/bin/python3";
          mutt_oauth2 = "${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py";
          passDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;
        in
        "${python} ${mutt_oauth2} --encryption-pipe 'gpg -e -r ${address}' ${passDir}/${address}.gpg";

      flavor = "outlook.office365.com";

      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "maildir";
        extraConfig.account.AuthMechs = "XOAUTH2";
      };

      gpg = {
        encryptByDefault = true;
        signByDefault = true;
      };

      maildir.path = address;

      folders = {
        sent = "Sent Items";
        trash = "Deleted Items";
      };

      neomutt = {
        enable = true;
        extraMailboxes = [
          "Drafts"
          "Deleted Items"
          "Sent Items"
        ];
        extraConfig = ''
          source ${config.xdg.configHome}/neomutt/sidebar/${name}
        '';
      };

      notmuch = {
        enable = true;
        neomutt.enable = true;
      };
    };

  mkGmail =
    {
      name,
      address,
      aliases ? [ ],
    }:
    {
      inherit address realName aliases;

      flavor = "gmail.com";

      gpg = {
        encryptByDefault = true;
        signByDefault = true;
      };

      maildir.path = address;

      msmtp = {
        enable = true;
        extraConfig.auth = "xoauth2";
      };

      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "maildir";
        extraConfig.account.AuthMechs = "XOAUTH2";
      };

      neomutt = {
        enable = true;
        extraMailboxes = map (x: "[Gmail]/" + x) [
          "Drafts"
          "Trash"
          "Sent Mail"
        ];
        extraConfig = ''
          ${if aliases != [ ] then "alternates ${toString aliases}" else ""}
            source ${config.xdg.configHome}/neomutt/sidebar/${name}
        '';
      };

      notmuch = {
        enable = true;
        neomutt.enable = true;
      };

      passwordCommand =
        let
          python = "${pkgs.python3}/bin/python3";
          mutt_oauth2 = "${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py";
          passDir = config.programs.password-store.settings.PASSWORD_STORE_DIR;
        in
        "${python} ${mutt_oauth2} --encryption-pipe 'gpg -e -r lajp@iki.fi' ${passDir}/oauth/${address}.gpg";

      folders = {
        sent = "[Gmail]/Sent Mail";
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
    };
in
{
  accounts.email.maildirBasePath = config.xdg.dataHome + "/mail";
  accounts.email.accounts = {
    personal =
      let
        address = "lajp@lajp.fi";
      in
      {
        msmtp.enable = true;

        inherit address realName;
        aliases = [ "luukas@portfo.rs" ];
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
          extraMailboxes = [
            "Drafts"
            "Junk"
            "Trash"
            "Sent"
            "Archive"
          ];
          extraConfig = ''
            # This together with `set reverse_name` allows automatically
            # determening the address from which to reply based on the
            # recipient of the original mail
            alternates luukas@portfo.rs lajp@iki.fi luukas.portfors@iki.fi
            source ${config.xdg.configHome}/neomutt/sidebar/personal
          '';
        };

        notmuch = {
          enable = true;
          neomutt.enable = true;
        };

        passwordCommand = "${pkgs.pass}/bin/pass ${address}";

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
    iki =
      let
        address = "lajp@iki.fi";
      in
      {
        inherit address realName;
        aliases = [ "luukas.portfors@iki.fi" ];
        msmtp.enable = true;

        passwordCommand = "${pkgs.pass}/bin/pass ${address}";

        userName = address;

        smtp = {
          host = "smtp.iki.fi";
          port = 587;
          tls.useStartTls = true;
        };
      };

    aalto = mkSchool {
      name = "aalto";
      address = "luukas.portfors@aalto.fi";
    };

    hy = mkSchool {
      name = "hy";
      address = "luukas.portfors@helsinki.fi";
      userName = "lajportf@ad.helsinki.fi";
    };

    otanix = mkGmail {
      name = "otanix";
      address = "lajp@otanix.fi";
      aliases = [ "luukas@otanix.fi" ];
    };

    helsec = mkGmail {
      name = "helsec";
      address = "lajp@helsec.fi";
    };
  };
}
