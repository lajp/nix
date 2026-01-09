{ config, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    envExtra = ''
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    '';

    initContent = lib.mkOrder 1500 ''
      bindkey "^R" history-incremental-pattern-search-backward
    '';

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
