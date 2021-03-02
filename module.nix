{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.inventaire;
  statePath = pkgs.inventaire.statePath;
  user = "inventaire";
  group = "inventaire";
  nginxGroup = config.services.nginx.group;
  couchGroup = config.services.couchdb.group;
  nginxConfig = import ./nginx-config.nix;
in
{
  options.services.inventaire = {
    enable = mkEnableOption "Enable inventaire server";

    # TODO: make package customizable
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
      description = "Start the inventaire server.";
      serviceConfig = {
        WorkingDirectory = "${pkgs.inventaire-prerender}/lib/node_modules/prerender";
        ExecStart = ''${pkgs.nodejs}/bin/node server.js'';
        User = user;
      };
    };

    systemd.services.inventaire = {
      path = [pkgs.graphicsmagick];
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the inventaire server.";
      serviceConfig = {
        WorkingDirectory = "${pkgs.inventaire}/lib/node_modules/inventaire/";
        ExecStart = "${pkgs.nodejs}/bin/node server/server.js";
        User = user;
        Group = group;
      };
    };



    services.nginx = nginxConfig { domain-name = "0.0.0.0"; prerender-instance = "http://localhost:3000"; project-root = "${pkgs.inventaire}/lib/node_modules/"; statePath = statePath; };

    systemd.services.nginx.serviceConfig.ReadWritePaths = [ "${statePath}/nginx" ];

    users.groups.${group} = {
      members = [
        "nginx"
        "couchdb"
      ];
    };
    users.users.${user} = {
      group = group;
      extraGroups = [
        nginxGroup
        couchGroup
      ];
      isSystemUser = true;
    };

  };

}
