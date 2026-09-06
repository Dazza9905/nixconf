{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.programs-basic = {
    pkgs,
    lib,
    self',
    username,
    ...
  }: {
    imports = [
    
    ];

    environment.systemPackages = with pkgs; [
      codex
    ];
  };
}
