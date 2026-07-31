{hostname, ...}: {
  imports = [
    ../modules/desktop
    ../modules/hardware
    ../modules/system
  ];

  networking.hostName = hostname;
}
