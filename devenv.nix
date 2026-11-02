{pkgs, inputs, ...}: {
  packages = with pkgs; [
    neovim
    nixd
    alejandra
  ];

  env.NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
}
