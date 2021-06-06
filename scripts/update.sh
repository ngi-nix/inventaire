#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix git
set -e

# Updating server packages
echo "Updating server packages"
SERVER=$(mktemp -d)
git clone https://github.com/inventaire/inventaire "$SERVER"

# Patch package.json to include a version field
patch "$SERVER/package.json" server/nix-adaptions.patch
# Remove old packages to start from a clean slate, ignore if file is missing
rm server/node-packages.nix || true
node2nix \
        -i "$SERVER/package.json" \
        -d \
        -14 \
        -c /dev/null \
        -o server/node-packages.nix
        #-l "$SERVER/package-lock.json" \ # currently broken

# We need to patch the sources passed to the nix/node build
# node2nix does not support that, yet
# we had this problem before: https://github.com/ngi-nix/ngi/issues/109
# this patch resembles: https://github.com/svanderburg/node2nix/issues/195
patch server/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# updating client packages
echo "Updating client packages"
CLIENT=$(mktemp -d)
git clone https://github.com/inventaire/inventaire-client "$CLIENT"
# The client has more to be patched
patch -d "$CLIENT" -p1 < client/nix-adaptions.patch
rm client/node-packages.nix || true
node2nix -i "$CLIENT/package.json" -d -14 -c /dev/null -o client/node-packages.nix
# lock file currently broken: -l "$CLIENT/package-lock.json"
patch  client/node-packages.nix --fuzz 3  -i patches/node2nix-node-packages.nix.patch

# updating prerender
echo "Updating client packages"
node2nix -i prerender/package.json -d -14 -c /dev/null -o prerender/node-packages.nix

# update flake
nix flake update
