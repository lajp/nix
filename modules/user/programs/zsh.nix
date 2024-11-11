{config, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    envExtra = ''
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
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
    };
  };
}
