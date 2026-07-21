{self, ...}: {
  flake.nixosModules.rpi5Configuration = {pkgs, ...}: {
    imports = [
      self.nixosModules.rpi5Hardware
      self.nixosModules.base
      self.nixosModules.networking
    ];

    # must match the colmena node name for apply-local
    networking.hostName = "rpi5";

    # TODO: revisit bootloader when NixOS is actually installed on the Pi
    # (likely via nixos-hardware / raspberry-pi-nix for Pi 5 support)
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    networking.useDHCP = true;

    users.users.dazza = {
      uid = 1000;
      isNormalUser = true;
      description = "Daren Drahos";
      extraGroups = ["wheel"];
    };

    environment.systemPackages = with pkgs; [];

    system.stateVersion = "25.11";
  };
}
