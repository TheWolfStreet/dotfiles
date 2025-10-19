{pkgs, ...}: let
  mkIf = cond: value:
    if cond
    then value
    else [];
in {
  imports = [
    ./scripts/nx-switch.nix
    ./scripts/vault.nix
  ];

  home.packages = pkgs.lib.flatten (with pkgs; [
    fastfetch
    steam
    bat
    eza
    fd
    ripgrep
    ncdu
    btop
    powertop
    fzf
    xxd
    distrobox
    lazydocker
    lazygit
    scrcpy

    (mkIf pkgs.stdenv.isLinux [
      (mpv.override {scripts = [mpvScripts.mpris];})
      (bottles.override {
        removeWarningPopup = true;
      })
      virtiofsd
      cups-filters
      krb5 # For wine
      xdg-desktop-portal-gtk
      gamescope
      gamemode
      vesktop
      libreoffice
      fragments
      steam-run
      file-roller
      evince
      telegram-desktop
      krita
      inkscape
      audacity
      blender-hip
      ghidra
      easyeffects
      figma-linux
      nodejs
      appimage-run

      (pkgs.symlinkJoin {
        name = "FreeCAD";
        paths = [pkgs.freecad-wayland];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/FreeCAD \
          --set __GLX_VENDOR_LIBRARY_NAME mesa \
          --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json
        '';
        meta.mainProgram = "FreeCAD";
      })
    ])
  ]);
}
