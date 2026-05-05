{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.lajp.services.webmail;

  address = local: domain: local + "@" + domain;

  loginAccount = address "lajp" "lajp.fi";
  ikiPrimary = address "lajp" "iki.fi";
  ikiAlias = address "luukas.portfors" "iki.fi";
  ikiSenderIdentities = [
    ikiPrimary
    ikiAlias
  ];
  ikiRelayHost = "[smtp.iki.fi]:587";
  ikiSmtpUser = ikiPrimary;
  senderLoginMaps = "hash:/etc/postfix/vaccounts,hash:/etc/postfix/webmail_sender_login";

  virtuserFile = pkgs.writeText "roundcube-virtuser" (
    lib.concatMapStringsSep "\n" (address: "${address} ${loginAccount}") cfg.senderIdentities + "\n"
  );
in
{
  options.lajp.services.webmail = {
    enable = mkEnableOption "Roundcube webmail";

    hostName = mkOption {
      type = types.str;
      default = "webmail.lajp.fi";
      description = "Public hostname for the Roundcube webmail vhost.";
    };

    senderIdentities = mkOption {
      type = types.listOf types.str;
      default = [
        loginAccount
        (address "luukas" "portfo.rs")
        (address "lajp" "portfo.rs")
        (address "portfors" "formicer.com")
        (address "luukas" "formicer.com")
      ]
      ++ ikiSenderIdentities;
      description = "Sender identities that Roundcube should create for the main account on first login.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.lajp.services.mailserver.enable;
        message = "webmail requires mailserver to be enabled";
      }
    ];

    age.secrets.iki-smtp-password = {
      rekeyFile = ../../../secrets/iki-smtp-password.age;
      mode = "0400";
    };

    lajp.services.nginx.enable = true;

    services.roundcube = {
      enable = true;
      hostName = cfg.hostName;
      plugins = [ "virtuser_file" ];
      extraConfig = ''
        $config['imap_host'] = "ssl://${config.mailserver.fqdn}:993";
        $config['smtp_host'] = "tls://${config.mailserver.fqdn}:587";
        $config['smtp_user'] = "%u";
        $config['smtp_pass'] = "%p";
        $config['virtuser_file'] = "${virtuserFile}";
        $config['identities_level'] = 1;
        $config['product_name'] = "lajp webmail";
        $config['skin'] = "elastic";
      '';
    };

    services.postfix = {
      submissionOptions.smtpd_sender_login_maps = lib.mkForce senderLoginMaps;
      submissionsOptions.smtpd_sender_login_maps = lib.mkForce senderLoginMaps;

      settings.main = {
        sender_dependent_relayhost_maps = "hash:/etc/postfix/sender_relay";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
        smtp_sasl_security_options = "noanonymous";
        smtp_sasl_tls_security_options = "noanonymous";
        smtp_sender_dependent_authentication = "yes";
        smtp_tls_policy_maps = lib.mkAfter [ "hash:/etc/postfix/tls_policy" ];
      };
    };

    systemd.services.postfix = {
      requires = [ "postfix-webmail-iki-relay.service" ];
      after = [ "postfix-webmail-iki-relay.service" ];
    };

    systemd.services.postfix-webmail-iki-relay = {
      description = "Build Postfix maps for webmail IKI relay";
      requires = [ "postfix-setup.service" ];
      after = [ "postfix-setup.service" ];
      before = [ "postfix.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail

        password="$(${pkgs.coreutils}/bin/tr -d '\n' < ${config.age.secrets.iki-smtp-password.path})"
        if [ -z "$password" ]; then
          echo "iki-smtp-password secret is empty" >&2
          exit 1
        fi

        install -d -m 0755 -o root -g root /var/lib/postfix/conf

        cat > /var/lib/postfix/conf/webmail_sender_login <<'EOF'
        ${ikiPrimary} ${loginAccount}
        ${ikiAlias} ${loginAccount}
        EOF

        cat > /var/lib/postfix/conf/sender_relay <<'EOF'
        ${ikiPrimary} ${ikiRelayHost}
        ${ikiAlias} ${ikiRelayHost}
        EOF

        cat > /var/lib/postfix/conf/tls_policy <<'EOF'
        ${ikiRelayHost} encrypt
        EOF

        {
          printf '%s %s:%s\n' '${ikiPrimary}' '${ikiSmtpUser}' "$password"
          printf '%s %s:%s\n' '${ikiAlias}' '${ikiSmtpUser}' "$password"
          printf '%s %s:%s\n' '${ikiRelayHost}' '${ikiSmtpUser}' "$password"
        } > /var/lib/postfix/conf/sasl_passwd

        chmod 0644 \
          /var/lib/postfix/conf/webmail_sender_login \
          /var/lib/postfix/conf/sender_relay \
          /var/lib/postfix/conf/tls_policy
        chmod 0600 /var/lib/postfix/conf/sasl_passwd

        ${pkgs.postfix}/bin/postmap hash:/var/lib/postfix/conf/webmail_sender_login
        ${pkgs.postfix}/bin/postmap hash:/var/lib/postfix/conf/sender_relay
        ${pkgs.postfix}/bin/postmap hash:/var/lib/postfix/conf/tls_policy
        ${pkgs.postfix}/bin/postmap hash:/var/lib/postfix/conf/sasl_passwd

        chmod 0644 \
          /var/lib/postfix/conf/webmail_sender_login.db \
          /var/lib/postfix/conf/sender_relay.db \
          /var/lib/postfix/conf/tls_policy.db
        chmod 0600 /var/lib/postfix/conf/sasl_passwd.db
      '';
    };

    services.gatus.settings.endpoints = mkIf config.lajp.services.gatus.enable [
      {
        name = "Webmail";
        group = "public";
        url = "https://${cfg.hostName}/";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 48h"
        ];
        alerts = [ { type = "email"; } ];
      }
    ];
  };
}
