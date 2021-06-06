{ pkgs }:
{ inventaire-i18n-src, piwik-js, inventaire-client-src }:
with pkgs;
let
  patchedSources = stdenv.mkDerivation {
    name = "inventaire-client-src-patched";
    src = inventaire-client-src;
    patches = [ ./nix-adaptions.patch ];
    installPhase = ''
      mkdir $out
      cp -r ./ $out
    '';
  };
  compositionRaw = import ./composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };
  composition =
    compositionRaw.override (old: { extraArgs = { src = patchedSources; }; });

  inventaire-client = composition.package;
in stdenv.mkDerivation {
  name = inventaire-client.name;
  version = inventaire-client.version;
  src = inventaire-client.src;

  nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
  buildInputs = [ pkgs.nodejs-14_x ];

  buildPhase = ''

    # for a reason the inventaire-client cannot be used directly
    # webpack build will ignore almost all sources
    ln -s ${inventaire-client}/lib/node_modules/inventaire-client/node_modules ./node_modules
    ls -la node_modules/
    PATH=$PATH:${inventaire-client}/bin
    PATH=$PATH:$PWD/node_modules/.bin



    patchShebangs ./

    mkdir -p ./public/i18n

    ls ${inventaire-i18n-src}

    cp -r ${inventaire-i18n-src}/dist/client/* ./public/i18n
    cat ${inventaire-i18n-src}/dist/languages_data.js > ./app/lib/languages_data.js

    # adapted ./scripts/postinstall

    mkdir -p ./vendor
    echo 'let JSON_PIWIK, AnalyticsTracker, piwik_log;' > ./vendor/piwik.js
    cat ${piwik-js} >> ./vendor/piwik.js
    mkdir -p ./public/json ./vendor

    cp -r app/assets/* ./public

    npm run update-mentions
    ./scripts/build_i18n

    npm run build
  '';

  installPhase = ''
    cp -r ./public $out
  '';

}
