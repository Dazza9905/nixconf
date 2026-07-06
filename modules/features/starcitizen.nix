{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.starcitizen = {
    pkgs,
    inputs,
    ...
  }: {
    nix.settings = {
      substituters = ["https://nix-citizen.cachix.org"];
      trusted-public-keys = ["nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="];
    };

    boot.kernel.sysctl = {
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    # See RAM, ZRAM & Swap
    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 8 * 1024; # 8 GB Swap
      }
    ];
    zramSwap = {
      enable = true;
      memoryMax = 16 * 1024 * 1024 * 1024; # 16 GB ZRAM
    };

    # The following line was used in my setup, but I'm unsure if it is still needed
    # hardware.pulseaudio.extraConfig = "load-module module-combine-sink";

    environment.systemPackages = with pkgs; [
      #`home.packages` if using home manager
      # replace or repeat for any included package
      inputs.nix-citizen.packages.${system}.rsi-launcher
    ];
  };
}
