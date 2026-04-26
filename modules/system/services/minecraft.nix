{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.lajp.services.minecraft;

  # Performance-only Fabric mods. They preserve vanilla gameplay; bump these
  # in lockstep with `cfg.package` whenever the Minecraft version changes.
  perfMods = {
    lithium = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/R7MxYvuW/lithium-fabric-0.24.2%2Bmc26.1.2.jar";
      sha512 = "9231ad05667d4eef0348c700bf5160929e0b723d9e145fd97c7fcef9387ac2e6d524fb15d99f47f8f838f1d235324fd750cdcb6603b63aab6085d79fbeaab31b";
    };
    ferritecore = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar";
      sha512 = "d81fa97e11784c19d42f89c2f433831d007603dd7193cee45fa177e4a6a9c52b384b198586e04a0f7f63cd996fed713322578bde9a8db57e1188854ae5cbe584";
    };
    krypton = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/kYAGItyj/krypton-0.3.0.jar";
      sha512 = "14233210283a76f3cf435a3b8ddbcbd65a858d2b1a10b88ff643c0a01486dfd2bf1843bd3456cd4fb86cbb3b06f2dea0c4e663b1976a48e96de16d3b5a707ec9";
    };
    # Required as a hard dependency by Chunky.
    fabric-api = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/tnmuHGZA/fabric-api-0.146.1%2B26.1.2.jar";
      sha512 = "cd8a760ecb976127036f8047c1e968f264aea9cd9deca60e6e9cb57496b1b5cca79873c59b7ab46b92f49ac22f49a2b695bb6ebe61653c8df6954e97b8836890";
    };
    # Op-driven world pre-generation: in-game `/chunky radius N` + `/chunky start`.
    # Pre-baking chunks eliminates the worldgen pause when players walk into new terrain.
    chunky = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/fALzjamp/versions/DCgX52a5/Chunky-Fabric-1.4.58.jar";
      sha512 = "82edc03802bf1796c2e0e9ca11ea8eb7b8753b9f5c4107350786258de6349935f6827e585134500b3c42924f3f8cd32e46d1c1f460b01affd6ae23ed0fbc1025";
    };
  };
in
{
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  options.lajp.services.minecraft = {
    enable = mkEnableOption "Java-edition Minecraft server (via nix-minecraft)";

    package = mkOption {
      description = ''
        Server package. Defaults to the latest Fabric build of the latest stable Minecraft
        version, with the JRE pinned to JDK 25 (Minecraft 26.x compiles class files at v69
        which require Java 25; nixpkgs' default `jre_headless` is still Java 21). Bump this
        when Mojang raises the Java floor again.
      '';
      type = types.package;
      default = pkgs.fabricServers.fabric.override { jre_headless = pkgs.jdk25_headless; };
      defaultText = lib.literalExpression "pkgs.fabricServers.fabric.override { jre_headless = pkgs.jdk25_headless; }";
    };

    serverPort = mkOption {
      description = "TCP port the Minecraft server listens on.";
      type = types.port;
      default = 25565;
    };

    jvmHeap = mkOption {
      description = "JVM heap size, used for both -Xms and -Xmx. Leave at least ~2 GiB of host RAM free for the OS and direct buffers.";
      type = types.str;
      default = "6G";
    };

    jvmExtraOpts = mkOption {
      description = "Extra JVM flags appended after -Xms / -Xmx. The default is Aikar's flags tuned for G1GC on a Minecraft workload.";
      type = types.str;
      default = lib.concatStringsSep " " [
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
        "-XX:G1ReservePercent=20"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
      ];
    };

    performanceMods = mkOption {
      description = "Install Lithium, FerriteCore, and Krypton — vanilla-preserving performance mods. Requires a Fabric package.";
      type = types.bool;
      default = true;
    };

    extraMods = mkOption {
      description = "Additional mods to drop into the server's mods/ directory, keyed by jar filename (without .jar).";
      type = types.attrsOf types.package;
      default = { };
      example = lib.literalExpression ''
        {
          fabric-api = pkgs.fetchurl { url = "..."; sha512 = "..."; };
        }
      '';
    };

    serverProperties = mkOption {
      description = "Settings merged on top of the module's server.properties defaults.";
      type = types.attrsOf (types.oneOf [
        types.bool
        types.int
        types.str
      ]);
      default = { };
    };

    whitelist = mkOption {
      description = "Whitelist players, attrs of player-name -> UUID. Set serverProperties.white-list = true to enforce.";
      type = types.attrsOf types.str;
      default = { };
    };

    operators = mkOption {
      description = "Server operators. Either name -> UUID or the richer submodule form accepted by nix-minecraft.";
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    lajp.portRequests.minecraft = cfg.serverPort;

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      servers.main = {
        enable = true;
        package = cfg.package;
        jvmOpts = "-Xms${cfg.jvmHeap} -Xmx${cfg.jvmHeap} ${cfg.jvmExtraOpts}";

        symlinks.mods = pkgs.linkFarm "minecraft-mods" (
          (lib.optionals cfg.performanceMods (
            lib.mapAttrsToList (n: drv: {
              name = "${n}.jar";
              path = drv;
            }) perfMods
          ))
          ++ (lib.mapAttrsToList (n: drv: {
            name = "${n}.jar";
            path = drv;
          }) cfg.extraMods)
        );

        serverProperties = {
          motd = "Minecraft on NixOS";
          gamemode = "survival";
          difficulty = "normal";
          max-players = 20;
          view-distance = 10;
          simulation-distance = 8;
          online-mode = true;
          pvp = true;
          spawn-protection = 0;
          server-port = cfg.serverPort;
          enable-rcon = false;
          # vanilla default is true (fsync after every chunk write). Letting the kernel
          # batch writes is a large I/O win; the trade-off is up to ~30s of recent
          # changes lost on a hard crash — acceptable on a journaled FS with managed
          # shutdowns. Set back to true via `cfg.serverProperties` if you need it.
          sync-chunk-writes = false;
        }
        // cfg.serverProperties;

        whitelist = cfg.whitelist;
        operators = cfg.operators;
      };
    };
  };
}
