{...}: {
  flake.nixosModules.lighting = {pkgs, lib, ...}: {
    services.hardware.openrgb.enable = true;

    # The Riing Quad controller needs OpenRGB's keepalive to stay dark.
    systemd.services.openrgb.serviceConfig.ExecStart =
      lib.mkForce (lib.escapeShellArgs (
        [
          "${pkgs.openrgb}/bin/openrgb"
          "--server" "--noautoconnect"
          "--device" "ENE DRAM"
          "--mode" "Static" "--color" "000000"
        ]
        ++ lib.concatMap (zone: [
          "--device" "TT LEDFanBox"
          "--zone" (toString zone)
          "--mode" "Direct"
          "--size" "54" "--color" "000000"
        ]) (lib.range 0 4)
      ));
  };
}
