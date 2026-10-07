<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [4. xWalk software](../index.md) / xWalk OS CLI guide

**4. xWalk software &middot; Module 19**

<!-- xwalk-page-header:end -->

# xWalk OS CLI guide

The same pure C++ executable supports the standalone, host and Raspberry Pi 5 profiles.
`--gui` opens the HUD; `--cli` selects terminal commands. `--fullscreen` opens the GUI fullscreen.
Run commands from `xWalkPiCarAI/xWalk-rpi5-os` unless an absolute executable path is shown.

## 1. Terminal help

Use `xwalk-pi5car --help` or `xwalk-pi5car -h` for usage, options, CLI commands, groups,
examples and exit statuses. Both forms print to standard output and exit successfully without a display,
process owner or configuration writes. `--cli --help` prints the same reference.
`./build.sh --help` and `./build.sh -h` describe the build launcher without configuring or building.

## 2. Editable help JSON

The executable is named `xwalk-pi5car`. Its saved configuration directory and process lock retain the old
`xwalk-desktop` name so existing settings and single-owner protection continue to work.

Help text is loaded on every invocation from `config/xWalkOsHelp.json` beside a build executable or
`share/xwalk-pi5car/xWalkOsHelp.json` under an installed prefix. Edit that runtime file directly; no rebuild is
needed. The source template is `xWalkConfig/xWalkOsHelp.json`. To use it or another file directly:

```bash
XWALK_OS_HELP_FILE=/path/to/xWalkOsHelp.json xwalk-pi5car --help
```

The document contains a nonempty `help` array of strings, one string per output line. Missing, oversized or
invalid documents produce a plain stderr error and exit status 1; no GUI or service is started.

## 3. Build and launch

```bash
./build.sh --standalone --gui
./build.sh --host --gui
./build.sh --rpi5 --gui --fullscreen
./build.sh --standalone --cli serve
```

The build launcher configures and builds the selected profile, runs its configured host tests, then launches
the requested interface. Pi builds retain the guarded single-job builder. Put CMake `-D` options before `--cli`.
For everyday commands, use the built executable directly to avoid rebuilding each time.

| Profile | Executable | Backend |
| --- | --- | --- |
| Standalone | `./build-standalone/xwalk-pi5car` | Bundled process and Wi-Fi stubs; no real power actions |
| Host | `./build-host/xwalk-pi5car` | Configured host Node/Traffic executables and NetworkManager |
| Pi 5 | `./build-rpi5/xwalk-pi5car` | Configured Pi Node/Traffic, NetworkManager and OS power controls |

The examples below use standalone. Substitute the appropriate executable for host or Pi.
Runtime commands never change the compiled backend.

```bash
./build-standalone/xwalk-pi5car --cli --help
./build-standalone/xwalk-pi5car --cli --build-mode
./build-standalone/xwalk-pi5car --gui
./build-standalone/xwalk-pi5car --gui --fullscreen
```

Host and standalone use resizable windows with native minimize, maximize and close controls.
F11 toggles fullscreen. `--fullscreen` is a GUI option, not a CLI option; control an existing GUI with
`--cli window fullscreen` instead. `--gui` and `--cli` cannot be combined.

## 4. One process owner

Start the background runtime or a host-owned GUI, then send CLI commands from another terminal under the same OS
user.
The CLI never creates a second Controller alongside the GUI. Each build profile has an independent instance
lock and user-only local socket. There is no TCP listener, shell-command execution, or remote network API.

```bash
./build-standalone/xwalk-pi5car --cli serve
./build-standalone/xwalk-pi5car --cli status
```

`serve` stays in the foreground and works without `DISPLAY` or Wayland. Ctrl+C/SIGTERM shuts down its owned
processes. A second owner is rejected. Without an owner, commands return an error explaining how to start one.
Headless mode uses Qt's offscreen backend; it does not open windows.

