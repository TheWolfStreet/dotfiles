{pkgs, ...}: {
  imports = [
    ./scripts/nx.nix
    ./easyeffects
  ];

  home.packages = with pkgs; [
    # Small, fast tools you end up reaching for constantly
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

    # Dev + reverse engineering + containers
    distrobox
    lazydocker
    lazygit
    claude-code
    opencode
    nodejs
    ghidra
    figma-linux

    # Hardware + pcb design
    kicad

    # Phone mirroring / adb screen + input
    scrcpy

    # Media + creation
    (mpv.override {scripts = [mpvScripts.mpris];})
    audacity
    krita
    inkscape
    blender

    # Games + compatibility layer helpers
    steam
    (bottles.override {removeWarningPopup = true;})
    gamescope
    gamemode
    steam-run

    # Docs, notes, chat
    libreoffice
    obsidian
    telegram-desktop
    vesktop

    # System plumbing + diagnostics
    lsof
    virtiofsd
    cups-filters
    krb5
    xdg-desktop-portal-gtk
    fragments
    easyeffects
    appimage-run

    # Hardware inventory + bus inspection
    usbutils
    pciutils
    dmidecode
    hdparm
    smartmontools
    lm_sensors

    # Networking utilities (brings ifconfig via net-tools)
    ethtool
    iw
    bridge-utils
    net-tools

    # Live I/O monitoring
    iotop

    # Freecad wrapper: forces mesa gl/egl vendor selection to avoid weird driver picks
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
