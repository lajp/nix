{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.lajp.services.emailTelegramBridge;

  transportMap = pkgs.writeText "telegram_transport" ''
    ${cfg.archiveAddress}    telegram-alert:
  '';

  emailToTelegram = pkgs.writeShellScript "email-to-telegram" ''
    set -euo pipefail
    source ${config.age.secrets.telegram-bridge.path}

    # Read and store email
    EMAIL=$(${pkgs.coreutils}/bin/cat)
    SUBJECT=$(echo "$EMAIL" | ${pkgs.procmail}/bin/formail -xSubject: | ${pkgs.coreutils}/bin/tr -d '\n' | ${pkgs.perl}/bin/perl -MMIME::QuotedPrint -e 'print decode_qp(join("",<STDIN>))')
    # Truncate in perl rather than with `head -c`: head exits early, so awk gets
    # SIGPIPE on long bodies and pipefail aborts the script.
    BODY=$(echo "$EMAIL" | ${pkgs.gawk}/bin/awk '/^$/{found=1; next} found{print}' | ${pkgs.perl}/bin/perl -MMIME::QuotedPrint -e 'print substr(decode_qp(join("",<STDIN>)), 0, 3000)')

    # Escape HTML entities
    SUBJECT_ESC=$(echo "$SUBJECT" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    BODY_ESC=$(echo "$BODY" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    MESSAGE="<b>Alert</b>
<b>Subject:</b> $SUBJECT_ESC

<pre>$BODY_ESC</pre>"

    # Send to Telegram
    ${pkgs.curl}/bin/curl -s --max-time 30 -X POST \
      "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d parse_mode="HTML" \
      --data-urlencode text="$MESSAGE" || true

    # Deliver to main address (won't loop since it doesn't match transport_maps).
    # Must be the setgid wrapper: the store sendmail runs a postdrop without the
    # postdrop group, which retries the maildrop write forever until the pipe
    # time limit (1000s) kills it, holding the single telegram-alert slot.
    echo "$EMAIL" | ${config.security.wrapperDir}/sendmail -G -i "lajp@lajp.fi"
  '';
in
{
  options.lajp.services.emailTelegramBridge = {
    enable = mkEnableOption "Email to Telegram bridge for alerts";

    alertSender = mkOption {
      type = types.str;
      default = "alerts@lajp.fi";
      description = "Email sender address that triggers Telegram forwarding";
    };

    archiveAddress = mkOption {
      type = types.str;
      default = "lajp+alerts@lajp.fi";
      description = "Tagged address for email archival";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.lajp.services.mailserver.enable;
        message = "emailTelegramBridge requires mailserver to be enabled";
      }
    ];

    age.secrets.telegram-bridge = {
      rekeyFile = ../../../secrets/telegram-bridge.age;
      mode = "0400";
      owner = "telegram-bridge";
      group = "telegram-bridge";
    };

    users.users.telegram-bridge = {
      isSystemUser = true;
      group = "telegram-bridge";
      description = "Email to Telegram bridge user";
    };
    users.groups.telegram-bridge = { };

    # Route mail to the alerts address through our telegram transport
    services.postfix.settings.main.transport_maps = "texthash:${transportMap}";

    # Use extraMasterConf for raw pipe transport definition
    services.postfix.extraMasterConf = ''
      telegram-alert unix - n n - 1 pipe
        flags=Rq user=telegram-bridge argv=${emailToTelegram}
    '';
  };
}
