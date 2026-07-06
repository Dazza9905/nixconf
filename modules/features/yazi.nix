{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.yazi = {
    pkgs,
    lib,
    ...
  }: {
    programs.yazi = {
      enable = true;
    };
  };
}
