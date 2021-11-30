{ inventaire-client-src, inventaire-server-src, inventaire-i18n-src }:

let
  overlay = pkgs:

    let
      piwik-js = builtins.fetchurl {
        url = "https://piwik.allmende.io/piwik.js";
        sha256 = "sha256:1gsfhry3z9qwc17q68qhdf9ihrmqd20qya4694f1dpqg214i1baj";
      };

      sitemap-deps = pkgs.callPackage ./sitemap { };
      inventaire-server = pkgs.callPackage ./server { };
      inventaire-client = pkgs.callPackage ./client { };
      inventaire-prerender = (pkgs.callPackage ./prerender
        { })."prerender-git://github.com/inventaire/prerender.git";

      prerender = inventaire-prerender.override {
        preRebuild = ''
          echo "module.exports = { chromeLocation: '${pkgs.chromium}/bin/chromium-browser' }" > config/local.js
        '';
        nativeBuildInputs = [ pkgs.nodePackages.node-gyp-build ];
      };
      sitemaps = pkgs.runCommand "build-sitemaps" {
        buildInputs = [ pkgs.nodejs ];
        __noChroot = true;
      } ''
        ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/node_modules .
        ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/package.json .
        ln -s  ${inventaire-client.package}/lib/node_modules/inventaire-client/custom-loader.js .

        mkdir scripts/
        cp -r ${inventaire-client.package}/lib/node_modules/inventaire-client/scripts/sitemaps scripts

        mkdir -p public/sitemaps

        npm run generate-sitemaps
        mv public/sitemaps $out
      '';

      client = inventaire-client {
        inherit inventaire-client-src piwik-js inventaire-i18n-src;
      };
      server = inventaire-server {
        inherit inventaire-server-src client inventaire-i18n-src;
      };

    in {
      inventaire = {
        prerender = prerender;
        sitemaps = sitemaps;
        sitemap-deps = sitemap-deps;
        client = client;
        server = server;
      };
    };

in final: prev: overlay prev
