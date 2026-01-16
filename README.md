# nixos dotfiles

![desktop preview](thumbnail.png)

a personal nixos setup built around hyprland, ags, and home-manager.

---

## overview

* flake-based nixos + home-manager
* no display manager (tty → hyprland)
* hosts are explicit, reusable, and boring on purpose
* daily rebuilds happen through small wrapper scripts

system config lives in `modules/`
home-manager configuration lives in `home/`
host specific configuration (home-manager + system) lives in `hosts/`

---

## quick start

### requirements

* nixos 24.05+
* repo must live in user home directory at `~/.dotfiles`

### install

```bash
cd ~
git clone --recurse-submodules https://github.com/yourusername/dotfiles.git .dotfiles
cd .dotfiles
```

edit identity once:

```bash
nvim flake.nix
# username
# gitName
# gitEmail
```

if on a fresh install, make sure hardware config exists:

```bash
sudo nixos-generate-config --show-hardware-config \
  |sudo tee /etc/nixos/hardware-configuration.nix
```

pick or create a host in `hosts/` and adjust:

* gpu (amd / nvidia)
* amd cpu (microcode, kernel params)
* monitors
* keyboard layout
* power management settings

on first build only:
```bash
sudo nixos-rebuild switch --flake .#<hostname> --impure
sudo reboot
```

---

## hosts

hosts describe machine specific properties.

to reuse one:

1. copy or edit `hosts/<hostname>.nix`
2. import hardware + gpu modules
3. define monitors and layouts
4. toggle power management for laptops

host template:

```nix
{ username, hostname, ... }: {
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
    ../modules/hardware/amd.nix
  ];
	# Must be present for passing the hostname from flake, same for username
  networking.hostName = hostname;

	hardware = {
		enableAllFirmware = true;        # load all available firmware blobs

		nvidia = {
			enable = true;                 # enable nvidia gpu support
			persistence.enable = true;     # keep nvidia driver loaded between uses
		};

		amd.cpu.enable = true;           # enable amd cpu-specific features and microcode
	};

  power.enable = false; # Disable power management
	
	# Host specific home manager settings
  home-manager.users.${username} = {
		wayland.windowManager.hyprland.settings = {
			monitor = [ "DP-1,1920x1080@60,0x0,1" ]; # output_name, resolution@refresh, position, scale
			input.kb_layout = "us"; # multiple layouts are comma separated "us, ru"
		};
	};
}
```

register it in `flake.nix`, then rebuild once with `--impure`.


---

## first login

* you land in a tty
* login (initial password is the username)
* change it immediately: `passwd`
* start the session: `start-hyprland`

from here on, the desktop and ags load automatically.

---

## daily usage

after the first rebuild, never type the long command again.

available helpers:

```bash
nx-switch   # rebuild and switch (default)
nx-boot     # rebuild, apply on next boot
nx-test     # temporary test
nx-vm       # build in vm
nx-update   # update flake inputs + rebuild
nx-gc       # garbage collect
```

typical loop:

```bash
nvim ~/.dotfiles/home/packages.nix
nx-switch
```

useful probes:

```bash
hyprctl monitors
```

---

