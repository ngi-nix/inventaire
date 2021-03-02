{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem,
  statePath ? "/var/lib/inventaire"
}:

let
  sitemap-deps = pkgs.callPackage ./sitemap { };
  inventaire-server = pkgs.callPackage ../server { nodejs=pkgs."nodejs-14_x"; };
  inventaire-client = pkgs.callPackage ../client { nodejs=pkgs."nodejs-14_x"; };
  inventaire-prerender = (pkgs.callPackage ./prerender {})."prerender-git://github.com/inventaire/prerender.git";
  inventaire-i18n = builtins.fetchGit {
    url = "https://github.com/inventaire/inventaire-i18n.git";
    ref = "dist";
  };

  piwik-js =  builtins.fetchurl {
    url = https://piwik.allmende.io/piwik.js;
    sha256 = "sha256:1gsfhry3z9qwc17q68qhdf9ihrmqd20qya4694f1dpqg214i1baj";
  };



   prerender = inventaire-prerender.override {
        preRebuild = ''
        echo "module.exports = { chromeLocation: '${pkgs.chromium}/bin/chromium-browser' }" > config/local.js
        '';
        nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
   };



  sitemaps = pkgs.runCommand "build-sitemaps" { buildInputs = [ pkgs.nodejs ]; __noChroot = true; } ''
    ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/node_modules .
    ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/package.json .
    ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/custom-loader.js .

    mkdir scripts/
    cp -r ${inventaire-client.package}/lib/node_modules/inventaire-client/scripts/sitemaps scripts

    mkdir -p public/sitemaps

    npm run generate-sitemaps
    mv public/sitemaps $out
  '';



  client = pkgs.stdenv.mkDerivation {
    name = inventaire-client.package.name;
    version = inventaire-client.package.version;
    src = inventaire-client.package.src;

    nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
    buildInputs = [pkgs.nodejs-14_x];

    buildPhase = ''


      ln -s ${inventaire-client.nodeDependencies}/lib/node_modules ./node_modules
      ls node_modules/ -la
      PATH=$PATH:${inventaire-client.nodeDependencies}/bin

      patchShebangs ./

      mkdir -p ./public/i18n
      cp -r ${inventaire-i18n}/dist/client/* ./public/i18n
      cat ${inventaire-i18n}/dist/languages_data.js > ./app/lib/languages_data.js

      mkdir vendor
      echo 'let JSON_PIWIK, AnalyticsTracker, piwik_log;' > ./vendor/piwik.js


      cat ${piwik-js} >> ./vendor/piwik.js

      ./scripts/postinstall

      npm run build

    '';

    installPhase = ''
     cp -r ./public $out
    '';

  };

in
{
  prerender = prerender;
  client = client;
  sitemaps = sitemaps;
  sitemap-deps = sitemap-deps;
  inventaire = inventaire-server.package.override {

    preRebuild = ''
      cp -r ${inventaire-i18n} ./inventaire-i18n

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
}
