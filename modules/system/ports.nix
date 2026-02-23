{ lib, config, options, ... }:
let
  inherit (lib) mkOption types;

  basePort = 3000;
  requests = config.lajp.portRequests;

  normalizePath = path:
    let
      storeMatch = builtins.match "^/nix/store/[^/]+-source/(.*)$" path;
    in
    if storeMatch == null then path else lib.head storeMatch;

  formatPos = pos:
    let
      file =
        if pos != null && pos ? file then
          normalizePath pos.file
        else
          "<unknown>";
      line = if pos != null && pos ? line then ":${toString pos.line}" else "";
      column = if pos != null && pos ? column then ":${toString pos.column}" else "";
    in
    "${file}${line}${column}";

  portRequestDefinitions =
    if options ? lajp && options.lajp ? portRequests && options.lajp.portRequests ? definitionsWithLocations then
      options.lajp.portRequests.definitionsWithLocations
    else
      [ ];

  rawExplicitAllocations =
    lib.concatMap
      (definition:
        let
          value =
            if definition ? value && builtins.isAttrs definition.value then
              definition.value
            else
              { };
          fallbackFile =
            if definition ? file then
              definition.file
            else
              "<unknown>";
        in
        lib.concatMap
          (name:
            let
              port = value.${name};
              pos = builtins.unsafeGetAttrPos name value;
              resolvedPos =
                if pos == null then
                  { file = fallbackFile; }
                else if pos ? file then
                  pos
                else
                  pos // { file = fallbackFile; };
            in
            if builtins.isInt port then
              [
                {
                  inherit name port;
                  pos = resolvedPos;
                }
              ]
            else
              [ ])
          (lib.attrNames value))
      portRequestDefinitions;

  explicitAllocations =
    lib.filter
      (allocation:
        builtins.hasAttr allocation.name requests
        && builtins.isInt requests.${allocation.name}
        && requests.${allocation.name} == allocation.port)
      rawExplicitAllocations;

  sortByNameAndPos = a: b:
    if a.name != b.name then
      a.name < b.name
    else
      formatPos a.pos < formatPos b.pos;

  groupedExplicitAllocationsByPort = lib.groupBy (allocation: toString allocation.port) explicitAllocations;

  # Separate explicit (number) from auto (true) requests
  explicitPorts = lib.filterAttrs (_: v: builtins.isInt v) requests;
  autoRequests = lib.attrNames (lib.filterAttrs (_: v: v == true) requests);

  # Check for duplicate explicit ports
  explicitValues = lib.attrValues explicitPorts;
  duplicateExplicitPorts =
    lib.sort (a: b: a < b) (lib.unique (lib.filter (port: lib.count (x: x == port) explicitValues > 1) explicitValues));

  formatExplicitDuplicate = port:
    let
      key = toString port;
      allocations =
        if builtins.hasAttr key groupedExplicitAllocationsByPort then
          lib.sort sortByNameAndPos groupedExplicitAllocationsByPort.${key}
        else
          [ ];
      lines =
        if allocations == [ ] then
          [ "- no source locations available" ]
        else
          lib.unique (map (allocation: "- lajp.portRequests.${allocation.name} at ${formatPos allocation.pos}") allocations);
    in
    "port ${toString port}:\n${lib.concatStringsSep "\n" lines}";

  duplicateExplicitDetails = lib.concatStringsSep "\n" (map formatExplicitDuplicate duplicateExplicitPorts);

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
  allDuplicatePorts =
    lib.sort (a: b: a < b) (lib.unique (lib.filter (port: lib.count (x: x == port) allPorts > 1) allPorts));

  # Keep collision reporting focused on auto allocation conflicts so
  # explicit duplicate requests are only reported once by the assertion above.
  collisionPorts =
    lib.filter
      (
        port:
        let
          explicitCount = lib.count (value: value == port) (lib.attrValues explicitPorts);
          autoCount = lib.count (value: value == port) (lib.attrValues autoPorts);
        in
        autoCount > 1 || (explicitCount > 0 && autoCount > 0)
      )
      allDuplicatePorts;

  formatCollision = port:
    let
      key = toString port;
      explicitForPort =
        if builtins.hasAttr key groupedExplicitAllocationsByPort then
          lib.sort sortByNameAndPos groupedExplicitAllocationsByPort.${key}
        else
          [ ];
      explicitLines =
        lib.unique
          (map
            (allocation: "- lajp.portRequests.${allocation.name} (explicit) at ${formatPos allocation.pos}")
            explicitForPort);
      autoForPort = lib.sort (a: b: a < b) (lib.filter (name: autoPorts.${name} == port) (lib.attrNames autoPorts));
      autoLines = map (name: "- lajp.portRequests.${name} (auto) allocated in modules/system/ports.nix") autoForPort;
      allLines = explicitLines ++ autoLines;
      lines =
        if allLines == [ ] then
          [ "- no allocation metadata available" ]
        else
          allLines;
    in
    "port ${toString port}:\n${lib.concatStringsSep "\n" lines}";

  collisionDetails = lib.concatStringsSep "\n" (map formatCollision collisionPorts);
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
        assertion = duplicateExplicitPorts == [ ];
        message = "Duplicate explicit port requests detected:\n${duplicateExplicitDetails}";
      }
      {
        assertion = collisionPorts == [ ];
        message = "Port collision detected:\n${collisionDetails}";
      }
    ];
  };
}
