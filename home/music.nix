{pkgs, ...}: {
  systemd.user.services.midi-hotplug-bridge = {
    Unit.Description = "Bridge hot-plugged MIDI controllers";
    Service = {
      ExecStart = pkgs.writeShellScript "midi-hotplug-bridge" ''
        while true; do
          ${pkgs.alsa-utils}/bin/aconnect -i | ${pkgs.gawk}/bin/awk '
            /^client [0-9]+:/ {
              hardware = $0 ~ /\[type=kernel,card=[0-9]+\]/
              client = $2
              sub(/:$/, "", client)
              next
            }
            hardware && /^    [0-9]+ / { print client ":" $1 }
          ' | while IFS= read -r source; do
            ${pkgs.alsa-utils}/bin/aconnect "$source" "Midi Through:0" >/dev/null 2>&1 || true
          done
          ${pkgs.coreutils}/bin/sleep 1
        done
      '';
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = ["default.target"];
  };
}
