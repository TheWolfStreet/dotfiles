{pkgs, ...}: let
  accent = "#{@main_accent}";

  client_prefix = let
    left = "#[noreverse]#{?client_prefix,,}";
    right = "#[noreverse]#{?client_prefix, ,}";
    icon = "#[reverse]#{?client_prefix,,}";
  in "#[fg=${accent}]${left}${icon}${right}";

  current_window = let
    color = "#[bold,fg=${accent}]";
    name = "#[bold,fg=default]#W";
  in "${color}#I ${name} ";

  window_status = let
    index = "#[bold,fg=default]#I";
    name = "#[nobold,fg=default]#W";
  in "${index} ${name} ";

  time = let
    icon =
      pkgs.writers.writeNu "icon"
      # nu
      ''
        [ 󱑖 󱑋 󱑌 󱑍 󱑎 󱑏 󱑐 󱑑 󱑒 󱑓 󱑔 󱑕 ]
        | get ((date now | into record | get hour) mod 12)
      '';
  in "  #[fg=${accent}]#(${icon}) #[bold,fg=default]%H:%M";

  battery = let
    state =
      if pkgs.stdenv.isDarwin
      then
        pkgs.writers.writeNu "battery"
        # nu
        ''
          let info = pmset -g batt | lines

          let is_charging = (
              $info
              | first
              | parse "{pre} '{from}'"
              | get 0
              | do { $in.from == "AC Power" }
          )

          let percent = (
              $info
              | last
              | parse "{head}\t{percent}%; {tail}"
              | get 0
              | do { ($in.percent | into int) / 100 }
          )

          { percent:$percent is_charging:$is_charging }
          | to json
        ''
      else
        pkgs.writers.writeNu "battery"
        # nu
        ''
          let percent = (
              open /sys/class/power_supply/*/capacity
              | match ($in | describe) {
                  "string" => $in,
                  "list<string>" => ($in | get 0),
                  _ => "-1",
              }
              | ($in | into int) / 100
          )

          let is_charging = (
              open /sys/class/power_supply/*/status
              | match ($in | describe) {
                  "string" => $in,
                  "list<string>" => ($in | get 0),
                  _ => "Unknown",
              }
              | str trim
              | do { ($in == "Charging") or ($in == "Full" and $percent == 1) }
          )

          { percent:$percent is_charging:$is_charging }
          | to json
        '';
    script =
      pkgs.writers.writeNu "battery"
      # nu
      ''
        let low_threshhold = 25
        let state = ${state} | from json
        let percent = $state.percent
        let is_charging = $state.is_charging

        if $percent < 0 { "" } else {
          let icons: list<string> = (
              if $is_charging {
                  "󰢜 :󰂆 :󰂇 :󰂈 :󰢝 :󰂉 :󰢞 :󰂊 :󰂋 :󰂅 "
              } else {
                  "󱃍 :󰁺 :󰁻 :󰁼 :󰁽 :󰁿 :󰁾 :󰂀 :󰂁 :󰂂 :󰁹 "
              }
              | split row ":"
          )

          let icon: string = $icons | get (
              ($percent) * (($icons | length) - 1)
              | math floor
          )
          let icon_fg = (
              if $is_charging { "green" }
              else if ($percent * 100) <= ($low_threshhold) { "red" }
              else { "default" }
          )
          let label = $"($percent * 100 | math floor)%"
          let label_fg = (
              if ($percent * 100) <= ($low_threshhold) { "red" } else { "default" }
          )
          $"  #[fg=($icon_fg)]($icon)#[fg=($label_fg)]($label)"
        }
      '';
  in "#(${script})";

  pwd = let
    icon = "#[fg=${accent}] ";
    format = "#[fg=default]#{b:pane_current_path}";
  in "  ${icon}${format}";

  git = let
    script =
      pkgs.writers.writeNu "git"
      # nu
      ''
        def main [dir: string] {
          let branch = git -C $dir rev-parse --abbrev-ref HEAD | complete
          if ($branch.exit_code) == 0 {
            $"  #[fg=magenta] ($branch.stdout | str trim)"
          } else { "" }
        }
      '';
  in "#(${script} #{pane_current_path})";
in {
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
    ];
    prefix = "C-Space";
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    shell = "${pkgs.nushell}/bin/nu";
    terminal = "screen-256color";
    historyLimit = 10000;
    focusEvents = true;

    extraConfig =
      # sh
      ''
        set-option -sa terminal-overrides ",xterm*:Tc"
        set-option -g renumber-windows on

        bind v copy-mode
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key b set-option status

        bind-key -n M-1 select-window -t 1
        bind-key -n M-2 select-window -t 2
        bind-key -n M-3 select-window -t 3
        bind-key -n M-4 select-window -t 4
        bind-key -n M-5 select-window -t 5
        bind-key -n M-6 select-window -t 6
        bind-key -n M-7 select-window -t 7
        bind-key -n M-8 select-window -t 8
        bind-key -n M-9 select-window -t 9
        bind-key -n M-0 select-window -t 10
        bind-key -n M-F1 select-window -t 1
        bind-key -n M-F2 select-window -t 2
        bind-key -n M-F3 select-window -t 3
        bind-key -n M-F4 select-window -t 4
        bind-key -n M-F5 select-window -t 5
        bind-key -n M-F6 select-window -t 6
        bind-key -n M-F7 select-window -t 7
        bind-key -n M-F8 select-window -t 8
        bind-key -n M-F9 select-window -t 9
        bind-key -n M-F10 select-window -t 10

        set-option -g @main_accent "blue"
        set-option -g status-right-length 100
        set-option -g pane-active-border fg=black
        set-option -g pane-border-style fg=black
        set-option -g status-style "bg=default fg=default"
        set-option -g status-left "${client_prefix}"
        set-option -g status-right "${git}${pwd}${battery}${time}"
        set-option -g window-status-current-format "${current_window}"
        set-option -g window-status-format "${window_status}"
        set-option -g window-status-separator ""
      '';
  };
}
