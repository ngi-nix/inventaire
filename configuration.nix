{ config, pkgs, ... }:
let inventaire = pkgs.callPackage ./default.nix {};

in
{
  imports =
    [ # Include the results of the hardware scan.
        ./module.nix
    ];

    nixpkgs.overlays = [(self: super: {
        erlangR19 = super.erlangR20;
        inventaire = inventaire.inventaire;
        inventaire-prerender = inventaire.prerender;
    })];

    # services.timesyncd.enable = false;
    # services.elasticsearch.enable = true;
    # services.couchdb = {
    #     extraConfig = ''
    #     [admins]
    #     yourcouchdbusername=yourcouchdbpassword
    #     '';
    #     enable = true;
    # };

    services.inventaire.enable = true;
    services.nginx.enable = true;

    virtualisation.memorySize = "2048M";
    nixpkgs.config.allowUnfree = true;


    environment.systemPackages = [pkgs.telnet];

#   users.users.root = { password = "vagrant"; };
#   # Creates a "vagrant" group & user with password-less sudo access
#   users.groups.vagrant = {
#     name = "vagrant";
#     members = [ "vagrant" ];
#   };
#   users.users.vagrant = {
#     description     = "Vagrant User";
#     name            = "vagrant";
#     group           = "vagrant";
#     extraGroups     = [ "users" "wheel" ];
#     password        = "vagrant";
#     home            = "/home/vagrant";
#     createHome      = true;
#     useDefaultShell = true;
#     openssh.authorizedKeys.keys = [
#           "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
#     ];
#   };

#   security.sudo.extraConfig =
#     ''
#       Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
#       Defaults:root,%wheel env_keep+=NIX_PATH
#       Defaults:root,%wheel env_keep+=TERMINFO_DIRS
#       Defaults env_keep+=SSH_AUTH_SOCK
#       Defaults lecture = never
#       root   ALL=(ALL) SETENV: ALL
#       %wheel ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
#     '';

}
