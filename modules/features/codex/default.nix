{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.codex = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.codex;
      flags."--config" = "allow_login_shell=false";
    };
  };
}
