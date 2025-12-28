{...}: {
  networking = {
    networkmanager = {
      enable = true;
      unmanaged = [];
      ensureProfiles.profiles = {
        ethernet-default = {
          connection = {
            id = "Wired connection";
            type = "ethernet";
            autoconnect = true;
            autoconnect-priority = 999;
          };
          ethernet = {
            auto-negotiate = true;
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };

    enableIPv6 = false;

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
