{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.networking = {
    pkgs,
    lib,
    username,
    ...
  }: {

  };
}
