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
}
