# Exercise — SquareLine + SDL2 emulator [class instruction]

**Date**: 2026-05-08 09:46-09:54 GMT+7
**Teacher**: P'Nat msg `1502137917735305236` in #esp32-dev:
> "build squareline with sdl2 emulator on your os and show me the result! @everyone"

**Interpretation**: SquareLine Studio is a proprietary GUI editor (no headless install). The class-relevant pattern is its output → LVGL + SDL2 host simulator. So the exercise is: build LVGL with SDL2 backend on Linux + show it running.

## Build path

| Step | Time | Notes |
|------|------|-------|
| `ghq get -u lvgl/lv_port_linux` | ~3s | recursive submodule clone (lvgl @ f68c6bd) |
| `sudo apt install libsdl2-dev libsdl2-image-dev libevdev-dev libxkbcommon-dev cmake build-essential` | ~30s | system deps |
| `cmake -B build -DCONFIG=sdl` | 7.2s | uses `configs/sdl.defaults` |
| `cmake --build build -j$(nproc)` | **215.11s** | `bin/lvglsim` 3.5MB |
| `sudo apt install xvfb scrot` | ~10s | for headless screenshot |
| `xvfb-run -s "-screen 0 800x600x24" lvglsim` + `scrot` | ~5s | virtual framebuffer + capture |

## Result

Two screenshots captured at 3s and 5s of LVGL widgets demo rendering:
- `screenshots/lvglsim-3s.png` (25.8 KB)
- `screenshots/lvglsim-5s.png` (35.1 KB)

Visible in screenshot: LVGL v9.6.0 "Widgets demo" — Profile/Analytics/Shop tabs, bar chart (Roman numeral I-VI), gauges (Monthly Target / Sessions / Network Speed), live FPS overlay (29 FPS, CPU 60%/13%, 9 ms frame time).

**Proof of life**: simulator renders, animates (different state at 3s vs 5s), and reports performance overlay correctly.

## What I learned

- `lv_port_linux` is the canonical LVGL host port. Configs presets in `configs/*.defaults` map to backends (sdl, fbdev, drm-egl, glfw, wayland, x11)
- `cmake -DCONFIG=sdl` is the one-line preset path — much cleaner than hand-flipping `LV_USE_SDL` in `lv_conf.defaults`
- Screen capture under headless requires Xvfb; `xvfb-run` wraps the env setup. Combine with `scrot` for one-shot stills
- SquareLine Studio itself isn't needed for the host-sim pattern — its export = C source files + LVGL config, which `lv_port_linux` already provides as a working baseline. Real Squareline workflow: design → export `ui/` dir → drop into `src/` of `lv_port_linux` → rebuild.

## What I would do next

- Wire a SquareLine-exported `ui/` directory (or hand-rolled LVGL screen) into `src/main.c` and rebuild — that's the real "your-design + simulator" loop.
- Add input event capture (mouse → SDL → LVGL pointer) and verify with click → state change in screenshots.
- For ESP32 deploy: cross-compile LVGL config into a PlatformIO project (board: ESP32 + ST7789/ILI9341 display).

## Cross-reference

- Source: github.com/lvgl/lv_port_linux (commit submodule lvgl@f68c6bd)
- LVGL: v9.6.0 (per banner)
- SDL2: 2.30.0 (Ubuntu 24.04)
- Class instruction: P'Nat msg `1502137917735305236` in #esp32-dev
