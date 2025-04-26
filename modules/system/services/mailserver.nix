{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.mailserver;
  admin = "lajp" + "@lajp.fi";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  options.lajp.services.mailserver.enable = mkEnableOption "Enable mailserver";

  config = mkIf cfg.enable {
    age.secrets.email-password.rekeyFile = ../../../secrets/email-password.age;
    age.secrets.alerts-email-hashed.rekeyFile = ../../../secrets/alerts-email-hashed.age;

    mailserver = {
      enable = true;
      fqdn = "mail.portfo.rs";
      domains = [
        "lajp.fi"
        "portfo.rs"
        "formicer.com"
      ];

      # A list of all login accounts. To create the password hashes, use
      # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
      loginAccounts = {
        ${admin} = {
          hashedPasswordFile = config.age.secrets.email-password.path;
          aliases = [
            ("portfors" + "@formicer.com")
            ("luukas" + "@formicer.com")
            ("luukas" + "@portfo.rs")
            ("lajp" + "@portfo.rs")
          ];
        };

        "alerts@lajp.fi" = {
          hashedPasswordFile = config.age.secrets.alerts-email-hashed.path;
          sendOnly = true;
        };
      };

      mailboxes = {
        Drafts = {
          auto = "subscribe";
          specialUse = "Drafts";
        };
        Junk = {
          auto = "subscribe";
          specialUse = "Junk";
        };
        Sent = {
          auto = "subscribe";
          specialUse = "Sent";
        };
        Trash = {
          auto = "no";
          specialUse = "Trash";
        };
        Archive = {
          auto = "subscribe";
        };
      };

      extraVirtualAliases = {
        "postmaster@lajp.fi" = admin;
        "abuse@lajp.fi" = admin;
        "postmaster@portfo.rs" = admin;
        "abuse@portfo.rs" = admin;
        "postmaster@formicer.com" = admin;
        "abuse@formicer.com" = admin;
      };

      forwards = {
        ${"miia" + "@portfo.rs"} = "mpor" + "tfors" + "@gmail.com";
        ${"petri" + "@portfo.rs"} = "ppor" + "tfors" + "@gmail.com";
        ${"contact" + "@formicer.com"} = [
          admin
          ("ons" + "ku.eveli" + "@gmail.com")
          ("eet" + "u.maenpaa" + "@outlook.com")
          ("oss" + "e.tammi" + "@gmail.com")
        ];
        ${"github" + "@formicer.com"} = ("formicer" + "@gmail.com");
        ${"eveli" + "@formicer.com"} = ("ons" + "ku.eveli" + "@gmail.com");
        ${"eetu" + "@formicer.com"} = ("eet" + "u.mae" + "npaa" + "@outlook.com");
        ${"tammi" + "@formicer.com"} = ("osse" + ".tammi" + "@gmail.com");
      };

      certificateScheme = "acme-nginx";

      policydSPFExtraConfig = ''
        Mail_From_reject = false
      '';
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp@iki.fi";
    };
  };
}
