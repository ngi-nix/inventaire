{ pkgs }:
{ inventaire-server-src, client, inventaire-i18n-src }:
with pkgs;
let
  patchedSources = stdenv.mkDerivation {
    name = "inventaire-server-src-patched";
    src = inventaire-server-src;
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

  inventaire-server = statePath: config:
    composition.package.override {

      preRebuild = ''
        cp -r ${inventaire-i18n-src} ./inventaire-i18n

        mkdir -p ./client/public
        cp -r ${client}/* ./client/public

        ln -s ${statePath}/client/uploads ./client/uploads
        ln -s ${statePath}/config/.sessions_keys ./config/.sessions_keys
        ln -s ${statePath}/storage ./storage

        cp ${config} ./config/local.js

        ln -s ${statePath}/db/couchdb/design_docs/groups_notifications.json server/db/couchdb/design_docs/groups_notifications.json
      '';

      nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
      buildInputs = [ pkgs.graphicsmagick ];
      statePath = statePath;

    };
in inventaire-server
