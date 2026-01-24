# nixos dotfiles

![desktop preview](thumbnail.png)

a personal nixos setup built around hyprland, ags, and home-manager.

---

## quick start

**requirements:** nixos 24.05+, repo at `~/.dotfiles`

```bash
cd ~
git clone --recurse-submodules https://github.com/yourusername/dotfiles.git .dotfiles
cd .dotfiles
```

**configure once:**
```bash
nvim flake.nix  # set username, gitName, gitEmail
```

**on fresh installs:**
```bash
sudo nixos-generate-config --show-hardware-config \
  | sudo tee /etc/nixos/hardware-configuration.nix
```

**create/edit host in `hosts/`:**
- copy template (see [hosts](#hosts))
- set gpu, cpu, monitors, keyboard, power
- register in `flake.nix`

**first build:**
```bash
sudo nixos-rebuild switch --flake .#<hostname> --impure
sudo reboot
```

**first login:**
- land in tty, login (password = username)
- `passwd` to change it
- `start-hyprland` to launch

---

## daily workflow

**never type the long command again:**

```bash
nx-switch   # rebuild + switch
nx-boot     # apply on next boot
nx-test     # test without commitment
nx-update   # update inputs + rebuild
nx-gc       # garbage collect
```

**typical edit:**
```bash
nvim ~/.dotfiles/home/packages.nix
nx-switch
```

---

## hosts

hosts define hardware, monitors, and machine-specific settings.

**template:**
```nix
{ username, hostname, ... }: {
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/amd.nix
  ];

  networking.hostName = hostname;

  hardware = {
    enableAllFirmware = true;
    nvidia.enable = true;
    nvidia.persistence.enable = true;
    amd.cpu.enable = true;
  };

  power.enable = false;  # disable for desktops

  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      monitor = [ "DP-1,1920x1080@60,0x0,1" ];
      input.kb_layout = "us";
    };
  };
}
```

---

## structure

```
~/.dotfiles/
├── hosts/              # machine-specific configs
├── modules/
│   ├── system/         # base OS layer
│   ├── hardware/       # cpu/gpu tuning
│   └── desktop/        # compositor + desktop services
└── home/
    ├── packages.nix    # user packages
    ├── terminal/       # shell, prompt, tmux
    ├── desktop/        # hyprland, ags, browser, theme
    ├── dev/            # git, lf
    └── scripts/        # helpers
```

<details>
<summary><b>detailed breakdown</b></summary>

### modules/system/
- `base.nix` - users, shells, home-manager
- `boot.nix` - bootloader, kernel params
- `hardware.nix` - bluetooth, firmware
- `locale.nix` - timezone, language
- `network.nix` - networking, firewall
- `power.nix` - suspend, power profiles
- `security.nix` - sudo, polkit
- `services.nix` - background daemons
- `virtualization.nix` - vms, containers
- `responsiveness.nix` - tuning

### modules/hardware/
- `amd.nix` - amd cpu/gpu, microcode
- `nvidia.nix` - nvidia driver, wayland

### modules/desktop/
- `audio.nix` - pipewire, low-latency
- `hyprland.nix` - compositor, portals, lockscreen
- `nautilus.nix` - file manager
- `plymouth.nix` - boot splash

### home/desktop/
- `hyprland.nix` - user config, keybinds
- `ags.nix` - ags2-shell dependencies
- `browser.nix` - browser policies
- `spotify.nix` - spicetify theming
- `dconf.nix` - gsettings
- `theme.nix` - gtk/icons/cursors
- `colors.nix` - shared colors

</details>

---

## common tasks

**change settings:**
- username → `flake.nix`
- packages → `home/packages.nix`
- timezone/locale → `modules/system/locale.nix`
- keyboard/monitors → `hosts/<hostname>.nix`
- keybinds → `home/desktop/hyprland.nix`

**find monitor names:**
```bash
hyprctl monitors
```

---

## keybinds

<details>
<summary><b>core navigation</b></summary>

| keybind                | action                   |
| ---------------------- | ------------------------ |
| super + 1..7           | workspace 1–7            |
| super + shift + 1..7   | move to workspace        |
| super + grave          | special workspace        |
| super + q              | close window             |
| super + f              | fullscreen               |
| super + space          | float/tile               |
| super + arrows         | move window              |
| super + shift + arrows | resize window            |
| alt + tab              | cycle windows            |
| super + left/right mouse | move/resize window     |

</details>

<details>
<summary><b>launcher & apps</b></summary>

| keybind             | action            |
| ------------------- | ----------------- |
| super + r           | launcher          |
| super + tab         | overview          |
| super + x           | terminal          |
| super + b           | browser           |
| super + e           | file manager      |
| super + l           | lock              |
| ctrl + alt + delete | restart ags shell |

</details>

<details>
<summary><b>media & hardware</b></summary>

| keybind                   | action              |
| ------------------------- | ------------------- |
| print                     | screenshot (area)   |
| shift + print             | screenshot (full)   |
| super + print             | record area         |
| super + shift + print     | record screen       |
| xf86audio play/pause/next | media controls      |
| xf86audio mute            | toggle mute         |
| shift + xf86audiomute     | toggle mic          |
| xf86monbrightness up/down | brightness          |
| xf86touchpadtoggle        | toggle touchpad     |

</details>

---

## notes

- no display manager (tty → hyprland)
- flakes required
- first rebuild needs `--impure`, rest are routine

---

## license

mit. provided as-is.
