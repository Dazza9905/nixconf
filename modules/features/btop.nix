{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.btop = {
    pkgs,
    lib,
    ...
  }: {
    security.wrappers.btop = {
      owner = "root";
      group = "root";
      source = "${pkgs.btop}/bin/btop";
      capabilities = "cap_perfmon+ep";
    };

    environment.shellAliases = {
      btop = "/run/wrappers/bin/btop";
    };
  };
}