## structure
```
~/.dotfiles/
├── hosts/
│   ├── common.nix
│   │   shared host-level defaults: nix, users, overlays, gc
│   │
│   ├── nixos.nix
│   │   desktop entrypoint
│   │   imports common + system + desktop + nvidia + amd cpu
│   │
│   └── nixtop.nix
│       laptop entrypoint
│       imports common + system + desktop + amd cpu + amd gpu
│
├── modules/
│   ├── system/
│   │   ├── base.nix
│   │   │   absolute floor: users, shells, home-manager
│   │   │
│   │   ├── boot.nix
│   │   │   bootloader, initrd, kernel params
│   │   │
│   │   ├── hardware.nix
│   │   │   generic hardware support (bluetooth, firmware)
│   │   │
│   │   ├── locale.nix
│   │   │   language, timezone, formats
│   │   │
│   │   ├── network.nix
│   │   │   networking, firewall, ports
│   │   │
│   │   ├── power.nix
│   │   │   suspend, power profiles, device quirks
│   │   │
│   │   ├── security.nix
│   │   │   sudo, polkit, hardening
│   │   │
│   │   ├── services.nix
│   │   │   daemons and background services
│   │   │
│   │   ├── virtualization.nix
│   │   │   vms, containers, kernel features
│   │   │
│   │   └── responsiveness.nix
│   │   │   responsiveness tuning
│   │   │
│   ├── hardware/
│   │   ├── amd.nix
│   │   │   amd cpu/gpu tuning, microcode, kernel flags
│   │   │
│   │   └── nvidia.nix
│   │       nvidia driver, power, wayland glue
│   │
│   └── desktop/
│       ├── audio.nix
│       │   pipewire, limits, low-latency tuning
│       │
│       ├── hyprland.nix
│       │   compositor, xwayland, portals
│       │   lockscreen integration lives here
│       │
│       ├── nautilus.nix
│       │   file manager and mime hooks
│       │
│       └── plymouth.nix
│           boot splash
│
├── home/
│   ├── packages.nix
│   │   user-scoped packages, shared across hosts
│   │
│   ├── terminal/
│   │   ├── sh.nix
│   │   │   shell environment
│   │   │
│   │   ├── starship.nix
│   │   │   prompt semantics
│   │   │
│   │   └── tmux.nix
│   │       tmux behavior and tone
│   │
│   ├── desktop/
│   │   ├── default.nix
│   │   │   aggregator for home desktop layer
│   │   │
│   │   ├── hyprland.nix
│   │   │   user-side hyprland config and bindings
│   │   │
│   │   ├── ags.nix
│   │   │   dependency surface for ags2-shell
│   │   │   the shell itself lives elsewhere
│   │   │
│   │   ├── browser.nix
│   │   │   browser configuration and policies
│   │   │
│   │   ├── spotify.nix
│   │   │   spicetify: theming and extensions
│   │   │
│   │   ├── dconf.nix
│   │   │   gsettings state
│   │   │   launcher favorites and defaults
│   │   │
│   │   ├── theme.nix
│   │   │   gtk/icon/cursor wiring
│   │   │
│   │   └── colors.nix
│   │       shared color definitions
│   │
│   ├── dev/
│   │   ├── default.nix
│   │   │   dev tool aggregator
│   │   │
│   │   ├── git.nix
│   │   │   git identity and behavior
│   │   │
│   │   └── lf.nix
│   │       terminal file manager
│   │
│   ├── easyeffects/
│   │   ├── default.nix
│   │   │   symlink rules
│   │   │
│   │   ├── config/
│   │   │   easyeffects state
│   │   │
│   │   └── presets/
│   │       audio presets
│   │
│   ├── nvim/
│   │   ├── default.nix
│   │   │   symlink entrypoint
│   │   │
│   │   └── config/
│   │       neovim config
│   │
│   └── scripts/
│       ├── blocks.nu
│       │   ansi color block probe
│       │
│       ├── nx.nix
│       │   nix shortcuts
│       │
│       └── touchpad.nix
│           touchpad toggle

```
---

## adding packages

edit once:

```nix
home.packages = with pkgs; [
  htop
  neofetch
];
```

apply with `nx-switch`.

---

## common tweaks

* username: `flake.nix`
* timezone / locale: `modules/system/locale.nix`
* keyboard layouts: `hosts/<hostname>.nix`
* monitors: `hosts/<hostname>.nix`
* keybinds: `home/desktop/hyprland.nix`
* disable docker / vms: remove/comment `virtualization.nix` from system imports

monitor names come from `hyprctl monitors`.

---

## default hyprland keybinds

`super` is the main modifier.

### core navigation

| keybind                    | action                           |
| -------------------------- | -------------------------------- |
| super + 1..7               | switch to workspace 1–7          |
| super + shift + 1..7       | move active window to workspace  |
| super + grave              | toggle special workspace         |
| super + shift + grave      | move window to special workspace |
| alt + tab                  | cycle windows                    |
| super + q                  | close active window              |
| super + f                  | toggle fullscreen                |
| super + space              | toggle floating                  |
| super + p                  | toggle split                     |
| super + arrow keys         | move window                      |
| super + shift + arrow keys | resize window                    |

### launcher, overview, session

| keybind             | action                 |
| ------------------- | ---------------------- |
| super + r           | ags launcher           |
| super + tab         | ags overview           |
| ctrl + alt + delete | restart ags shell      |
| super + l           | lock screen (hyprlock) |

### applications

| keybind   | action   |
| --------- | -------- |
| super + b | browser  |
| super + e | nautilus |
| super + x | terminal |

### screenshots and recording

| keybind               | action            |
| --------------------- | ----------------- |
| print                 | screenshot (area) |
| shift + print         | screenshot (full) |
| super + print         | record area       |
| super + shift + print | record screen     |

### media and hardware

| keybind                   | action                |
| ------------------------- | --------------------- |
| xf86audio play/pause      | media play / pause    |
| xf86audio next / prev     | next / previous track |
| xf86audio mute            | toggle output mute    |
| xf86audiomicmute          | toggle mic mute       |
| shift + xf86audiomute     | toggle mic mute       |
| xf86monbrightness up/down | screen brightness     |
| ctrl + f7 / f8            | screen brightness     |
| xf86kbdbrightness up/down | keyboard backlight    |
| xf86touchpadtoggle        | toggle touchpad       |

### mouse bindings

| keybind             | action        |
| ------------------- | ------------- |
| super + left mouse  | move window   |
| super + right mouse | resize window |


---

## notes

* no display manager at the moment
* flakes must be enabled
* first rebuild is special, everything after is routine

---

## license

mit. provided as-is.

---
