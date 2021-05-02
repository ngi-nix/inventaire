#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix git

# Updateing server packages
SERVER=$(mktemp -d)
git clone https://github.com/inventaire/inventaire "$SERVER"
patch "$SERVER/package.json" server/nix-adaptions.patch
node2nix -i "$SERVER/package.json" -l "$SERVER/package-lock.json" -d -14 -c /dev/null -o server/node-packages.nix
patch  server/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# updating client packages
CLIENT=$(mktemp -d)
git clone https://github.com/inventaire/inventaire-client "$CLIENT"
patch "$CLIENT/package.json" client/nix-adaptions.patch
node2nix -i "$CLIENT/package.json" -l "$CLIENT/package-lock.json" -d -14 -c /dev/null -o client/node-packages.nix
patch  client/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# update flake
nix flake update
