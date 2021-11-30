{overlay}:
rec {
  module = { lib, pkgs, config, ... }:
    with lib;
    let
      cfg = config.services.inventaire;
      user = "inventaire";
      group = "inventaire";
      nginxGroup = config.services.nginx.group;
      couchGroup = config.services.couchdb.group;
      statePath = cfg.statePath;
      configFile = pkgs.writeText "local.js" cfg.config;
      nginxConfig = import ./nginx-config.nix;
      inventaire = pkgs.inventaire.server statePath configFile;
    in
      {
        options.services.inventaire = {
          enable = mkEnableOption "Enable inventaire server";

          statePath = mkOption {
            default = "/var/lib/inventaire";
            description = "Folder to store runtime data (Database, uploads, etc)";
            type = types.str;
          };

          config = mkOption {
            default = "";
            description =
              "Inventair configuration. (Typically a JavaScript file overriding https://github.com/inventaire/inventaire/blob/master/config/default.js)";
            type = types.str;
          };

        };
        config = mkIf cfg.enable {

          systemd.tmpfiles.rules = [
            "d ${statePath} 0750 ${user} ${group} - -"
            "d ${statePath}/storage 0750 ${user} ${group} - -"
            "d ${statePath}/storage/users 0750 ${user} ${group} - -"
            "d ${statePath}/config 0750 ${user} ${group} - -"
            "d ${statePath}/db 0750 ${user} ${group} - -"
            "d ${statePath}/db/couchdb 0750 ${user} ${group} - -"
            "d ${statePath}/db/couchdb/design_docs 0750 ${user} ${group} - -"
            "d ${statePath}/client 0750 ${user} ${group} - -"
            "d ${statePath}/client/uploads 0750 ${user} ${group} - -"
            "d ${statePath}/nginx 0770 ${user} ${group} - -"
            "d ${statePath}/nginx/tmp 0770 ${user} ${group} - -"
            "d ${statePath}/nginx/resize 0770 ${user} ${group} - -"
          ];

          systemd.services.inventaire-prerender = {

            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            description = "Start the inventaire prerender.";
            serviceConfig = {
              WorkingDirectory =
                "${pkgs.inventaire.prerender}/lib/node_modules/prerender";
              ExecStart = "${pkgs.nodejs}/bin/node server.js";
              User = user;
            };
          };

          systemd.services.inventaire = {
            path = [ pkgs.graphicsmagick ];
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            description = "Start the inventaire server.";
            serviceConfig = {
              WorkingDirectory = "${inventaire}/lib/node_modules/inventaire/";
              ExecStart = "${pkgs.nodejs}/bin/node server/server.js";
              User = user;
              Group = group;
            };
          };

          services.nginx = nginxConfig {
            domain-name = "0.0.0.0";
            prerender-instance = "http://localhost:3000";
            project-root = "${inventaire}/lib/node_modules/";
            statePath = statePath;
          };

          systemd.services.nginx.serviceConfig.ReadWritePaths =
            [ "${statePath}/nginx" ];

          users.groups.${group} = { members = [ "nginx" "couchdb" ]; };
          users.users.${user} = {
            group = group;
            extraGroups = [ nginxGroup couchGroup ];
            isSystemUser = true;
          };

        };

      };

  default = { self, pkgs, ... }: {
    imports = [ module ];
    nixpkgs.overlays = [ overlay ];

    # Network configuration.

    # useDHCP is generally considered to better be turned off in favor
    # of <adapter>.useDHCP
    networking.useDHCP = false;
    networking.firewall.allowedTCPPorts = [ 80 3006 ];

    # Enable the inventaire server.
    services.inventaire = {
      enable = true;
      config = builtins.readFile ../test/local.js;
    };

    # Dependency services.
    services.couchdb = {
      enable = true;
      adminUser = "yourcouchdbusername";
      adminPass = "yourcouchdbpassword";
      package = pkgs.couchdb3;

    };
    services.nginx.enable = true;
    services.elasticsearch.enable = true;
    services.elasticsearch.package = pkgs.elasticsearch7;

    nixpkgs.config.allowUnfree = true;
  };
}
