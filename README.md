# Inventaire

This is a flake for the [inventaire](https://github.com/inventaire/inventaire) project.

The project does not offer an executable in that sense, but a complete server setup. Likewise, this flake only exposes a NixOS module that can be used to setup inventaire on your server.

## Configuration

Inventaire uses config files in a JavaScript format. An example can be found in ./test/local.js.
The module is largely configured through this JS file. You will need to override the present values to fit your needs.

The provided example is hte default configuration as provided by inventaire, keys are individually overridable, which means you need only to specify the configuration keys that you need to update.

## Updating

Update dependencies by running

```bash
$ nix run .#update-deps

or

./scripts/update.sh
```

## (Test) Setup

If you are using nix flakes already, the nixosConfiguration can readily be included as `module` (see https://www.tweag.io/blog/2020-07-31-nixos-flakes/ as an example how). Otherwise, module and overlay can manually be imported as documented in `./test/test-configuration.nix`. The latter is supposed to be compatible with [nixos-shell](https://github.com/chrisfarms/nixos-shell)


### Dependency Services

The example assumes `couchdb` and `elasticsearch` to be running locally (as configured in the defined system configurations). If you plan to set it up individually, make sure that you eitehr start the respective services or connect to your external providers by configuring the inventaire config file..



## Function

After startup you should be able to navigate to `<host>:80` and see inventaire's interface.

Upladed data should be kept and stored in the specified `statePath`
