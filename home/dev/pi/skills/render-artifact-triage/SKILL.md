---
name: render-artifact-triage
description: Diagnose visual artifacts in a real-time renderer (ghosting, shimmer, halos, judder) by isolating the responsible stage before changing code. Use when a user reports something looks wrong on screen and the cause is not yet known.
---

# Render artifact triage

Do not change shaders on a hunch. Identify the stage first, then make one change.

## 1. Find the shared path

Get the user to name a second app/scene showing the same artifact. Then diff what they share.
Anything not in the intersection is eliminated for free. Check what each actually uses
(material, post chain, passes) rather than assuming — e.g. one demo on `pbr`, another on
`basic`, means BRDF edits cannot explain an artifact common to both.

## 2. Apply the math test

Ask what each remaining stage can physically produce:

- **Convex combinations** — bilinear, trilinear, anisotropy, mip generation, box blur,
  `VK_RESOLVE_MODE_AVERAGE_BIT`: weights non-negative summing to 1, so output is bounded by
  min/max of inputs. Cannot create a halo, cannot brighten an edge.
- **Monotonic curves** — tonemap, gamma: `f(avg)` stays between `f(a)` and `f(b)`. Concavity
  makes edges harsher than curve-then-average, but never out of bounds.
- **Negative lobes** — cubic/Lanczos/`VK_FILTER_CUBIC`, unsharp, FSR's RCAS, CAS: the *only*
  things that overshoot. Grep for them; confirm opt-in features are actually compiled and linked
  (`CMakeCache.txt`, `nm`, `ldd`), not merely present in-tree.

If nothing in the path has negative lobes, the halo is not from the renderer.

## 3. Match the signature

| Symptom | Cause |
|---|---|
| Shimmer/crawl on ground at grazing angles | `VK_SAMPLER_MIPMAP_MODE_NEAREST` or no anisotropy |
| Smeared trail behind moving edges | temporal accumulation, or display persistence |
| Bright on dark→light **and** dark on light→dark | LCD overdrive overshoot — panel, not code |
| Doubled/strobing edges | frame pacing; `dt` sampled at the wrong point vs present |
| Horizontal bands offset along motion | tearing; check present mode is FIFO |
| Input stutter | see below |

Signed, direction-dependent fringing is always the panel. MSAA does not antialias shading,
only geometry edges — tile/texture aliasing needs filtering or TAA.

## 4. Rule out the compositor and panel

```sh
hyprctl monitors                     # scale != 1.00 means resampling; note refresh rate
hyprctl getoption decoration:blur:enabled
hyprctl getoption decoration:screen_shader
hyprctl keyword monitor eDP-1,1920x1200@60,0x0,1   # different overdrive tuning at 60 Hz
```

Decisive test: a screenshot captures the framebuffer *before* the panel. Clean PNG + visible
artifact on screen = display. Also `testufo.com/ghosting`.

If it is overdrive, check for a panel overdrive/"response time" toggle in BIOS or vendor
software — some laptops do expose one. Disabling it removes the overshoot fringes and trades
them for slower, softer transitions, usually a win above 120 Hz.

## 5. Input stutter is usually frame bookkeeping

Host loops often poll events themselves (e.g. `glfw_host::open()` calls `glfwPollEvents()`).
An app that then calls `input::frame()` *before* reading wipes motion the host already collected,
so only events landing in the gap survive — jitter that tracks frame pacing. `frame()` ends a
frame: call it last, after everything has read. Also drop the warp delta when capturing the
cursor, or the view snaps.

## Rules

- Measure before concluding: frame rate, `hyprctl`, actual device limits via `caps()`.
- Verify a fix is live rather than assuming (query the feature/limit you just enabled).
- State plainly when evidence points outside the code; do not invent a renderer fix to look busy.
