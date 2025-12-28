{pkgs, ...}: {
  imports = [
    ./scripts/nx.nix
    ./scripts/vault.nix
    ./easyeffects
  ];

  home.packages = with pkgs; [
    # Core utilities
    fastfetch
    bat
    eza
    fd
    ripgrep
    ncdu
    btop
    powertop
    fzf
    xxd

    # Development tools
    distrobox
    lazydocker
    lazygit
    claude-code
    crush
    nodejs
    ghidra
    figma-linux

    # Mobile/Remote tools
    scrcpy

    # ] ++ lib.optionals stdenv.isLinux [ NOTE: If darwin system to be used

    # Media applications
    (mpv.override {scripts = [mpvScripts.mpris];})
    audacity
    krita
    inkscape
    blender

    # Gaming
    steam
    (bottles.override {
      removeWarningPopup = true;
    })
    gamescope
    gamemode
    steam-run

    # Office & productivity
    libreoffice
    telegram-desktop
    vesktop

    # System utilities
    virtiofsd
    cups-filters
    krb5 # For wine
    xdg-desktop-portal-gtk
    fragments
    easyeffects
    appimage-run
    usbutils
    pciutils
    ethtool
    iw
    bridge-utils
    lm_sensors
    dmidecode
    hdparm
    smartmontools
    iotop

    # Custom FreeCAD with proper graphics setup
    (symlinkJoin {
      name = "FreeCAD";
      paths = [freecad-wayland];
      buildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/FreeCAD \
        --set __GLX_VENDOR_LIBRARY_NAME mesa \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesa}/share/glvnd/egl_vendor.d/50_mesa.json
      '';
      meta.mainProgram = "FreeCAD";
    })
  ];
}
