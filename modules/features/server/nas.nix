{
  flake.nixosModules.nas = {...}: {
    # Share account only; no login shell by default, no home created.
    users.users.patrik = {
      uid = 1011;
      isNormalUser = true;
      createHome = false;
    };

    # Samba passwords are imperative state: run `smbpasswd -a dazza` and
    # `smbpasswd -a patrik` once after the first deploy.
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = "rpi5";
          security = "user";
        };
        files-dazza = {
          path = "/mnt/860evo/files-dazza";
          writable = "yes";
          "valid users" = "dazza";
        };
        files-patrik = {
          path = "/mnt/860evo/files-patrik";
          writable = "yes";
          "valid users" = "patrik";
        };
      };
    };
    # Windows network discovery
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    # Paths match dazzapc's existing NFS mounts of this host.
    services.nfs.server = {
      enable = true;
      exports = ''
        # Allow LAN clients and the Pangolin client subnet.
        # Newt relays connections from this host using unprivileged source ports.
        /mnt/860evo/files-dazza  192.168.100.21(rw,no_subtree_check,insecure) 192.168.100.0/24(rw,no_subtree_check) 100.90.128.0/20(rw,no_subtree_check)
        /mnt/860evo/files-patrik 192.168.100.0/24(rw,no_subtree_check)
      '';
    };
    networking.firewall.allowedTCPPorts = [2049]; # NFSv4
  };
}
