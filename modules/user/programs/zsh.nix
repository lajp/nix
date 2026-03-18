{ config, lib, ... }:
let
  gpgConnectAgent = "${config.programs.gpg.package}/bin/gpg-connect-agent";
  gpgConf = "${config.programs.gpg.package}/bin/gpgconf";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    envExtra = ''
      export SSH_AUTH_SOCK="$(${gpgConf} --list-dirs agent-ssh-socket)"
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 1400 ''
        autoload -Uz add-zsh-hook

        lajp_update_gpg_startup_tty() {
          ${gpgConnectAgent} --quiet updatestartuptty /bye >/dev/null
        }

        add-zsh-hook preexec lajp_update_gpg_startup_tty
      '')

      (lib.mkOrder 1500 ''
      bindkey "^R" history-incremental-pattern-search-backward
      '')
    ];

    history = {
      size = 9999999999;
      save = 9999999999;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
    };

    historySubstringSearch.enable = true;

    shellAliases = {
      tempdir = "cd $(mktemp -d)";
      # Stolen from: https://jcmc.dev/posts/2025/10/multiple_claude_code_accounts/
      claude-personal = "CLAUDE_CONFIG_DIR=~/.claude-personal claude";
      claude-braiins = "CLAUDE_CONFIG_DIR=~/.claude-braiins claude";
    };
  };
}
