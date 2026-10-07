<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkConfig

**4. xWalk software &middot; Module 04**

<!-- xwalk-page-header:end -->

# xWalkConfig

`xWalkConfig` holds the tracked default deployment settings of the desktop: one profile template per build mode,
the standalone demo robot configuration, the generated build-mode header template and the editable help text.
Runtime user overrides are preserved outside this source directory.

## 1. Overview

- `cmake/XWalkBuildMode.cmake` configures
  `desktop-${XWALK_OS_MODE}.cfg.in` into `<build>/generated/desktop.cfg` and `include/XWalkBuildMode.h.in` into
  `<build>/generated/include/XWalkBuildMode.h`. `@XWALK_OS_INTEGRATION_ROOT@` is substituted into host and rpi5
  paths.
- The generated `desktop.cfg` is embedded as the Qt resource `:/desktop.cfg` and installed under
  `share/xwalk-pi5car`. First launch copies it to `~/.config/xWalk/xwalk-desktop/<mode>/desktop.cfg`; existing
  user files are never replaced.
- `XWalkBuildMode` (namespace `xwalk::hal`) exposes the compile-time constants `name`, `standalone` and
  `hardware`. Runtime settings cannot turn stubs into hardware. Do not copy or hand-edit the generated header.
- `xWalkOsHelp.json` holds the `help` text printed by `xwalk-pi5car --help`. It is copied to
  `<build>/config/xWalkOsHelp.json` and installed as `share/xwalk-pi5car/xWalkOsHelp.json`; edits to that runtime
  file apply without rebuilding.

## 2. Source location

`xWalk-rpi5-os/xWalkConfig` - source directory

## 3. Directory layout

```text
xWalkConfig/
    desktop-standalone.cfg.in         Bundled-stub launchers, local robot.cfg, camera disabled
    desktop-host.cfg.in               Host Node and Traffic build paths under the integration root
    desktop-rpi5.cfg.in               Pi runtime/run-xwalk, run-xwalk-traffic and runtime/picar-x.conf
    robot.cfg                         Standalone editing example; never sent to hardware
    include/XWalkBuildMode.h.in       Template for the generated immutable build policy
    xWalkOsHelp.json                  Editable CLI and GUI help text
    test/src/xWalkConfigGoogleTest.cpp  Embedded mode-default contract test
```

## 4. Configuration

All three templates set `camera_frame` (`auto` on host and rpi5, `disabled` in standalone),
`touch_keyboard = true`, `automatic_monitoring = true` and the readiness limits
`readiness_startup_timeout_ms = 45000`, `readiness_fresh_ms = 15000`, `readiness_battery_fresh_ms = 30000` and
`readiness_distance_max_cm = 1000`. The meaning of each key is listed in the
[desktop note](../xWalk-rpi5-os.md#7-configuration).

`robot.cfg` is a standalone editing example (`hardware_board = simulated_robot_hat`, motor output, servo trims,
`proximity_stop_mm`, motor watchdog and `picarx_calibration_verified = false`). It is installed beside
`desktop.cfg` but is never sent to hardware.

## 5. Testing

```bash
ctest --test-dir build-standalone -L xWalkConfig --output-on-failure
```

`xWalkConfig.ModeDefaultsAreEmbedded` loads `:/desktop.cfg` and checks the mode-specific `node_launcher` and the
keyboard and robot-configuration defaults.

## 6. Safety and constraints

- Never commit live credentials, account stores or private deployment overrides here.
- Changing a template affects only new user profiles; existing saved profiles must be edited separately.

## 7. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkConfiguration](../xWalkConfiguration/xWalkConfiguration.md)
- [xWalkDeploy](../xWalkDeploy/xWalkDeploy.md)

---

[Previous page](../xWalkCli/xWalkCli.md) · [Chapter index](../../index.md) · [Next page](../xWalkConfiguration/xWalkConfiguration.md)
