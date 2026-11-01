{...}: {
  flake.nixosModules.scripts = {pkgs, ...}: {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "force-samsung990pro";
        runtimeInputs = with pkgs; [
          bash
          coreutils
          gnugrep
          ntfs3g
          procps
          systemd
          util-linux
        ];
        text = builtins.readFile ./force-samsung990pro.sh;
      })
    ];
  };
}
