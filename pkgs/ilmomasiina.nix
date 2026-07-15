{
  stdenv,
  nodejs,
  nodejs-slim,
  python3,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
  brotli,
  makeWrapper,
  fetchFromGitHub,
  lib,

  BRANDING_HEADER_TITLE_TEXT ? "Kilta ry ilmomasiina",
  BRANDING_HEADER_TITLE_TEXT_SHORT ? "Ilmomasiina",
  BRANDING_FOOTER_GDPR_TEXT ? "Tietosuoja",
  BRANDING_FOOTER_GDPR_LINK ? "http://example.com/privacy",
  BRANDING_FOOTER_HOME_TEXT ? "Example.com",
  BRANDING_FOOTER_HOME_LINK ? "http://example.com",
  BRANDING_LOGIN_PLACEHOLDER_EMAIL ? "admin@example.com",

  logo ? null,
  favicon ? null,
  css ? null,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ilmomasiina";
  version = "v2.1.1";

  src = fetchFromGitHub {
    owner = "Tietokilta";
    repo = "ilmomasiina";
    tag = finalAttrs.version;
    hash = "sha256-Bpw6Erl11NSFU3NK4UakPxwMStpq05fDHcQPuX7Qb/4=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
    makeWrapper
    brotli
    python3
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
    hash = "sha256-nKPSdn6nPOjWOYOZCufzk36fdsq9I4+dnh0KtuBVdRU=";
  };

  inherit
    BRANDING_HEADER_TITLE_TEXT
    BRANDING_HEADER_TITLE_TEXT_SHORT
    BRANDING_FOOTER_GDPR_TEXT
    BRANDING_FOOTER_GDPR_LINK
    BRANDING_FOOTER_HOME_TEXT
    BRANDING_FOOTER_HOME_LINK
    BRANDING_LOGIN_PLACEHOLDER_EMAIL
    ;

  postPatch =
    ""
    + lib.optionalString (logo != null) ''
      cp -f ${logo} packages/ilmomasiina-frontend/src/assets/logo.svg
    ''
    + lib.optionalString (favicon != null) ''
      rm -rf packages/ilmomasiina-frontend/public/*.png
      cp -f ${favicon} packages/ilmomasiina-frontend/public/favicon.ico
    ''
    + lib.optionalString (css != null) ''
      cp -f ${css} packages/ilmomasiina-frontend/src/styles/_definitions.scss
    '';

  buildPhase = ''
    runHook preBuild

    export NODE_ENV=production
    export VERSION=${finalAttrs.version}

    npm run build

    runHook postBuild
  '';

  postBuild = ''
    find packages/ilmomasiina-frontend/build -type f\
      -regex ".*\.\(js\|json\|html\|map\|css\|svg\|ico\|txt\)" -exec gzip -k "{}" \; -exec brotli "{}" \;
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/packages

    # NOTE: pnpm doesn't support recursive pruning https://pnpm.io/cli/prune/
    rm -rf node_modules
    pnpm install --ignore-scripts --verbose --frozen-lockfile --offline --prod --filter @tietokilta/ilmomasiina-backend --filter @tietokilta/ilmomasiina-models

    export npm_config_nodedir=${nodejs}
    pushd packages/ilmomasiina-backend/node_modules
    # bcrypt requires running the build script
    pnpm rebuild bcrypt
    popd

    cp -r packages/ilmomasiina-models $out/lib/packages
    cp -r packages/ilmomasiina-backend $out/lib/packages
    cp -r packages/ilmomasiina-frontend/build $out/lib/frontend
    cp -r node_modules $out/lib

    # remove dangling symlinks
    find $out/lib -xtype l -print -delete

    makeWrapper ${nodejs-slim}/bin/node $out/bin/ilmomasiina \
      --chdir $out/lib \
      --add-flag $out/lib/packages/ilmomasiina-backend/dist/bin/server.js \
      --set NODE_ENV production

    runHook postInstall
  '';
})
