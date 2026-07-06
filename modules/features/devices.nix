{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.devices = {
    pkgs,
    lib,
    ...
  }: {
    #bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    #printing
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    #audio
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
