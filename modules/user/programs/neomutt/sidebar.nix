{
  config,
  lib,
  ...
}:
let
  accs = config.accounts.email.accounts;
  sidebar =
    acc: value:
    if value.neomutt.enable then
      {
        "neomutt/sidebar/${acc}".text =
          "unmailboxes *\n"
          + lib.concatLines (
            lib.attrsets.attrValues (
              lib.mapAttrs (
                x: v:
                if v.neomutt.enable then
                  ''
                    mailboxes -label '${x}' ${config.accounts.email.maildirBasePath}/${v.address}/Inbox
                    ${
                      if x == acc then
                        lib.concatLines (
                          map (
                            box: "mailboxes -label ' ${box}' \"${config.accounts.email.maildirBasePath}/${v.address}/${box}\""
                          ) v.neomutt.extraMailboxes
                        )
                      else
                        ""
                    }
                  ''
                else
                  ""
              ) accs
            )
          );
      }
    else
      { };
in
{
  xdg.configFile = lib.concatMapAttrs sidebar accs;
}
