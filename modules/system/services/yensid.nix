{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.yensid.nixosModules.proxy
    inputs.yensid.nixosModules.builder
  ];

  options.lajp.services.yensid.enable = lib.mkEnableOption "Enable yensid proxy";

  config.yensid = lib.mkIf config.lajp.services.yensid.enable {
    proxy = {
      enable = true;
      builders = {
        nas.ip = "100.64.0.2";
        vaasa.ip = "192.168.178.114";
      };
      # TODO: custom load balancer
      #loadBalancing.strategy = "leastconn";
      loadBalancing.strategy = "custom";
      loadBalancing.luaFile =
        let
          nmcli = "${pkgs.networkmanager}/bin/nmcli";
        in
        pkgs.writeText "custom-balanging.lua" ''
          local function is_ethernet_connected()
              -- Use nmcli to check for active ethernet connections
              local handle = io.popen("${nmcli} -t -f TYPE,STATE device 2>/dev/null")
              local result = handle:read("*a")
              handle:close()
              
              -- Check if any ethernet device is connected
              for line in result:gmatch("[^\n]+") do
                  local device_type, state = line:match("^([^:]+):([^:]+)")
                  if device_type == "ethernet" and state == "connected" then
                      return true
                  end
              end
              
              return false
          end

          local ethernet_status = nil
          local last_check = 0

          core.register_fetches('custom-strategy', function(txn)
              local now = os.time()
              if ethernet_status == nil or (now - last_check) >= 5 then
                  ethernet_status = is_ethernet_connected()
                  last_check = now
              end
              
              return ethernet_status and "nas" or nil
          end)
        '';
    };

    #builder = {
    #  enable = true;
    #  name = "localhost";

    #  caHostKey = ../../../framework-ssh-host.pub;

    #  sshClientKey = "/etc/ssh/ssh_host_ed25519_key";

    #  caDomain = "localhost";

    #  clientAuthorizedKeyFiles = [ ../../../framework-ssh.pub ];
    #};
  };
}
