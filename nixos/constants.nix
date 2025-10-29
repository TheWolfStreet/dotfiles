{
  # Hardware constants
  hardware = {
    desktop = {
      resolution = "1920x1080";
      monitor = "DP-1";
    };
    laptop = {
      resolution = "1920x1200";
      refreshRate = 144;
      monitor = "eDP-1";
    };
  };

  # System constants
  system = {
    swapSizeGB = 16;
    username = "tws";
  };

  # Keyboard layouts
  keyboards = {
    desktop = "us, ru";
    laptop = "us, ru, il";
  };

  # Power management
  power = {
    idleTimeoutSec = 900; # 15 minutes
    amdGpuPollIntervalSec = 5;
  };

  # Graphics
  graphics = {
    cursors = {
      theme = "Qogir";
      size = 24;
    };
  };
}