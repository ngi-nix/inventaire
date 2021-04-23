{ pkgs }:
{ inventaire-server-src, client, statePath, inventaire-i18n-src}:
with pkgs;
let
  patchedSources = stdenv.mkDerivation {
    name = "${inventaire-server-src.name}-patched";
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
  composition = compositionRaw.override ( old:
      {
        extraArgs = {
          src = patchedSources;
        };
      }
  );

  inventaire-server = composition.package.override {

    preRebuild = ''
      cp -r ${inventaire-i18n-src} ./inventaire-i18n

      mkdir -p ./client/public
      cp -r ${client}/* ./client/public

      ln -s ${statePath}/client/uploads ./client/uploads
      ln -s ${statePath}/config/.sessions_keys config/.sessions_keys
      ln -s ${statePath}/storage ./storage

      ln -s ${statePath}/db/couchdb/design_docs/groups_notifications.json db/couchdb/design_docs/groups_notifications.json
    '';

    nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
    buildInputs = [ pkgs.graphicsmagick ];
    statePath = statePath;

  };
in
inventaire-server
