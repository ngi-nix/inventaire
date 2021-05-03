{ config, pkgs, ... }:
let inventaire = import ../.;
in {
  imports = [ inventaire.nixosModule ];
  nixpkgs.overlays = [ inventaire.overlay ];

  networking.firewall.allowedTCPPorts = [ 80 3006 ];

  services.elasticsearch.enable = true;
  services.elasticsearch.package = pkgs.elasticsearch7;
  services.couchdb = {
    extraConfig = ''
      [admins]
      yourcouchdbusername=yourcouchdbpassword
    '';
    enable = true;
    package = pkgs.couchdb2;
  };

  services.inventaire = {
    enable = true;
    config = builtins.readFile ./local.js;
  };
  services.nginx.enable = true;

  virtualisation.memorySize = "3000M";
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [ pkgs.telnet ];
}
