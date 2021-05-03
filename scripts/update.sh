#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix git
set -e

# Updateing server packages
SERVER=$(mktemp -d)
git clone https://github.com/inventaire/inventaire "$SERVER"
patch "$SERVER/package.json" server/nix-adaptions.patch
rm server/node-packages.nix
node2nix -i "$SERVER/package.json" -l "$SERVER/package-lock.json" -d -14 -c /dev/null -o server/node-packages.nix
patch  server/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# updating client packages
CLIENT=$(mktemp -d)
git clone https://github.com/inventaire/inventaire-client "$CLIENT"
patch -d "$CLIENT" -p1 < client/nix-adaptions.patch
rm client/node-packages.nix
node2nix -i "$CLIENT/package.json" -l "$CLIENT/package-lock.json" -d -14 -c /dev/null -o client/node-packages.nix
patch  client/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# updating prerender
node2nix -i prerender/package.json -d -14 -c /dev/null -o prerender/node-packages.nix

# update flake
nix flake update
