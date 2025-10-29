{...}: {
  config = {
    hardware = {
      enableAllFirmware = true;
      cpu.amd.updateMicrocode = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    boot = {
      kernelParams = [
        "amd_pstate=active"
      ];
    };
  };
}

