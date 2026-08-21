# FL Studio with Bottles on NixOS and Hyprland

This guide records the reproducible parts of the working FL Studio environment on this machine. The referenced modules are the source of truth for declarative system and Home Manager configuration.

## Result

- FL Studio runs in the custom `Music` bottle through XWayland.
- The bottle uses the newest installed Kron4ek runner, Vulkan, DXVK, VKD3D, and FSync.
- Bottles runtime injection and Wine's experimental Wayland driver are disabled.
- DejaVu-based Segoe-compatible fonts provide the glyphs expected by FL Studio.
- A Hyprland watcher hides FL's blank VCL owner window and Pianoteq's opaque menu-edge windows.
- A user service routes readable hardware ALSA MIDI ports through stable `Midi Through Port-0`, allowing controllers connected after Wine starts to work.

## Repository Sources

The declarative implementation is maintained in these files:

```text
home/desktop/fl-studio.nix  FL and Pianoteq XWayland watcher
home/desktop/default.nix    Imports the FL module
home/music.nix              Generic ALSA MIDI hot-plug bridge
home/packages.nix           Bottles and alsa-utils
modules/desktop/audio.nix   PipeWire rate and quantum
modules/desktop/hyprland.nix
modules/hardware/amd.nix
modules/hardware/nvidia.nix
modules/system/base.nix     Imports the Home Manager music module
modules/system/boot.nix     Zen kernel and threadirqs
```

Generated `/nix/store` paths are rebuilt from this flake.

## Machine Paths

Current paths are:

```text
Dotfiles:  /home/tws/.dotfiles
Bottle:    /home/tws/Software/Music/Prefix
Runner:    /home/tws/.local/share/bottles/runners/kron4ek-wine-11.11-staging-tkg-amd64
FL binary: /home/tws/Software/Music/FL Studio 21/FL64.exe
FL data:   /home/tws/Software/Music/FL Studio Data
```

Replace `/home/tws` consistently for another user. A standard Bottles-managed prefix is also valid.

## Hardware Selection

Identify the actual display hardware before setting any EGL override:

```bash
lspci -nnk -d ::0300
lspci -nnk -d ::0302
ls /run/opengl-driver/share/glvnd/egl_vendor.d
ls /run/opengl-driver-32/share/glvnd/egl_vendor.d
```

This machine is AMD-only and uses `amdgpu`. Its bottle deliberately has no `__EGL_VENDOR_LIBRARY_FILENAMES` override and uses Mesa's normal GLVND discovery.

Use these rules on another machine:

| Hardware | EGL behavior |
| --- | --- |
| AMD or Intel | Omit the override first. Pin `50_mesa.json` only after reproducing a vendor-selection problem. |
| AMD plus Intel | Omit the override and use `DRI_PRIME` for device selection. |
| NVIDIA-only | Omit the override first. If Mesa probing causes the known issue, pin `/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json` for this bottle. |
| NVIDIA plus Mesa hybrid | Keep both vendors available; an exclusive single-vendor filename override breaks one side. |
| FHS vendor discovery failure | Prefer `__EGL_VENDOR_LIBRARY_DIRS` containing both `/run/opengl-driver` EGL directories. |

Wine needs both 64-bit and 32-bit graphics support. The relevant NixOS hardware modules in this repository already configure that support.

## Build and Activate Nix

Validate the current laptop Home Manager generation without activation:

```bash
cd /home/tws/.dotfiles
nix build .#nixosConfigurations.nixtop.config.home-manager.users.tws.home.activationPackage --impure --no-link
```

If newly created files are still untracked, Git-backed flakes omit them. During development, build the path directly:

```bash
nix build 'path:.#nixosConfigurations.nixtop.config.home-manager.users.tws.home.activationPackage' --impure --no-link
```

Apply the full host configuration:

```bash
cd /home/tws/.dotfiles
sudo nixos-rebuild switch --flake .#nixtop --impure
```

After activation, verify the MIDI service:

```bash
systemctl --user daemon-reload
systemctl --user enable --now midi-hotplug-bridge.service
systemctl --user status midi-hotplug-bridge.service
```

