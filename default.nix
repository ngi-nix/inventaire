{pkgs ? import <nixpkgs> {
    inherit system;
}, system ? builtins.currentSystem,
  statePath ? "/var/lib/inventaire"
}:

let
  inventaire-server = pkgs.callPackage ../server {};
  inventaire-client = pkgs.callPackage ../client {};
  inventaire-i18n = builtins.fetchGit {
    url = "https://github.com/inventaire/inventaire-i18n.git";
    ref = "dist";
  };

  piwik-js =  builtins.fetchurl {
    url = https://piwik.allmende.io/piwik.js;
    sha256 = "1md7jsfd8pa45z73bz1kszpp01yw6x5ljkjk2hx7wl800any6455";
  };

  client = inventaire-client.override {
    postInstall = ''
      echo 'let JSON_PIWIK, AnalyticsTracker, piwik_log;' > $out/lib/node_modules/inventaire-client/vendor/piwik.js
      ${piwik-js} >> ./vendor/piwik.js
    '';
  };

in
{
  inventaire = inventaire-server.package.override {

    preRebuild = ''
      cp -r ${inventaire-client.package}/lib/node_modules/inventaire-client client
      cp -r ${inventaire-i18n} inventaire-i18n
      ln -s ${statePath}/config/.sessions_keys config/.sessions_keys
      ln -s ${statePath}/db/couchdb/design_docs/groups_notifications.json db/couchdb/design_docs/groups_notifications.json
    '';

    buildInputs = [ pkgs.nodePackages.node-gyp-build ];
    statePath = statePath;

  };
}
