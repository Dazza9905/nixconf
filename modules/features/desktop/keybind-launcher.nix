{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.launcher = {
    pkgs,
    lib,
    username,
    ...
  }: {
    #     let
    # configFile = pkgs.writeText "config.yaml"
  };
}
