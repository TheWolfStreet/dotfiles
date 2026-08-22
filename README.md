# NixOS Dotfiles

[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue?logo=nixos)](https://nixos.org)
[![Home Manager](https://img.shields.io/badge/Home_Manager-Nix-41439a)](https://github.com/nix-community/home-manager)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff?logo=wayland)](https://hyprland.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A multi-host NixOS and Home Manager configuration built around Hyprland and the [ags2-shell](https://github.com/TheWolfStreet/ags2-shell) desktop shell. Hardware support, user identity, laptop power management, virtualization, and specialized packages are selected per host.

![Desktop preview](thumbnail.png)

## Included

- Hyprland desktop with tuigreet, Hyprlock, GTK/Qt theming, GNOME services, and the packaged AGS shell
- PipeWire and WirePlumber fixed at 44.1 kHz with a 512-sample quantum, plus declarative EasyEffects presets and MIDI hotplug bridging
- NetworkManager, key-only SSH defaults, Flatpak, and declarative Flathub provisioning
- AMD, Intel, and NVIDIA hardware modules with native and 32-bit graphics acceleration
- Optional gaming, laptop power management, containers, libvirt/VM tooling, and Hermes Agent integration
- Home Manager configuration for terminal tools, Neovim, browsers, media and creation applications, development tools, and system utilities
- FL Studio/Bottles integration and optional security, forensics, wireless, and RF tooling

## Current Hosts

| Selector | Machine | Notable configuration |
| --- | --- | --- |
| `ironmaiden` | Lenovo ThinkPad T420, user `ghost` | Legacy Intel VA-API, laptop power, RF/security tooling, no virtualization |
| `nixos` | AMD/NVIDIA desktop, user `tws` | Gaming, virtualization, NVIDIA persistence, host-specific audio and network rules |
| `nixtop` | ASUS TUF Gaming A16, user `tws` | AMD graphics, laptop power, gaming, virtualization, ASUS services, Hermes Agent |

All bundled host files contain machine-specific hardware, monitor, network, or service assumptions. New machines should get a new host selector rather than reusing one of these unchanged.

## Quick Start

### 1. Clone The Repository

The AGS shell is a Git submodule. Clone recursively to `~/.dotfiles`; generated rebuild helpers use that exact path under the configured user's home directory.

```bash
git clone --recurse-submodules https://github.com/TheWolfStreet/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

For an existing non-recursive clone:

```bash
git submodule update --init --recursive
```

### 2. Configure Identity And Hosts

Edit the shared identity values and host registry in `flake.nix`. This example shows how to replace or add selectors; it is not the repository's current host list:

```nix
let
  defaultUsername = "user";
  gitName = "Your Name";
  gitEmail = "you@example.com";

  hosts = {
    laptop = {};
    desktop = {
      username = "another-user";
      hostname = "workstation";
    };
  };
in
# ...
```

Each attribute name is a flake configuration and selects `hosts/<configuration>.nix`. The username defaults to `defaultUsername`; the hostname defaults to the configuration name. Overrides affect the user account, Home Manager path, hostname, and generated rebuild commands together.

### 3. Define The Host

Create `hosts/<configuration>.nix` and import the shared modules plus the machine-generated hardware configuration:

```nix
{
  username,
  ...
}: {
  imports = [
    ./common.nix
    /etc/nixos/hardware-configuration.nix
  ];

  hardware.amd = {
    cpu.enable = true;
    gpu.enable = true;
  };

  gaming.enable = true;
  power.enable = true;
  virtualisation.enable = true;

  home-manager.users.${username}.wayland.windowManager.hyprland.settings = {
    monitor = ["eDP-1,1920x1080@60,0x0,1"];
    input.kb_layout = "us";
  };
}
```

Keep `/etc/nixos/hardware-configuration.nix` outside this repository. Its absolute import is why rebuild commands use `--impure`.

### 4. Build And Boot

```bash
sudo nixos-rebuild boot --flake ~/.dotfiles#<configuration> --impure
sudo reboot
```

Tuigreet starts after boot. The bootstrap password is the configured username; replace it immediately after the first login:

```bash
passwd
```

## Host Options

Hosts compose the common desktop, hardware, and system modules and enable only machine-specific behavior.

| Option | Purpose |
| --- | --- |
| `hardware.amd.cpu.enable` | AMD microcode, `amd_pstate`, and Zenpower |
| `hardware.amd.gpu.enable` | AMDGPU and Mesa graphics support |
| `hardware.amd.gpu.rocm.enable` | ROCm support; defaults to the AMD GPU setting |
| `hardware.amd.gpu.disablePanelSelfRefresh` | Opt-in suspend/resume workaround for affected laptop panels |
| `hardware.intel.cpu.enable` | Intel microcode |
| `hardware.intel.gpu.enable` | Intel graphics and VA-API support |
| `hardware.intel.gpu.vaapiDriver` | `modern` for Broadwell and newer, `legacy` for older GPUs |
| `hardware.nvidia.enable` | NVIDIA driver, Wayland, and video acceleration |
| `hardware.nvidia.persistence.enable` | NVIDIA persistence daemon |
| `gaming.enable` | Steam, Gamescope, Gamemode, and local-transfer firewall support |
| `power.enable` | Laptop power, lid, suspend, and device power policies |
| `virtualisation.enable` | Docker, Podman, libvirt, virt-manager, Boxes, Distrobox, Lazydocker, SPICE USB, and `nx-vm` |
| `hermes.enable` | Hermes Agent; imports `~/.hermes/nixos/hermes.nix` when present, otherwise installs the generic flake package |

Hardware-specific NixOS options can be added directly in a host. Examples include ASUS services, Intel legacy VA-API, RF hardware, Wireshark USB capture, and host-specific NetworkManager or WirePlumber rules. The optional Hermes implementation path is another impure, machine-local input.

Import `../home/pentest.nix` into a host's Home Manager configuration only where the security toolkit is wanted:

```nix
home-manager.users.${username}.imports = [../home/pentest.nix];
```

## Daily Workflow

The installed helpers retain the current flake configuration name even when it differs from the machine hostname.

| Command | Action |
| --- | --- |
| `nx-switch` | Build and switch immediately |
| `nx-boot` | Build and select the generation for the next boot |
| `nx-test` | Activate temporarily without adding a boot entry |
| `nx-update` | Update flake inputs and switch |
| `nx-gc` | Expire old Home Manager generations, collect old Nix generations, and optimize the store |
| `nx-vm` | Build and run the host VM; installed only when virtualization is enabled |
| `hyprlock-revive` | Restore and relaunch Hyprlock after a lock failure |

A typical change is:

```bash
nvim ~/.dotfiles/home/packages.nix
nx-switch
```

Useful direct checks:

```bash
nix flake check --impure
hyprctl monitors
journalctl --user -u ags.service -b
```

## AGS Shell

The root flake builds `ags2-shell` from the submodule, installs the matching AGS CLI, and runs the packaged shell as `ags.service`. The GTK portal backend provides portal settings such as the desktop color-scheme preference. Development, controls, packaging, and native installation are documented in the [submodule README](ags2-shell/README.md).

## Managed User Configuration

- EasyEffects is enabled on every host. Home Manager force-replaces `~/.config/easyeffects` and `~/.local/share/easyeffects` with `home/easyeffects/`; device-specific autoload filenames may need adjustment on another machine.
- `home/music.nix` runs a MIDI hotplug bridge that connects hardware sequencer ports to `Midi Through:0`. The FL Studio Hyprland watcher is also installed globally; Bottles setup and restart requirements are documented in [docs/fl-studio-bottles.md](docs/fl-studio-bottles.md).
- `hermes.enable` is host-gated. It imports `~/.hermes/nixos/hermes.nix` when available and otherwise installs the generic Hermes package with an evaluation warning.

## Repository Layout

```text
~/.dotfiles/
|-- ags2-shell/       # Standalone AGS shell submodule
|-- docs/             # Specialized operational guides
|-- hosts/            # Machine-specific hardware and desktop settings
|-- modules/
|   |-- desktop/      # Hyprland, audio, greeter, Chromium policy, gaming, and desktop services
|   |-- hardware/     # Devices plus AMD, Intel, and NVIDIA options
|   `-- system/       # Base OS, boot, network, power, services, and virtualization
|-- home/
|   |-- desktop/      # AGS, Hyprland, themes, applications, and FL Studio integration
|   |-- terminal/     # Shell, Ghostty, tmux, mail, GPG, and prompt
|   |-- nvim/         # Neovim package and configuration
|   |-- dev/          # Git and development tools
|   |-- easyeffects/  # EasyEffects configuration and presets
|   |-- scripts/      # Rebuild, lock recovery, and touchpad helpers
|   |-- music.nix     # MIDI hotplug bridge
|   |-- packages.nix  # Shared user applications and utilities
|   `-- pentest.nix   # Optional security toolkit
|-- flake.nix         # Inputs, identities, host registry, and system constructor
`-- flake.lock
```

## Common Keybindings

### Navigation And Applications

| Binding | Action |
| --- | --- |
| `Super + 1..7` | Select workspace |
| `Super + Shift + 1..7` | Move window to workspace |
| `Super + grave` | Select special workspace |
| `Super + Shift + grave` | Move window to special workspace |
| `Super + Q` | Close window |
| `Super + F` | Toggle fullscreen |
| `Super + Space` | Toggle floating |
| `Super + P` | Toggle the dwindle split direction |
| `Super + arrows` | Move window |
| `Super + Shift + arrows` | Resize window |
| `Alt + Tab` | Cycle windows |
| `Super + R` | Open launcher |
| `Super + Tab` | Open workspace overview |
| `Super + X` | Open terminal |
| `Super + B` | Open browser |
| `Super + E` | Open file manager |
| `Super + L` | Lock session |
| `Ctrl + Alt + Delete` | Restart AGS shell |
| `Super + mouse left/right` | Move or resize a window |

### Capture And Hardware

| Binding | Action |
| --- | --- |
| `Print` | Select screenshot area |
| `Shift + Print` | Capture focused monitor |
| `Super + Print` | Select recording area |
| `Super + Shift + Print` | Record focused monitor |
| `XF86PowerOff` | Open shutdown confirmation |
| `XF86Audio*` | Media and volume controls |
| `Shift + XF86AudioMute` | Toggle microphone mute |
| `XF86MonBrightness*` | Change display brightness |
| `XF86KbdBrightness*` | Change ASUS keyboard-backlight brightness |
| `XF86TouchpadToggle` | Toggle touchpad |
| `mouse:276` | Push to talk while held |

## Operational Notes

- This configuration tracks unstable inputs and is currently constructed for `x86_64-linux`.
- `/etc/nixos/hardware-configuration.nix` remains machine-local, and enabled Hermes configurations may import `~/.hermes/nixos/hermes.nix`; evaluation and rebuild commands therefore use `--impure`.
- SSH permits public-key authentication by default, denies root login, and disables password authentication unless a host explicitly overrides it.
- Flatpak is enabled system-wide and Flathub provisioning retries until networking becomes available.
- Home Manager conflict backups use the `.hm-bak` extension and are ignored by Git.

## License

MIT. Provided as-is.
