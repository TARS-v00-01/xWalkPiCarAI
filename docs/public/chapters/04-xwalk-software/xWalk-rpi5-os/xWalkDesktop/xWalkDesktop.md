<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkDesktop

**4. xWalk software &middot; Module 10**

<!-- xwalk-page-header:end -->

# xWalkDesktop

`xWalkDesktop` renders the scalable robot HUD and live telemetry display: the artwork canvas, function keys,
gauges, camera and Traffic preview, event console, Pi 5 illustration, boot-readiness overlay and shutdown screen.

## 1. Overview

- `XWalkHud` scales the supplied HUD artwork as one canvas with live overlays and touch and mouse controls. It owns
  the `XWalkProcesses` coordinator, serves same-user CLI commands as the sole process owner, or attaches to the
  background runtime as a reconnecting client. The complete control behavior is described in the
  [desktop note](../xWalk-rpi5-os.md#controls).
- `XWalkFunctionGlow` draws the purple holographic glow behind active function keys with a 2.4 s breathing pulse,
  redrawn at 25 FPS only while a key is active and the HUD is visible.
- `XWalkPiIllustration` renders the official Pi 5 CAD mesh and reference-based HAT from real 3D triangles at up
  to 30 FPS.
- `XWalkEventConsole` shows the last 100 system failures with severity rows and ALL / ERRORS / WARNINGS filters.
- `XWalkBootScreen` is the non-blocking boot-readiness overlay and the static shutdown display. It presents the
  owner's verdict without inventing readiness, reveals the HUD on READY or timeout (default 45000 ms), and
  replaces readiness with the unmodified `:/shutdown-artwork.png` on power-off or reboot.
- Camera frames are read at 10 FPS; frames older than three seconds are hidden as stale. Gauges are redrawn once
  per resize at device resolution.

### Battery charging indication

The battery symbol shows a green outline and lightning bolt with `CHARGING · EST.` when the
[voltage trend](../xWalkRuntime/xWalkRuntime.md) suggests charging. The existing percentage and fill remain the
received battery estimate. This is automatic and needs no manual charger toggle; the label and tooltip
("Estimated charging: sustained voltage rise. Charger presence is not measured.") identify its uncertainty.
Otherwise the tooltip states that charging status is unknown because the Robot HAT reports voltage only. The
physical HAT charging LED remains the charging reference.

While the charging estimate is active, the battery fill blinks one second on and one second off. The outline,
lightning bolt, percentage and estimate label remain visible. This is a display-only animation; battery requests
continue every ten seconds and the charging trend still compares readings about one minute apart.

## 2. Source location

`xWalk-rpi5-os/xWalkDesktop` - source directory

## 3. Directory layout

```text
xWalkDesktop/
    CMakeLists.txt                        Static library xWalkOsDesktop and its Google Test
    include/XWalkHud.h                    Main HUD widget, theme, CLI command entry and shutdown observer
    include/XWalkBootScreen.h             Boot-readiness overlay and shutdown artwork
    include/XWalkEventConsole.h           Event record, delegate and full-screen console
    include/XWalkFunctionGlow.h           Active function-key glow
    include/XWalkPiIllustration.h         Rotating Pi 5 and HAT mesh renderer
    src/XWalkHud.cpp                      Canvas, gauges, telemetry overlays and camera panel
    src/XWalkHudCommands.cpp              CLI command handling against the owned runtime
    src/XWalkHudAttachment.cpp            Reconnecting client mode for the background runtime
    src/XWalkHudSettingsMenu.cpp          Android tablet-style Settings screen
    src/XWalkBootScreen.cpp, src/XWalkEventConsole.cpp, src/XWalkFunctionGlow.cpp, src/XWalkPiIllustration.cpp
    test/include/XWalkDesktopTestSupport.h  Test-only access to the gauge painter
    test/src/xWalkDesktopGoogleTest.cpp     HUD, dialog, boot, shutdown and opt-in live tests
```

## 4. Public interface

Namespace `xwalk::hal`:

- `XWalkHud`: `applyTheme()`, `setFullscreen(bool)`,
  `services()`, `touchKeyboardEnabled()`, `command(request, reply)` and
  `observeSystemShutdown(path = "/run/xwalk/shutdown-mode")`; signal `keyboardModeChanged(bool)`.
- `XWalkBootScreen`:
  `advance(readiness, elapsedMs)`, `shutdown(reboot, path)` and signal `completed(bool ready)`.
- `XWalkEventConsole`,
  `XWalkFunctionGlow` and
  `XWalkPiIllustration`.

## 5. Build

CMake target `xWalkOsDesktop` (static, C++17) links `Qt5::Widgets`, `xWalkOsConfiguration`, `xWalkOsRuntime`,
`xWalkOsSettings`, `xWalkOsNetwork`, `xWalkOsCli` and `xWalkOsBuild`, and compiles with
`-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through the [desktop root](../xWalk-rpi5-os.md)
to compose its dependencies.

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkDesktop --output-on-failure
```

Host tests cover idle startup, small-display fit, device-resolution gauges, artwork controls and dialogs, nested
HUD menus, the event console, Traffic preview freshness and risk badges, attachment, display changes, boot
readiness and timeout, and shutdown and power-failure recovery. Set `XWALK_OS_TEST_SCREENSHOTS` to save preview
images from the charging-gauge test.

`xWalkDesktop.OptInLiveTelemetryRetention` is labelled `xWalkDesktop;hardware` with a 240-second timeout and is
excluded from ordinary discovery. List it with `ctest -N -L hardware`; run it only with explicit approval and a
confirmed safe Raspberry Pi and Robot HAT setup. It skips unless `XWALK_OS_LIVE_TEST_CONFIG` is set. See the
[desktop note](../xWalk-rpi5-os.md#8-testing) for its procedure.

## 7. Safety and constraints

- Preview and screenshot modes never start configured monitoring or robot processes.
- The boot overlay never sends actuator commands and never declares readiness without the owner's verdict.
- Power requests paint the shutdown screen before stopping owned processes; duplicate requests do not spawn
  another power command.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkKeyboard](../xWalkKeyboard/xWalkKeyboard.md)
- [xWalkResources](../xWalkResources/xWalkResources.md)

---

[Previous page](../xWalkDeploy/GNOME_KEYBOARD.md) · [Chapter index](../../index.md) · [Next page](../xWalkKeyboard/xWalkKeyboard.md)