Restart the Hyprland session after activation. `hyprctl reload` does not rerun `exec-once`, so it will not start a newly added FL watcher.

## MIDI Prerequisite

The kernel module `snd_seq_dummy` supplies the stable `Midi Through` client. Confirm it exists before starting Wine:

```bash
lsmod | rg '^snd_seq_dummy'
aconnect -l
```

Expected endpoint:

```text
client N: 'Midi Through' [type=kernel]
    0 'Midi Through Port-0'
```

The numeric client ID is not stable. The Home Manager service addresses it by name as `Midi Through:0`.

## Runner and Bottle

Install or import this runner in Bottles:

```text
kron4ek-wine-11.11-staging-tkg-amd64
```

Use Nixpkgs Bottles rather than launching the runner directly. Nixpkgs supplies the multi-architecture FHS environment required by Wine on NixOS.

Create or configure the bottle with this identity:

```yaml
Arch: win64
Environment: Custom
Name: Music
Path: /home/tws/Software/Music/Prefix
Runner: kron4ek-wine-11.11-staging-tkg-amd64
Windows: win7
```

The important bottle components and parameters are:

```yaml
DXVK: dxvk-2.7.1-19-b0bb947
VKD3D: vkd3d-proton-3.0.1-2-c150088
NVAPI: dxvk-nvapi-v0.7.1  # gitleaks:allow — component version, not a credential
Environment_Variables: {}
Parameters:
    custom_dpi: 96
    decorated: true
    discrete_gpu: true
    dxvk: true
    dxvk_nvapi: false
    fixme_logs: false
    fsr: false
    fullscreen_capture: false
    gamemode: false
    gamescope: false
    latencyflex: false
    mouse_warp: true
    pulseaudio_latency: false
    renderer: vulkan
    sandbox: false
    sync: fsync
    take_focus: true
    use_be_runtime: false
    use_eac_runtime: false
    use_runtime: false
    use_steam_runtime: false
    virtual_desktop: false
    vkd3d: true
    wayland: false
    winebridge: false
```

Disabling all runtime toggles is intentional. Bottles 64.1 can construct a character-split `LD_LIBRARY_PATH` when its runtime is enabled, and the downloaded runtime layout on NixOS does not match the paths Bottles expects.

Install required dependencies through Bottles' dependency installer so DLL overrides are applied consistently:

```text
andale32 arial32 arialb32 comic32 courie32 georgi32 impact32
tahoma32 times32 trebuc32 verdan32 webdin32 allfonts cjkfonts
mfc42 d3dcompiler_46 d3dcompiler_47 d3dx9 d3dx11
dmsynth dmusic dsound gdiplus
```

## Registry Tuning

The current import files live inside the prefix:

```text
C:\fl-wine-tuning.reg
C:\fl-segoe-fonts.reg
```

`fl-wine-tuning.reg` configures Vulkan rendering, mouse warp, X11 focus/decorations, disables `winemenubuilder`, removes stale Segoe replacement mappings, and disables FL-specific repaint/transparency hacks.

With FL Studio and all processes in this bottle closed, import both files through Bottles:

```bash
PREFIX=/home/tws/Software/Music/Prefix
bottles-cli run -b Music -e "$PREFIX/drive_c/windows/regedit.exe" -- /S 'C:/fl-wine-tuning.reg'
bottles-cli run -b Music -e "$PREFIX/drive_c/windows/regedit.exe" -- /S 'C:/fl-segoe-fonts.reg'
```

Forward slashes are intentional. Bottles CLI 64.1 stripped the backslash from `C:\fl-wine-tuning.reg` on this host and passed `C:fl-wine-tuning.reg` to Regedit.

## Segoe-Compatible Fonts

The prefix contains these generated fonts under `drive_c/windows/Fonts`:

