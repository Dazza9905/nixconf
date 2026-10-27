{...}: {
  flake.nixosModules.dns = {
    lib,
    config,
    ...
  }: {
    options.settings.dns.enable = lib.mkEnableOption "DNS proxy with encrypted upstreams and FIIT DNS routing";

    config = lib.mkIf config.settings.dns.enable {
      networking = {
        networkmanager = {
          enable = true;
          dns = lib.mkForce "none";
          settings.main.systemd-resolved = false;
        };
        interfaces.lo.ipv4.addresses = [
          {
            address = "192.0.2.53";
            prefixLength = 32;
          }
        ];
        nameservers = ["192.0.2.53"];
      };

      services.resolved = {
        enable = true;
        settings.Resolve = {
          DNSOverTLS = "false";
          FallbackDNS = [];
        };
      };

      services.dnsproxy = {
        enable = true;
        settings = {
          listen-addrs = ["192.0.2.53"];
          listen-ports = [53];
          cache = true;
          upstream = [
            "https://1.1.1.1/dns-query"
            "https://1.0.0.1/dns-query"
            "[/fiit.stuba.sk/]147.175.159.11"
            "[/fiit.stuba.sk/]147.175.111.15"
          ];
        };
      };
      systemd.services.dnsproxy = {
        requires = ["network-addresses-lo.service"];
        after = ["network-addresses-lo.service"];
      };
    };
  };
}
