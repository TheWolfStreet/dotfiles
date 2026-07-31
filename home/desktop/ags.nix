{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  ags = inputs.ags.packages.${system}.default;
  shell = inputs.ags2-shell.packages.${system}.default;
in {
  home.packages = [ags shell];

  systemd.user.services.ags = {
    Unit = {
      Description = "AGS desktop shell";
      Documentation = ["https://github.com/TheWolfStreet/ags2-shell"];
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${shell}/bin/ags2-shell";
      KillMode = "mixed";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
