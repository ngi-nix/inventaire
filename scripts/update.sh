#! /usr/bin/env nix-shell
#! nix-shell -i bash -p nodePackages.node2nix git
set -e

# This script is an annoying necessity!
# 1. inventaire does not provide the required `version` field which must be patched in
# 2. the build procedure of inventaire includes cloning several git repositories into the `server` repo and build everything from there (notably not using submodules). In nix we cannot do that so we have to change the build script which requires changing the derivation source. Node2nix does not yet provide this function so it has to be patched in as well.




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