For field operation without a touchscreen, use the optional persistent user service described in
[headless deployment](xWalkDeploy/xWalkDeploy.md#headless-field-operation). It survives desktop logout and
restores explicitly configured functional groups without replaying motor commands.

Select a configuration when starting the owner:

```bash
./build-host/xwalk-pi5car --cli serve --config /path/to/desktop.cfg
./build-host/xwalk-pi5car --gui --fullscreen --config /path/to/desktop.cfg
```

Client commands use the running owner's configuration. Do not pass `--config` to a client command.
The `automatic_monitoring` setting controls initial read-only monitoring, just as in the GUI.

## 5. GUI-to-CLI command reference

| GUI operation | CLI command after `--cli` |
| --- | --- |
| Service / Vehicle keys | `start service`, `start vehicle` |
| Vision / Voice / Traffic keys | `start vision`, `start voice`, `start traffic` |
| All key | `start all` |
| Parallel function selection | `start service,vehicle,vision` |
| Press selected function again | `stop service` (or the selected function) |
| Red Stop key | `stop all` |
| Health, battery, sensor and status panels | `health`, `battery`, `sensors`, `status` |
| System events window / Clear | `events list`, `events clear` |
| Desktop configuration editor | `config list desktop`, `config get desktop KEY`, `config set desktop KEY VALUE` |
| Robot/Pi configuration editor | Same commands with target `robot` or an explicit `.cfg`/`.conf` path |
| Numeric slider | `config set TARGET NUMERIC_KEY NUMBER` |
| Wi-Fi radio on / off | `wifi on`, `wifi off` |
| Wi-Fi scan / connect | `wifi scan`, `wifi connect SSID` |
| Camera preview | `camera status`, `camera snapshot FILE.jpg` |
| Settings → Display → Touch keyboard switch | `keyboard on`, `keyboard off` |
| Minimize / maximize / restore | `window minimize`, `window maximize`, `window restore` |
| Fullscreen | `window fullscreen` |
| Capture visible HUD | `window screenshot FILE.png` |
| X close / Exit desktop | `window close` or `quit` |
| Power off / Restart Pi | `power off --confirm`, `power reboot --confirm` |

`start all` selects Service, Vehicle, Vision and Voice. Traffic remains explicitly selected.
`start monitor` selects read-only monitoring. `stop all` stops both owned Controller and Traffic groups,
including monitoring. These commands manage the desktop's owned processes, not unrelated external services.
Repeated `start` of an active function is idempotent. A multi-function failure reports that earlier selections
may remain active; inspect `status` before retrying. Start/stop acceptance is not a readiness guarantee.

```bash
./build-standalone/xwalk-pi5car --cli start service,vehicle
./build-standalone/xwalk-pi5car --cli start traffic
./build-standalone/xwalk-pi5car --cli status
./build-standalone/xwalk-pi5car --cli stop vehicle
./build-standalone/xwalk-pi5car --cli stop all
./build-standalone/xwalk-pi5car --cli quit
```

`quit`, `window close`, configuration writes and power commands require stopped owned services.
Wait for asynchronous shutdown to finish before retrying those commands. GUI window operations are rejected
by a headless owner. Closing an attached GUI leaves the runtime and its CLI endpoint running.
`quit` ends the runtime only after its work is stopped.

## 6. Telemetry and camera

`status`, `health`, `sensors` and `battery` return the current shared telemetry snapshot and HUD display fields.
They do not trigger extra battery samples, movement or lifecycle requests. Missing data remains missing.
Battery values remain the controller's minute averages, retained until the next update.
`battery_charging_estimated` reports the HUD's sustained-voltage-rise heuristic; false means unknown.
It is not a charger connection signal. See [charging limitations](xWalkRuntime/xWalkRuntime.md).
Standalone stubs do not simulate the full robot telemetry protocol.

```bash
./build-host/xwalk-pi5car --cli health
./build-host/xwalk-pi5car --cli sensors
./build-host/xwalk-pi5car --cli battery
./build-host/xwalk-pi5car --cli camera status
./build-host/xwalk-pi5car --cli camera snapshot /tmp/xwalk-camera.jpg
```

Camera commands use the configured shared JPEG producer, never a second CSI camera owner. Snapshots require
a frame less than three seconds old and a new, writable destination. There are no motor movement commands in
the OS HUD, so this CLI does not introduce drive, pan/tilt or autonomous-operation commands.

## 7. Configuration and keyboard

Targets are `desktop`, `robot`, or an explicit existing configuration path. Reads include inherited values.
Writes use the same atomic save, backup, comment retention, include handling and concurrent-edit checks as
the GUI. Only existing keys can be changed. Stop owned services first. Desktop reload can restart monitoring
if `automatic_monitoring` remains enabled.

```bash
./build-standalone/xwalk-pi5car --cli config list desktop
./build-standalone/xwalk-pi5car --cli stop all
./build-standalone/xwalk-pi5car --cli config set desktop automatic_monitoring false
./build-standalone/xwalk-pi5car --cli config set desktop touch_keyboard true
./build-standalone/xwalk-pi5car --cli config get desktop touch_keyboard
```

Quote values containing spaces. For a negative value, place `--` before the value to end option parsing.
Numeric values use the GUI editor's bounds and integer/decimal type; boolean fields accept only `true` or `false`.
The owning runtime also validates hardware-specific rules. `keyboard on|off` changes the current session;
use configuration commands to persist it.
Printed configuration may contain local sensitive values, so redirect output only to an appropriate location.

## 8. Wi-Fi

```bash
./build-standalone/xwalk-pi5car --cli wifi scan
./build-standalone/xwalk-pi5car --cli wifi connect "Test network"
./build-host/xwalk-pi5car --cli wifi connect "My network" --password-stdin < /path/to/private-password-file
./build-host/xwalk-pi5car --cli wifi connect "Hidden network" --hidden --password-stdin < /path/to/private-password-file
```

The password file contains one line and should be readable only by its owner. Passwords are not accepted as
command-line arguments and are delivered to NetworkManager through stdin. Omit `--password-stdin` for an open
or saved network. Standalone returns simulated results without modifying networking. Host/Pi requests use the
same OS authorization as the GUI. Enterprise Wi-Fi setup belongs in the OS network editor.
Scan output uses nmcli's escaped colon-separated `SSID:SIGNAL:SECURITY` format inside the JSON `output` field.

## 9. Power and results

Only a Pi build accepts actual power actions, with stopped owned services and explicit `--confirm`:

```bash
./build-rpi5/xwalk-pi5car --cli stop all
./build-rpi5/xwalk-pi5car --cli status
./build-rpi5/xwalk-pi5car --cli power reboot --confirm
```

Power actions remain subject to system authorization; the CLI does not elevate privileges.
The connection can close during a successful reboot/power-off, so loss of the response is not proof of failure.

Client output is one JSON object with an `ok` boolean. Exit status `0` means success/accepted, `1` means a
command or transport failure, and `2` means invalid startup/CLI usage or an unavailable owner lock.
An accepted process action completes asynchronously. Check `status` and `events list` for runtime failures.
Transport timeout or disconnect can leave the command outcome unknown; inspect state before retrying.
`--cli --help` and `--cli --build-mode` print human-readable information instead of JSON.

## 10. Host traffic video replay

Start the host GUI or `--cli serve`, then load and start a local video:

```bash
./build-host/xwalk-pi5car --cli traffic video "/absolute/path/to/traffic clip.mp4"
./build-host/xwalk-pi5car --cli status
./build-host/xwalk-pi5car --cli stop traffic
./build-host/xwalk-pi5car --cli start traffic
./build-host/xwalk-pi5car --cli stop traffic
./build-host/xwalk-pi5car --cli traffic default
```

Wait for `traffic: false` before changing the source. Relative video paths resolve in the CLI caller's directory.
The selection is retained for this desktop session (including the Traffic artwork button); `traffic default`
clears it without starting a process. A configuration reload or desktop restart also clears a CLI selection.
`status.traffic_video` reports the selected file. To preload a file persistently, add
`traffic_video = /absolute/path/to/clip.mp4` to the host desktop configuration.

This launches the configured `traffic_binary` directly with `--host --video FILE` in the existing owned Traffic
process group. It uses real decoding, trained models, classification, announcement pacing and the Traffic
Controller's MQTT configuration. EOF ends the run; it does not loop or emulate real-time camera pacing.
Build/install the host Traffic Controller and its trained model assets first. Missing executables are rejected;
invalid video contents, missing models and runtime failures appear in the system-error window.
Acceptance means process launch was requested, not that inference has finished or MQTT delivery succeeded.
The existing `xWalkHostTest.conf` disables MQTT by default. Enable it in the Traffic host configuration and
select a test MQTT destination when broadcast replay is needed.
Standalone and Pi builds reject this command; Pi camera capture is unchanged.

## 11. OS diagnostics

Use the new `OS` trace tag to enable lifecycle information:

```bash
./build-host/xwalk-pi5car --gui --trace OS.enable
./build-standalone/xwalk-pi5car --cli serve --trace OS.enable
```

Warnings/errors remain enabled independently. Records go to `<build>/log/xWalkTrace.log`, with no trace
text added to CLI JSON responses or the GUI error window. See [trace IDs and backend
details](../../07-xwalk-trace/xWalk-rpi5-trace/docs/OS_TRACES.md).

`session stop` is the HUD Stop key: stop owned processes and telemetry, retaining the functional selection.
After shutdown completes, `session start` is Play: launch that selection from the beginning and resume telemetry.
These commands never resume an old movement request. `stop all` remains an unconditional service stop.

Power and Restart on the Pi ask for confirmation, stop owned processes, then request system poweroff or reboot
through systemd/logind (the system action equivalent to `sudo shutdown now` or `sudo reboot`). No password is
stored in the HUD. Host and standalone modes cannot power off the computer.

## 12. Reconnecting the touchscreen HUD

On Pi, `--gui` automatically attaches to the persistent user runtime; install the services described in
[xWalkDeploy](xWalkDeploy/xWalkDeploy.md#headless-field-operation). For host and standalone, use `--attach`
to require a background owner. A GUI also attaches automatically if another owner already holds the lock.

```bash
./build-host/xwalk-pi5car --cli serve --config /path/to/desktop.cfg
./build-host/xwalk-pi5car --gui --attach
```

The attached HUD uses the runtime's configuration. Select a custom file when starting `serve`.
Closing the HUD, disconnecting the display, or restarting the desktop does not change selected functions.
`--cli toggle GROUP` toggles one selection atomically. `--cli session toggle` implements STOP/Play.
`--cli config reload` reloads saved settings only when all owned processes are stopped.

---

[Previous page](xWalkTest/xWalkTest.md) · [Chapter index](../index.md) · [Next page](../../05-xwalk-node/index.md)
