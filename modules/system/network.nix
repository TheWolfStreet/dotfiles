{
  networking = {
    networkmanager = {
      enable = true;
    };

    firewall = rec {
      allowedTCPPortRanges = [
        {
          # KDE Connect
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };
  };

  systemd.services.NetworkManager-wait-online.enable = false;
}
