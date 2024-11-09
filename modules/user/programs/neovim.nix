{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
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

  enchant-voikko = pkgs.enchant.overrideAttrs (final: prev: {
    buildInputs =
      [
        pkgs.libvoikko
      ]
      ++ prev.buildInputs;

    configureFlags =
      [
        "--enable-voikko"
      ]
      ++ prev.configureFlags;
  });
in {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    inputs.agenix.homeManagerModules.default
  ];

  options.lajp.editors.nvim.enable = mkEnableOption "Enable Neovim";

  config = mkIf cfg.enable {
    age.secrets.testaustime.file = ../../../secrets/testaustime.age;
    programs.ripgrep.enable = true;

    xdg.configFile."enchant/voikko".source = voikko-fi;

    programs.nixvim = {
      enable = true;
      enableMan = false;

      globals.mapleader = " ";

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

        typst-vim.enable = true;

        lsp = {
          enable = true;
          servers = {
            clangd.enable = true;
            nixd = {
              enable = true;
              settings = {
                formatting.command = ["${pkgs.alejandra}/bin/alejandra" "-q"];
              };
            };
            rust-analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
              cargoPackage = pkgs.rustup;
              rustcPackage = pkgs.rustup;
              settings.check.command = "clippy";
            };
            typst-lsp = {
              enable = true;
              settings.exportPdf = "never";
            };
            metals.enable = true;
            terraformls.enable = true;
          };

          keymaps = {
            diagnostic = {
              "<leader>ee" = "open_float";
            };
            lspBuf = {
              "K" = "hover";
              "<leader>af" = "code_action";
            };
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
          src = inputs.testaustime-nvim;
        })

        (pkgs.vimUtils.buildVimPlugin {
          name = "vimchant";
          src = inputs.vimchant;

          configurePhase = ''
            substituteInPlace autoload/vimchant.vim --replace enchant ${enchant-voikko}/bin/enchant-2
            substituteInPlace plugin/vimchant.vim --replace enchant ${enchant-voikko}/bin/enchant-2
          '';
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

        let g:vimchant_spellcheck_lang = 'fi'
      '';
    };
  };
}
