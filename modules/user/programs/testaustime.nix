{
  lib,
  config,
  osConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (osConfig.lajp.user) username;
  cfg = config.lajp.editors.nvim.testaustime;
in
{
  options.lajp.editors.nvim.testaustime.enable = mkEnableOption "Enable testaustime plugin";

  config = mkIf cfg.enable {
    age.rekey = {
      masterIdentities = [ ../../../yubikey.pub ];
      storageMode = "local";
      localStorageDir = osConfig.age.rekey.localStorageDir + "-${username}";
      hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7gs/ba3jdX+kfCruDK0NluwnFqO4AB+BZV3+2r36gY";
    };
    age.identityPaths = [ "/home/lajp/.ssh/id_ed25519" ];

    age.secrets.testaustime.rekeyFile = ../../../secrets/testaustime.age;

    programs.nixvim = {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "testaustime";
          doCheck = false;
          src = inputs.testaustime-nvim;

          buildInputs = [
            pkgs.curl
          ];
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
    };
  };
}
