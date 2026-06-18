{ self, inputs, ... }: {
  flake.nixosModules.starcitizen = { config, pkgs, username, ... }:
    let
      nix-gaming-pkgs = inputs.nix-gaming.packages.${pkgs.hostPlatform.system};
      # nix-gaming = import (builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz");
    in
    {
      boot.kernel.sysctl = {
        "vm.max_map_count" = 16777216;
        "fs.file-max" = 524288;
      };

      # See RAM, ZRAM & Swap
      swapDevices = [{
        device = "/var/lib/swapfile";
        size = 8 * 1024;  # 8 GB Swap
      }];
      zramSwap = {
        enable = true;
        memoryMax = 16 * 1024 * 1024 * 1024;  # 16 GB ZRAM
      };

      # The following line was used in my setup, but I'm unsure if it is still needed
      # hardware.pulseaudio.extraConfig = "load-module module-combine-sink";

      users.users.${username} = {
        packages = [
          (nix-gaming-pkgs.star-citizen.override {
            tricks = [ "arial" "vcrun2019" "win10" "sound=alsa" ];
          })
        ];
      };
    };
}
