{
  lib,
  pkgs,
  virtualisationEnabled,
  ...
}: {
  imports = [
    ./scripts/nx.nix
    ./scripts/revive.nix
    ./easyeffects
  ];

  home.packages = with pkgs;
    [
      # Useful tooling
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
      jq

      # Dev + reverse engineering
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
      stremio-linux-shell

      # Games + compatibility layer helpers
      (bottles.override {removeWarningPopup = true;})
      steam-run

      # Docs, notes, chat
      libreoffice
      obsidian
      telegram-desktop
      vesktop

      # System plumbing + diagnostics
      lsof
      krb5
      fragments
      appimage-run

      # Hardware inventory + bus inspection
      usbutils
      pciutils
      dmidecode
      hdparm
      smartmontools
      lm_sensors

      # Networking utilities (brings ifconfig via net-tools)
      tcpdump
      ethtool
      iw
      bridge-utils
      net-tools

      # Live I/O monitoring
      iotop

      sweethome3d.application
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
    ]
    ++ lib.optionals virtualisationEnabled [
      distrobox
      lazydocker
    ];
}
