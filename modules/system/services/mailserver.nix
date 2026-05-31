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
    age.secrets.nextcloud-email-hashed.rekeyFile = ../../../secrets/nextcloud-email-hashed.age;
    age.secrets.no-reply-email-hashed.rekeyFile = ../../../secrets/no-reply-email-hashed.age;
    age.secrets.otanix-nextcloud-email-hashed.rekeyFile = ../../../secrets/otanix-nextcloud-email-hashed.age;

    mailserver = {
      enable = true;
      fqdn = "mail.portfo.rs";
      domains = [
        "lajp.fi"
        "portfo.rs"
        "formicer.com"
        "nextcloud.otanix.fi"
        "oy.lajp.fi"
      ];

      stateVersion = 3;

      # This was on by default but was changed in 25.11 without any notice which completely broke my email :|
      enableSubmission = true;

      # A list of all login accounts. To create the password hashes, use
      # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
      accounts = {
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

        "nextcloud@lajp.fi" = {
          hashedPasswordFile = config.age.secrets.nextcloud-email-hashed.path;
          sendOnly = true;
        };

        "no-reply@lajp.fi" = {
          hashedPasswordFile = config.age.secrets.no-reply-email-hashed.path;
          sendOnly = true;
        };

        "system@nextcloud.otanix.fi" = {
          hashedPasswordFile = config.age.secrets.otanix-nextcloud-email-hashed.path;
          sendOnly = true;
        };
      };

      # NixOS 26.05 / dovecot 2.4: mailboxes use `special_use` (with an escaped
      # leading backslash, per RFC 6154) instead of the old `specialUse`.
      mailboxes = {
        Drafts = {
          auto = "subscribe";
          special_use = "\\Drafts";
        };
        Junk = {
          auto = "subscribe";
          special_use = "\\Junk";
        };
        Sent = {
          auto = "subscribe";
          special_use = "\\Sent";
        };
        Trash = {
          auto = "no";
          special_use = "\\Trash";
        };
        Archive = {
          auto = "subscribe";
        };
      };

      aliases = lib.mergeAttrsList (
        lib.map (domain: {
          "postmaster@${domain}" = admin;
          "abuse@${domain}" = admin;
        }) config.mailserver.domains
      );

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
        ${"contact" + "@oy.lajp.fi"} = ("lajp" + "+oy" + "@lajp.fi");
      };

      # NixOS 26.05: `certificateScheme = "acme-nginx"` was removed. Reference an
      # ACME cert managed via nginx (the vhost below provides the HTTP-01 challenge).
      x509.useACMEHost = "mail.portfo.rs";
    };

    # Replaces the old acme-nginx scheme: a vhost that serves the ACME challenge
    # so security.acme can obtain the cert for the mail fqdn.
    services.nginx.virtualHosts."mail.portfo.rs".enableACME = true;

    services.rspamd.extraConfig = ''
      actions {
        reject = null;
      }
    '';

    services.rspamd.workers.controller = {
      bindSockets = [
        {
          socket = "127.0.0.1:11334";
        }
      ];
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp@iki.fi";
    };

    # NixOS 26.05 removed the rspamd exporter; metrics are scraped from rspamd's
    # built-in /metrics endpoint instead (see prometheus.nix rspamd job).
    services.prometheus.exporters.postfix.enable = true;
    # The dovecot prometheus exporter relied on the `old_stats` plugin, which
    # dovecot 2.4 (NixOS 26.05) removed. Dropped until reimplemented on dovecot
    # 2.4's native OpenMetrics endpoint.
    # TODO: re-add dovecot metrics via dovecot 2.4's built-in stats exporter.
  };
}
