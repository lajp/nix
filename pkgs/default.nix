_final: prev: {
  k9mail-link = prev.callPackage ./k9mail-link.nix { };

  ilmomasiina =
    let
      nodejs = prev.nodejs_20;
    in
    prev.callPackage ./ilmomasiina.nix {
      inherit nodejs;
      pnpm = prev.pnpm_9.override { inherit nodejs; };
    };
}