```text
segoeui.ttf   DejaVu Sans, renamed to Segoe UI Regular
segoeuib.ttf  DejaVu Sans Bold, renamed to Segoe UI Bold
segoeuii.ttf  DejaVu Sans Oblique, renamed to Segoe UI Italic
segoeuiz.ttf  DejaVu Sans Bold Oblique, renamed to Segoe UI Bold Italic
seguisb.ttf   DejaVu Sans Bold, renamed to Segoe UI Semibold at weight 600
seguisym.ttf  DejaVu Sans, renamed to Segoe UI Symbol
```

For a new prefix, resolve `nixpkgs#dejavu_fonts` and use FontTools to copy each source font and rewrite TrueType name IDs `1`, `2`, `3`, `4`, `6`, `16`, `17`, `21`, and `22` to the family/style names above. Set `OS/2.usWeightClass` to `600` for `seguisb.ttf`. Register the resulting filenames with `fl-segoe-fonts.reg`.

`Fonts\Replacements` values mapping Segoe UI to Times New Roman override the generated family and must be absent.

FontTools updates font metadata when saving, so checksums can differ across versions or generation times. Validate internal family names and glyph coverage rather than relying only on hashes.

## FL Studio Setup

Register a Bottles program named `FL Studio 21` pointing to:

```text
/home/tws/Software/Music/FL Studio 21/FL64.exe
```

Launch it with:

```bash
bottles-cli run -p 'FL Studio 21' -b Music
```

Current FL audio assumptions:

- 44.1 kHz sample rate.
- PipeWire graph quantum fixed at 512 frames by the repository audio module.
- Wine uses `winepulse.drv`; WineASIO is not configured.
- Multithreaded mixer and generator processing are enabled.
- FL DWM refresh, Surface Pro DWM hack, and transparent forms are disabled.

For reliable MIDI hot-plug:

1. Start `midi-hotplug-bridge.service` before FL Studio.
2. Enable only `Midi Through Port-0` as the persistent FL input.
3. Disable native hardware entries when using the bridge, or notes can be delivered twice.
4. Connect a controller after FL starts and allow up to one second for the bridge.

Wine caches WinMM MIDI enumeration at process startup. FL's refresh button cannot add a native controller that Wine did not see at startup. The stable MIDI Through proxy is the workaround, and multiple physical controllers are merged into it.

## Verification

Confirm critical bottle values:

```bash
rg -n 'Runner:|Windows:|renderer:|sync:|wayland:|use_.*runtime:|take_focus:|__EGL' \
  /home/tws/Software/Music/Prefix/bottle.yml
```

Expected values include:

```text
Runner: kron4ek-wine-11.11-staging-tkg-amd64
Windows: win7
renderer: vulkan
sync: fsync
take_focus: true
wayland: false
use_runtime: false
use_steam_runtime: false
use_eac_runtime: false
use_be_runtime: false
```

While FL is running, inspect its environment:

```bash
pid="$(hyprctl -j clients | jq -r '.[] | select(.class == "fl64.exe") | .pid' | sort -u | sed -n '1p')"
tr '\0' '\n' < "/proc/$pid/environ" | rg '^(LD_LIBRARY_PATH|WINEDLLOVERRIDES|PROTON_)='
```

The runner paths in `LD_LIBRARY_PATH` must be complete path elements, not individual characters separated by colons. EAC and BattlEye runtime variables should be absent.

Verify MIDI routing:

```bash
systemctl --user status midi-hotplug-bridge.service
aconnect -l
```

Expected route:

```text
physical controller -> Midi Through:0 -> WINE ALSA Input
```

Open FL and Pianoteq to validate the compositor workarounds visually:

- FL's empty-title 800x800 helper should be resized to 1x1.
- Normal FL popup menus must remain visible.
- Pianoteq menu bodies titled `menu` must remain interactive.
- Empty-title 12-pixel Pianoteq edge windows should have active and inactive opacity overridden to zero.

## Limitations

- Native-name MIDI hot-plug is not supported; controllers are merged through `Midi Through`.
- The XWayland workarounds depend on current FL and Pianoteq window geometry and titles.
- Final VST flicker status still requires visual testing with representative plugins.
- Hyprland fullscreen state is not synchronized with FL's internal maximize state.
- Gamescope, GameMode, and WineASIO are not part of this setup.
