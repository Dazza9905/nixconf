# Single source of truth for all fleet metadata.
# Underscore prefix keeps import-tree from loading this as a flake-parts module.
{
  dazzapc = {
    system = "x86_64-linux";
    targetHost = "dazzapc.lan"; # TODO: real LAN IP/hostname
    targetUser = "root";
    tags = ["desktop" "x86"];
    allowLocalDeployment = true;
  };
  flow-z13 = {
    system = "x86_64-linux";
    targetHost = "flow-z13.lan"; # TODO: real LAN IP/hostname
    targetUser = "root";
    tags = ["laptop" "x86"];
    allowLocalDeployment = true;
  };
  rpi5 = {
    system = "aarch64-linux";
    targetHost = "192.168.1.30"; # TODO: real LAN IP/hostname
    targetUser = "root";
    tags = ["server" "arm"];
    allowLocalDeployment = false;
  };
}
