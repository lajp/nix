{ lib, config, ... }:
let
  inherit (lib) mkOption types;

  basePort = 3000;
  requests = config.lajp.portRequests;

  # Separate explicit (number) from auto (true) requests
  explicitPorts = lib.filterAttrs (n: v: builtins.isInt v) requests;
  autoRequests = lib.attrNames (lib.filterAttrs (n: v: v == true) requests);

  # Check for duplicate explicit ports
  explicitValues = lib.attrValues explicitPorts;
  duplicates = lib.filter (p: lib.count (x: x == p) explicitValues > 1) explicitValues;

  # Get all used explicit ports for collision check
  usedPorts = lib.unique explicitValues;

  # Assign auto ports starting from basePort, skipping used ports
  assignAutoPorts = names: used: port:
    if names == [ ] then
      { }
    else if lib.elem port used then
      assignAutoPorts names used (port + 1)
    else
      { ${lib.head names} = port; } // assignAutoPorts (lib.tail names) used (port + 1);

  autoPorts = assignAutoPorts (lib.sort (a: b: a < b) autoRequests) usedPorts basePort;

  # Combine explicit and auto ports
  portMap = explicitPorts // autoPorts;

  # Check auto ports don't collide with explicit
  allPorts = lib.attrValues portMap;
  allDuplicates = lib.filter (p: lib.count (x: x == p) allPorts > 1) allPorts;
in
{
  options.lajp.portRequests = mkOption {
    type = types.attrsOf (types.either types.bool types.port);
    default = { };
    description = ''
      Register a port request:
      - Set to true for auto-allocation: portRequests.hedgedoc = true;
      - Set to a port number for explicit: portRequests.ssh = 22;
    '';
  };

  options.lajp.ports = mkOption {
    type = types.attrsOf types.port;
    default = portMap;
    readOnly = true;
    description = "Computed port assignments";
  };

  config = {
    assertions = [
      {
        assertion = duplicates == [ ];
        message = "Duplicate explicit port requests: ${toString duplicates}";
      }
      {
        assertion = allDuplicates == [ ];
        message = "Port collision detected: ${toString allDuplicates}";
      }
    ];
  };
}
