_final: prev: {
  k9mail-link = prev.callPackage ./k9mail-link.nix { };

  ilmomasiina =
    let
      # nodejs_20 reached EOL and is marked insecure in nixpkgs 26.05; build
      # ilmomasiina against the current LTS instead.
      nodejs = prev.nodejs_22;
    in
    prev.callPackage ./ilmomasiina.nix {
      inherit nodejs;
      pnpm = prev.pnpm_9.override { inherit nodejs; };
    };

  ilmomasiina_3 =
    let
      nodejs = prev.nodejs_24;
    in
    (prev.callPackage ./ilmomasiina.nix {
      inherit nodejs;
      pnpm = prev.pnpm_9.override { inherit nodejs; };
    }).overrideAttrs
      (prev: {
        version = "v3.0.0-alpha.12";
        src = prev.src.overrideAttrs {
          hash = "sha256-zOjKDRc+M988Ci2WV79SD+7NjqrNm1JVgp8fu95zJ4A=";
        };

        pnpmDeps = prev.pnpmDeps.override { hash = "sha256-unHOLbLdeZ1p03/ucMKS1sRTP9IPCWy5vhy1L2l2nVs="; };
      });
}
