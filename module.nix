{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.inventaire;
  statePath = pkgs.inventaire.statePath;
  user = "inventaire";
  group = config.services.nginx.group;
in {
  options.services.inventaire = {
    enable = mkEnableOption "Enable inventaire server";

    # TODO: make package customizable
  };





  config = mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${statePath} 0750 ${user} ${group} - -"
      "d ${statePath}/config/ 0750 ${user} ${group} - -"
      "d ${statePath}/db 0750 ${user} ${group} - -"
      "d ${statePath}/db/couchdb 0750 ${user} ${group} - -"
      "d ${statePath}/db/couchdb/design_docs 0750 ${user} ${group} - -"


    ];

    systemd.services.inventaire = {

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the inventaire server.";
      serviceConfig = {
        WorkingDirectory="${pkgs.inventaire}/lib/node_modules/inventaire/";
        ExecStart = ''${pkgs.nodejs}/bin/node server/server.js'';
        User = user;
        Group = group;
      };
    };

    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };

  };

}
