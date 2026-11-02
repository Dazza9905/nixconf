{inputs, ...}: {
  perSystem = {pkgs, lib, ...}: {
    packages.mySuperfile = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.superfile;
      preHook = ''
        exec ${lib.getExe pkgs.superfile} \
          --hotkey-file ${./hotkeys.toml} "$@"
      '';
    };
  };
}
