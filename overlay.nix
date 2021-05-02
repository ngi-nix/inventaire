{ inventaire-client-src, inventaire-server-src, inventaire-i18n-src }:

let
  overlay = pkgs:

    let

      # inventaire-client-src = pkgs.fetchFromGitHub {
      #   owner = "inventaire";
      #   repo = "inventaire-client";
      #   rev = "954cb91ccdec9557ec5be8b53dead6971fd0984f";
      #   sha256 = "sha256:1v575lhx5rg8nny3lkwcjb40nb0wrzdkizwirfr1y0fbfccjhxw8";
      # };

      # inventaire-server-src = pkgs.fetchFromGitHub {
      #   owner = "inventaire";
      #   repo = "inventaire";
      #   rev = "a8928931c4f749751702f734f19f0e620a9d675b";
      #   sha256 = "sha256:0nxq9k1d9y6a59jsva7nj0mmivrxxyn09v6v32axhrzgb6jwksnr";
      # };

      # inventaire-i18n-src = builtins.fetchGit {
      #   url = "https://github.com/inventaire/inventaire-i18n.git";
      #   ref = "dist";
      # };

      piwik-js = builtins.fetchurl {
        url = https://piwik.allmende.io/piwik.js;
        sha256 = "sha256:1gsfhry3z9qwc17q68qhdf9ihrmqd20qya4694f1dpqg214i1baj";
      };

      sitemap-deps = pkgs.callPackage ./sitemap {};
      inventaire-server = pkgs.callPackage ./server {};
      inventaire-client = pkgs.callPackage ./client {};
      inventaire-prerender = (pkgs.callPackage ./prerender {})."prerender-git://github.com/inventaire/prerender.git";

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

      client = inventaire-client { inherit inventaire-client-src piwik-js inventaire-i18n-src; };
      server = inventaire-server { inherit inventaire-server-src client inventaire-i18n-src; };

    in
      {
        inventaire = {
          prerender = prerender;
          sitemaps = sitemaps;
          sitemap-deps = sitemap-deps;
          client = client;
          server = server;
        };
      };
in


final: prev: overlay prev
