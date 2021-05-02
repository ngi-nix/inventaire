{
  description = "A libre collaborative resource mapper powered by open-knowledge, starting with books! 📚";

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

  outputs = { self, nixpkgs, flake-utils, inventaire-client-src, inventaire-server-src, inventaire-i18n-src }:
    let
      overlay = import ./overlay.nix { inherit inventaire-client-src inventaire-server-src inventaire-i18n-src; };
    in
      {
        inherit overlay;
      } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (
        system:
          let
            pkgs = import nixpkgs { inherit system overlay; };
          in
            {
              nixosModule = import ./module.nix;
            }
      );
}
