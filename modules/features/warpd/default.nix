{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    warpd = pkgs.warpd.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./niri.patch ./smooth-scroll.patch];
    });
  in {
    packages.myWarpd = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = warpd;
      preHook = ''
        exec ${pkgs.util-linux}/bin/flock --nonblock --conflict-exit-code 0 --no-fork \
          "''${XDG_RUNTIME_DIR:?}/warpd.lock" \
          ${lib.getExe warpd} --config ${./config} "$@"
      '';
    };
  };
}
