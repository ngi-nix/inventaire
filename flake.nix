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
      nixosModules."inventaire" = (import ./module/inventaire.nix {inherit overlay;}).module;
      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
         (import ./module/inventaire.nix {inherit overlay;}).default
         ({...}: { boot.isContainer = true; }) 
        ];
      };



    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system overlay; };
      in rec {
        checks = import ./checks/inventaire.nix {inherit nixpkgs system overlay; };
        legacyPackages = overlay {} pkgs;
        apps.update-deps = flake-utils.lib.mkApp {
          drv = pkgs.writeScriptBin "update-deps"
            (builtins.readFile ./scripts/update.sh);
        };
      });
}
