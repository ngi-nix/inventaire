{
  description =
    "A libre collaborative resource mapper powered by open-knowledge, starting with books! 📚";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.inventaire-client-src = {
    url = "github:inventaire/inventaire-client";
    flake = false;
  };
  inputs.inventaire-server-src = {
    url = "github:inventaire/inventaire";
    flake = false;
  };
  inputs.inventaire-i18n-src = {
    url = "github:inventaire/inventaire-i18n/dist";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, inventaire-client-src
    , inventaire-server-src, inventaire-i18n-src }:
    let
      overlay = import ./overlay.nix {
        inherit inventaire-client-src inventaire-server-src inventaire-i18n-src;
      };
    in rec {
      inherit overlay;
      nixosModule = import ./module.nix;
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            imports = [ nixosModule ];
            nixpkgs.overlays = [ overlay ];

            boot.isContainer = true;

            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision =
              nixpkgs.lib.mkIf (self ? rev) self.rev;

            # Network configuration.
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 3006 ];

            # Enable the inventaire server.
            services.inventaire = {
              enable = true;
              config = builtins.readFile ./test/local.js;
            };

            # Dependency services.
            services.couchdb = {
              enable = true;
              extraConfig = ''
                [admins]
                yourcouchdbusername=yourcouchdbpassword
              '';
              package = pkgs.couchdb2;

            };
            services.nginx.enable = true;
            services.elasticsearch.enable = true;
            services.elasticsearch.package = pkgs.elasticsearch7;

            nixpkgs.config.allowUnfree = true;
          })
        ];
      };
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system overlay; };
      in rec {

        apps.update-deps = flake-utils.lib.mkApp {
          drv = pkgs.writeScriptBin "update-deps"
            (builtins.readFile ./scripts/update.sh);
        };
      });
}
