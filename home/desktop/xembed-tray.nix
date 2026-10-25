{pkgs, ...}: {
  systemd.user.services.xembedsniproxy = {
    Unit = {
      Description = "XEmbed to StatusNotifierItem tray bridge";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
