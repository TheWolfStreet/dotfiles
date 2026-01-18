{...}: {
  networking = {
    networkmanager = {
      enable = true;
      unmanaged = [];
      ensureProfiles.profiles = {
        ethernet-default = {
          connection = {
            id = "Ethernet";
            type = "ethernet";
            interface-name = "eno1";
            autoconnect = true;
          };
          ethernet = {
            auto-negotiate = false;
          };
          ipv4.method = "auto";
          ipv6.method = "disabled";
        };
      };
    };

    firewall = rec {
      allowedTCPPortRanges = [
        {
          # KDE Connect
          from = 1714;
          to = 1764;
        }
      ];
      allowedTCPPorts = [27040];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
}
