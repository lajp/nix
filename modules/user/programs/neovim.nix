{
  lib,
  config,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.editors.nvim;
in {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  options.lajp.editors.nvim.enable = mkEnableOption "Enable Neovim";
  config = mkIf cfg.enable {
    programs.ripgrep.enable = true;
    programs.nixvim = {
      enable = true;
      enableMan = false;

      colorschemes.gruvbox = {
        enable = true;
        settings.contrast_dark = "hard";
      };

      globals.mapleader = " ";

      opts = {
        clipboard = "unnamed";
        swapfile = false;

        hlsearch = false;
        number = true;
        relativenumber = true;

        tabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        smartindent = true;
        wrap = false;

        spell = true;
        spelllang = "en_us";
      };

      files = {
        "ftplugin/nix.lua".localOpts = {
          tabstop = 2;
          shiftwidth = 2;
        };
        "ftplugin/html.lua".localOpts = {
          tabstop = 2;
          shiftwidth = 2;
          wrap = true;
        };
        "ftplugin/markdown.lua".localOpts = {
          wrap = true;
          linebreak = true;
        };
        "ftplugin/tex.lua".localOpts = {
          wrap = true;
          linebreak = true;
        };
        "ftplugin/text.lua".localOpts = {
          smartindent = false;
          autoindent = false;
        };
        "ftplugin/json.lua".localOpts = {
          tabstop = 2;
          shiftwidth = 2;
        };
        "ftplugin/scala.lua".localOpts = {
          tabstop = 2;
          shiftwidth = 2;
        };
      };

      plugins = {
        telescope = {
          enable = true;

          keymaps = {
            "<C-p>" = "find_files";
            "<C-f>" = "live_grep";
          };
        };
      };

      extraConfigVim = ''
        vnoremap K :m '<-2<CR>gv=gv
        vnoremap J :m '>+1<CR>gv=gv
        nnoremap j gj
        nnoremap k gk
      '';
    };
  };
}
