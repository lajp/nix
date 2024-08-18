{ osConfig, ...}: {
  programs.tmux = {
    enable = true;
    # It's beneficial to be able to nest tmux sessions
    shortcut = if osConfig.lajp.core.server then "b" else "Space";
    keyMode = "vi";
    baseIndex = 1;
    clock24 = true;
  };
}
