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
