{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.editors.nvim;
in {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    inputs.agenix.homeManagerModules.default
  ];

  options.lajp.editors.nvim.enable = mkEnableOption "Enable Neovim";

  config = mkIf cfg.enable {
    age.secrets.testaustime.file = ../../../secrets/testaustime.age;
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

        treesitter.enable = true;

        gitsigns = {
          enable = true;
          settings.current_line_blame = true;
        };

        nix.enable = true;

        lsp = {
          enable = true;
          servers = {
            clangd.enable = true;
            nixd = {
              enable = true;
              settings = {
                formatting.command = ["${pkgs.alejandra}/bin/alejandra -q"];
              };
            };
            rust-analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
              cargoPackage = pkgs.rustup;
              rustcPackage = pkgs.rustup;
            };
            typst-lsp.enable = true;
            metals.enable = true;
          };
        };

        lsp-format.enable = true;

        cmp = {
          enable = true;
          settings = {
            autoEnableSources = true;
            sources = [
              {name = "nvim_lsp";}
            ];

            mapping = {
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
            };
          };
        };

        cmp-nvim-lsp.enable = true;
      };

      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "testaustime";
          src = pkgs.fetchFromGitHub {
            owner = "Testaustime";
            repo = "testaustime.nvim";
            rev = "main";
            sha256 = "gj1a6y2B3D4icsYRdY+ZxJWJ/2ioIWIGZQuBmd0M+wE=";
          };
        })
      ];

      extraConfigLua = ''
        function os.capture(cmd)
          local f = assert(io.popen(cmd, 'r'))
          local s = assert(f:read('*l'))
          f:close()
          return s
        end


          require('testaustime').setup({
            token = os.capture('cat ${config.age.secrets.testaustime.path}')
          })
      '';

      extraConfigVim = ''
        vnoremap K :m '<-2<CR>gv=gv
        vnoremap J :m '>+1<CR>gv=gv
        nnoremap j gj
        nnoremap k gk
      '';
    };
  };
}
