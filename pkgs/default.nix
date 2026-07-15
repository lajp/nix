_final: prev: {
  k9mail-link = prev.callPackage ./k9mail-link.nix { };

  ilmomasiina =
    let
      nodejs = prev.nodejs_24;
      nodejs-slim = prev.nodejs-slim_24;
      pnpm = prev.pnpm_10.override { inherit nodejs-slim; };
    in
    prev.callPackage ./ilmomasiina.nix {
      inherit nodejs nodejs-slim pnpm;
      fetchPnpmDeps = prev.fetchPnpmDeps.override { inherit pnpm; };
    };

  ilmomasiina_3 =
    let
      nodejs = prev.nodejs_24;
      nodejs-slim = prev.nodejs-slim_24;
      pnpm = prev.pnpm_10.override { inherit nodejs-slim; };
    in
    (prev.callPackage ./ilmomasiina.nix {
      inherit nodejs nodejs-slim pnpm;
      fetchPnpmDeps = prev.fetchPnpmDeps.override { inherit pnpm; };
    }).overrideAttrs
      (prev: {
        version = "v3.0.0-alpha.12";
        src = prev.src.overrideAttrs {
          hash = "sha256-zOjKDRc+M988Ci2WV79SD+7NjqrNm1JVgp8fu95zJ4A=";
        };

        pnpmDeps = prev.pnpmDeps.override { hash = "sha256-u2aHksbX4Q9gkwNRR3uOLn5u4H6dSgyngHHLKdYt04U="; };
      });
}
