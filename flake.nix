{
  description = "A libre collaborative resource mapper powered by open-knowledge, starting with books! 📚";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.inventaire-client-src.url = "";
  inputs.inventaire-server-src.url = "";
  inputs.inventaire-i18n-src.url = "";


  outputs = { self, nixpkgs, flake-utils, inventaire-client-src, inventaire-server-src, inventaire-i18n-src}:
    flake-utils.lib.eachDefaultSystem ( system:
    let
        overlay = import ./default.nix { inherit inventaire-client-src inventaire-server-src inventaire-i18n-src; };
        pkgs = import nixpkgs { inherit system overlay; };
    in
    {
        nixosModule = import ./module.nix;
    }

    );
}
