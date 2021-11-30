{ nixpkgs, system, overlay }:

{
  inventaire-integration-test =
    with import (nixpkgs + "/nixos/lib/testing-python.nix") {
      inherit system;
    };

    makeTest {
      name = "inventaire-integration-test";

      nodes.client = ({...}: {
        imports = [ (import ../module/inventaire.nix { inherit overlay; }).default ];
        virtualisation.memorySize = 2048;
      });

      testScript = ''
        start_all()

        # Make sure the service has not crashed immediately
        client.sleep(1)
        client.wait_for_unit("elasticsearch.service")
        client.wait_for_unit("inventaire.service")
        client.require_unit_state("inventaire.service", "active")
        client.shutdown()
      '';
    };
}
