{ lib
, config
, inputs
, pkgs
, pkgs-unstable
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.editors.nvim;

  voikko-fi = pkgs.stdenvNoCC.mkDerivation rec {
    name = "voikko-fi";
    version = "2.5";
    src = pkgs.fetchFromGitHub {
      owner = "voikko";
      repo = "corevoikko";
      rev = "refs/tags/rel-voikko-fi-${version}";
      hash = "sha256-0MIQ54dCxyAfdgYWmmTVF+Yfa15K2sjJyP1JNxwHP2M=";
    };

    sourceRoot = "${src.name}/voikko-fi";

    enableParallelBuilding = true;

    installTargets = "vvfst-install DESTDIR=$(out)";

    nativeBuildInputs = with pkgs; [
      python3
      foma
      libvoikko
    ];
  };

  enchant-voikko = pkgs.enchant.overrideAttrs (
    _final: prev: {
      buildInputs = [
        pkgs.libvoikko
      ] ++ prev.buildInputs;

      configureFlags = [
        "--enable-voikko"
      ] ++ prev.configureFlags;
    }
  );
in
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  options.lajp.editors.nvim.enable = mkEnableOption "Enable Neovim";

  config = mkIf cfg.enable {
    programs.ripgrep.enable = true;

    xdg.configFile."enchant/voikko".source = voikko-fi;

    programs.nixvim = {
      enable = true;
      enableMan = false;

      # NOTE: Due to this: https://github.com/neovim/neovim/issues/30675
      package = pkgs-unstable.neovim-unwrapped;

      globals.mapleader = " ";

      filetype.extension = {
        mdx = "markdown";
      };

      opts = {
        clipboard = "unnamed";
        swapfile = false;

        hlsearch = false;
        number = true;
        relativenumber = true;

        tabstop = 2;
        shiftwidth = 2;
        expandtab = true;
        smartindent = true;
        wrap = false;

        spell = true;
        spelllang = "en_us";
      };

      files = {
        "ftplugin/html.lua".localOpts = {
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
      };

      dependencies.lean = {
        enable = true;
        package = pkgs.elan;
      };

      plugins = {
        telescope = {
          enable = true;

          keymaps = {
            "<C-p>" = "find_files";
            "<C-f>" = "live_grep";
          };
        };
        web-devicons.enable = true;

        rainbow-delimiters.enable = true;

        idris2.enable = true;
        treesitter = {
          enable = true;
          settings = {
            #auto_install = true;
            highlight.enable = true;
            indent.enable = true;
          };
        };

        gitsigns = {
          enable = true;
          settings.current_line_blame = true;
        };

        hunk.enable = true;

        nix.enable = true;

        typst-vim.enable = true;

        lsp = {
          enable = true;
          servers = {
            clangd.enable = true;
            nixd = {
              enable = true;
              settings = {
                formatting.command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
                #formatting.command = [ "${lib.getExe pkgs.nixpkgs-fmt}" ];
              };
            };
            gleam.enable = true;
            pylsp.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
              #cargoPackage = null;
              #rustcPackage = null;
              settings.check.command = "clippy";
            };
            tinymist.enable = true;
            idris2_lsp.enable = true;
            metals.enable = true;
            terraformls = {
              enable = true;
              settings.formatting.command = [
                "${pkgs.terraform}/bin/terraform"
                "fmt"
              ];
            };
            ts_ls = {
              enable = true;
              settings.formatting.command = [
                "${pkgs.biome}/bin/biome"
                "format"
                "--write"
              ];
            };
          };

          keymaps = {
            diagnostic = {
              "<leader>ee" = "open_float";
            };
            lspBuf = {
              "K" = "hover";
              "<leader>af" = "code_action";
              "gd" = "definition";
              "gi" = "implementation";
            };
          };
          # FIXME: remove on nvim version bump:
          # https://github.com/neovim/neovim/issues/30985
          postConfig = ''
            for _, method in ipairs({ 'textDocument/diagnostic', 'workspace/diagnostic' }) do
                local default_diagnostic_handler = vim.lsp.handlers[method]
                vim.lsp.handlers[method] = function(err, result, context, config)
                    if err ~= nil and err.code == -32802 then
                        return
                    end
                    return default_diagnostic_handler(err, result, context, config)
                end
            end
          '';
        };

        lsp-format.enable = true;

        cmp = {
          enable = true;
          settings = {
            autoEnableSources = true;
            sources = [
              { name = "nvim_lsp"; }
              { name = "luasnip"; }
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
          name = "vimchant";
          src = inputs.vimchant;

          configurePhase = ''
            substituteInPlace autoload/vimchant.vim --replace enchant ${enchant-voikko}/bin/enchant-2
            substituteInPlace plugin/vimchant.vim --replace enchant ${enchant-voikko}/bin/enchant-2
          '';
        })

        (pkgs.vimUtils.buildVimPlugin {
          name = "golf";
          src = inputs.golf;
        })
      ];

      extraConfigVim = ''
        vnoremap K :m '<-2<CR>gv=gv
        vnoremap J :m '>+1<CR>gv=gv
        nnoremap j gj
        nnoremap k gk

        let g:vimchant_spellcheck_lang = 'fi'
      '';
    };
  };
}
