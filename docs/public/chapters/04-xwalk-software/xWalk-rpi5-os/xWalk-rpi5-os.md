<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [4. xWalk software](../index.md) / xWalk-rpi5-os

**4. xWalk software &middot; Module 01**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-os

`xWalk-rpi5-os` is the native C++17 / Qt 5 Widgets desktop for the Raspberry Pi 5 touchscreen. It builds one
executable, `xwalk-pi5car`, that renders the xWalk robot command HUD, owns the Controller and Traffic processes,
exposes the same operations through a local command-line interface, and configures Wi-Fi through NetworkManager.

## 1. Overview

- The supplied `xWalkResources/xWALK Robot Command HUD.png` is embedded unchanged as one continuous background.
- The interface targets 1280 × 720, preserves the artwork's proportions, and also accepts mouse and keyboard.
  On the Pi's 800 × 480 HDMI touchscreen it fills the panel width at 0.48 scale.
- The artwork, CPU, temperature and battery gauges, Stop/Play key and camera frames are resampled once per
  resize at device resolution, so they are drawn almost pixel for pixel instead of being shrunk every frame.
- Live text uses fixed pixel sizes (16 to 36 artwork pixels, bold for short values) that stay readable on the
  small panel and sharp up to 1080p. Live fields cover the artwork's illustrative readings; CPU gauges are drawn
  in C++.
- There is no Python, JavaScript, browser, QML or web server in the application. All runtime code and tests are
  C++; images are embedded through Qt resources.
- This is a fullscreen desktop application, not an operating-system image or a replacement window manager.
- Read-only monitor mode starts automatically; no movement or lifecycle commands are sent. Hardware ownership and
  runtime safety are delegated to the existing Node/Controller implementation; direct function selection does not
  bypass its runtime checks.

The build backend is fixed at configure time by `XWALK_OS_MODE`:

| Profile | Runtime behavior | Output |
| --- | --- | --- |
| `standalone` | Bundled C++ process stubs, simulated Wi-Fi; power disabled | `build-standalone/xwalk-pi5car` |
| `host` | Real host Node and Traffic, real NetworkManager; power disabled | `build-host/xwalk-pi5car` |
| `rpi5` | Real ARM64 Node/Robot HAT runtime, NetworkManager, authorized power | `build-rpi5/xwalk-pi5car` |

Standalone ignores configured process executable paths, so it cannot accidentally start a real robot process.
Its stub supports Service, Vehicle, Vision, Voice, Traffic and All, with readiness and heartbeat logs. It does
not emulate sensors, MQTT or the complete robot protocol. CPU telemetry describes the actual computer.

## 2. Source location

`xWalk-rpi5-os` - source directory

## 3. Directory layout

```text
xWalk-rpi5-os/
    CMakeLists.txt          Root project (xWalkDesktop 1.0.0); composes every module and the trace backend
    CMakePresets.json       standalone, host and rpi5 configure/build presets; standalone and host test presets
    build.sh                Profile build launcher with optional --gui, --fullscreen and --cli
    cmake/
        XWalkBuildMode.cmake  XWALK_OS_MODE validation, generated build-mode header, profile cfg and resources
    ci/
        run-host-ci.sh      Module-owned standalone/host build, test and staged-install gate
    .github/workflows/      Standalone GitHub quality workflow and CI log archive
    xWalkMain/              Application entry point (xwalk-pi5car)
    xWalkCli/               Same-user GUI/headless local JSON command transport
    xWalkDesktop/           HUD rendering, controls, telemetry display, boot and shutdown screens
    xWalkRuntime/           Controller and Traffic process lifecycle, telemetry and readiness
    xWalkConfiguration/     Layered configuration persistence
    xWalkSettings/          Settings editor and numeric sliders
    xWalkNetwork/           NetworkManager Wi-Fi dialog
    xWalkKeyboard/          Android-style native touch keyboard and HUD dialog style
    xWalkConfig/            Versioned default configuration, build-mode template and editable help JSON
    xWalkResources/         HUD, boot and shutdown artwork, Pi 5 mesh and Qt resource manifest
    xWalkDeploy/            Desktop entry, user services, helper scripts and installation rules
    xWalkStub/              Standalone C++ service and Wi-Fi simulation and file-only trace stub
    xWalkTest/              Shared Google Test runner, process fixture and per-module test function
    build-standalone/       Generated standalone build tree (untracked)
    build-host/             Generated host build tree (untracked)
```

All modules belong to this one Git repository. Each code module has its own CMake target and `include`/`src`
folders; every module owns `test/src/<Module>GoogleTest.cpp`.

## 4. Child modules

| Note | Responsibility |
| --- | --- |
| [xWalk-rpi5-os CI](ci/xWalk-rpi5-os%20CI.md) | Standalone and host build, test and installation gates |
| [xWalkCli](xWalkCli/xWalkCli.md) | Same-user GUI/headless command transport |
| [xWalkConfig](xWalkConfig/xWalkConfig.md) | Versioned default configuration and help text |
| [xWalkConfiguration](xWalkConfiguration/xWalkConfiguration.md) | Layered configuration persistence |
| [xWalkDeploy](xWalkDeploy/xWalkDeploy.md) | Desktop entry, user services and installation rules |
| [xWalkDesktop](xWalkDesktop/xWalkDesktop.md) | HUD rendering, controls and telemetry |
| [xWalkKeyboard](xWalkKeyboard/xWalkKeyboard.md) | Android-style native touch keyboard and HUD style |
| [xWalkMain](xWalkMain/xWalkMain.md) | Native application entry point |
| [xWalkNetwork](xWalkNetwork/xWalkNetwork.md) | NetworkManager Wi-Fi interface |
| [xWalkResources](xWalkResources/xWalkResources.md) | HUD artwork, boot animation, mesh and resource manifest |
| [xWalkRuntime](xWalkRuntime/xWalkRuntime.md) | Controller and Traffic process lifecycle and telemetry |
| [xWalkSettings](xWalkSettings/xWalkSettings.md) | Settings editor and numeric sliders |
| [xWalkStub](xWalkStub/xWalkStub.md) | Standalone C++ service and Wi-Fi simulation |
| [xWalkTest](xWalkTest/xWalkTest.md) | Shared Google Test runner and harmless process fixtures |

The [CLI guide](CLI_GUIDE.md) is the complete command reference for every GUI-to-CLI equivalent.

## 5. Public interface

The executable `xwalk-pi5car` accepts `--gui [--fullscreen] [--config FILE]`, `--cli COMMAND`, `--attach`,
`--boot-readiness`, `--screenshot PNG`, `--trace SELECTOR`, `--build-mode` and `--help`. See
[xWalkMain](xWalkMain/xWalkMain.md) and the [CLI guide](CLI_GUIDE.md).

### Controls

- The artwork is the only main-screen control surface; there is no bottom rectangular toolbar.
- The artwork's FUNCTION KEYS panel heading is shown as **MENU**: the HUD covers the bitmap text and draws the
  title and chevron as vector text in the artwork's header colors.
- Active function keys glow purple while their owned process is starting or running; stopped or failed
  processes clear the glow. The glow (`XWalkFunctionGlow`) is a holographic wash that is brightest behind the icon
  and fades towards the chevron, with a fading halo, a lit edge and bar, and a slow 2.4 s breathing pulse. It
  redraws at 25 FPS only while a key is active and the HUD is visible.
- The official Pi 5 CAD mesh and reference-based HAT rotate and tilt through front, back, side and underside
  views at up to 30 FPS; labels remain stationary. Cached blue outlines omit coplanar mesh seams and keep a fixed
  scale throughout each revolution. Edges nearer the viewer are brighter than those behind, and edges shorter
  than about one device pixel are skipped, so the model reads as smooth shading on the 800 × 480 panel.
  Animation redraw pauses when the HUD is hidden or minimized. The native C++ renderer uses real 3D triangles.
  Model provenance and the retained MIT license are in `xWalkResources`.
- Tap Service, Vehicle, Vision, Voice, Traffic or All once to start it; tap the same active key again to stop.
  This is a start/stop toggle, not a timed double-click gesture.
- **All** starts Service, Vehicle, Vision and Voice through one Node Controller; **Traffic** remains separate.
  Vehicle, Service, Vision and Voice can be selected together; Traffic runs independently. Changing controller
  selection stops and restarts the sole hardware owner, interrupting its current operations; Traffic stays
  running. Use the matching Node revision with comma-separated `--function service,vehicle` support; older Node
  binaries cannot run combined selections.
- The red **Stop** key sends SIGTERM to the owned process groups, then SIGKILL after five seconds if needed.
  This is service shutdown, not a new proximity/AllStop command. External system services are not managed.
- The Settings key opens an Android tablet-style screen: a category rail on the left (Display, Network,
  Robot / Pi, Desktop, System) and the selected category's options on the right. Display has Fullscreen and
  Touch keyboard switches; Network opens Wi-Fi; Robot / Pi and Desktop open their configuration editors above
  Settings; System shows the build and Exit, plus Restart and Power off on the Pi build.
- Wi-Fi, settings, file selection, messages and event dialogs fill the available display, with a Close header
  and scrolling. Nested menus use the holographic `xWalkKeyboard/XWalkHudStyle` look described in
  [xWalkKeyboard](xWalkKeyboard/xWalkKeyboard.md). Primary actions (Connect, Scan, Save) are cyan; Exit and every
  Yes confirmation are orange. Dialogs fade in over 160 ms where the compositor supports window opacity.
- Tapping a text field opens the touch keyboard automatically; there is no Keyboard button. The keyboard stays
  above the dialog, which shrinks to keep its scrollable fields above the keyboard and expands again when the
  keyboard hides. **Settings → Display → Touch keyboard** switches it on or off.
- In Pi mode, power and restart require confirmation and use `systemctl` with the logged-in user's normal
  authorization. Stop the desktop's services first. The GUI does not grant privileges or change system policy.
- Tap the System Events / Errors panel to open the full-screen event console (`XWalkEventConsole`) with the last
  100 system failures, newest first. ERRORS, WARNINGS and TOTAL counters sit at the top; ALL / ERRORS / WARNINGS
  chips filter the list, and CLEAR (orange) clears the history in the console and on the dashboard. Each event
  is a holographic row with a glowing severity bar, time stamp, ERROR / WARNING / INFO tag and the full wrapped
  message; flick to scroll. Entries without a level tag are failures and count as errors. An empty history shows
  "ALL SYSTEMS NOMINAL". The dashboard panel's own CLEAR key still works. Process startup, crash and shutdown
  failures and desktop operation failures are reported directly; child log traces and rejection traces are not
  parsed or copied into this window.
- **F11** toggles fullscreen; **Ctrl+Q** exits through the same owned-service shutdown flow.

### Live data and limits

- CPU load and frequency come from `/proc/stat` and Linux CPU frequency sysfs (`cpufreq/scaling_cur_freq`).
- Temperature comes from `/sys/class/thermal/thermal_zone0/temp`.
- Wi-Fi link presence comes from cached `/sys/class/net/*/operstate` of wireless interfaces; it is not an
  Internet connectivity test.
- Camera frames come from the existing shared JPEG producer, never a second CSI camera owner. `auto` uses
  `XWALK_CAMERA_FRAME_FILE` or `$XDG_RUNTIME_DIR/xwalk-camera/frame.jpg`. Frames older than three seconds are
  hidden as stale. Configure and run the
  [shared camera service](../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md) separately.
- MQTT connectivity and rates, fan RPM and HAT probing are not instrumented by this desktop. They display
  unavailable or not monitored rather than the sample values in the artwork. Traffic's existing MQTT publisher
  runs when its process is started; the HUD does not add another publisher.

### Automatic monitoring

The tracked desktop profiles enable `automatic_monitoring`. On starting the runtime, the sole Node owner starts
with `--function monitor`: only health and sensor request topics are accepted, and Vehicle safety activity
remains false. Functional selections share this owner; deselecting Vehicle keeps monitoring. STOP still shuts
down every owned controller process and does not silently restart it. Existing saved desktop profiles need
`automatic_monitoring = true` appended to enable this behavior.

The runtime sends only health, battery, distance and grayscale reads in a bounded sequential cycle. Each request
has a 1.5 second reply timeout and a 2.5 second process deadline. Valid data expires after 15 seconds; failures
display unavailable. Battery percentage is the Controller's voltage-based estimate. Standalone uses explicit
simulated telemetry. No health/sensor action menu is needed.

Battery telemetry is requested immediately and then every ten seconds, with five-second retries while pending.
The controller samples voltage every five seconds and returns a rolling one-minute average from its first valid
sample. The displayed reading is retained until another valid average arrives; pending or failed requests do not
clear the previous value. Percentage is estimated from the averaged voltage using the configured endpoints.
Charging estimation is described in [xWalkRuntime](xWalkRuntime/xWalkRuntime.md).

During a proximity safety stop, the HUD continues receiving distance, battery and grayscale telemetry. A
measured front distance includes a `SAFETY STOP` indication while movement is blocked. Invalid echoes and stale
acquisitions remain explicitly unavailable rather than displaying a fabricated distance.

On Pi, the background runtime requests `systemctl --user start xwalk-camera.service`, then reads its fresh shared
JPEG at 10 FPS. Install the generated camera user unit from Node's `xWalkTrafCtrl/xWalkCameraSvc/build-rpi5`
after building that component, then run `systemctl --user daemon-reload`. Camera capture is independent of
Vehicle, Vision and Traffic selections. The camera unit remains shared when the desktop exits.

### Traffic detection preview

Starting Traffic Control enables trained-model detections in the live camera panel. Bounding boxes, class labels
and confidence percentages are drawn on the exact frame used by inference. The detector remains in the Traffic
process and shares the existing camera producer; the HUD does not open another camera.

- Box colors follow the trained forest's overall frame risk: green for SAFE (0), amber for MODERATE RISK (1) and
  red for HIGH RISK (2). A matching warning box below the video shows that model assessment.
- The risk is scene-wide, not a separate prediction for each object. Missing, invalid or stale results show
  RISK UNKNOWN while Traffic is active; stopping Traffic shows TRAFFIC DETECTION OFF, never SAFE.
- Stopping Traffic Control restores the raw live feed. While inference starts, fails or falls behind, the panel
  falls back to raw frames and says it is waiting for detections. Detection frames expire three seconds after
  capture, so old boxes are never drawn over a newer camera image.
- The runtime sets `XWALK_TRAFFIC_PREVIEW_FILE` to `<camera_frame>.traffic.jpg` for the Traffic child. The
  preview is replaced atomically, cleared at startup and removed on normal Traffic shutdown. Risk metadata is
  embedded in the JPEG comment, so the warning and image always come from the same inference.
- Detection update frequency follows the Traffic frame stride and inference speed, independently of HUD refresh.

### Detachable touchscreen

Install the independent runtime and HUD login service using
[xWalkDeploy](xWalkDeploy/xWalkDeploy.md#headless-field-operation). On Pi, the HUD is a reconnecting client.
Choose features on screen, disconnect the display, then reconnect it to view the same running features and
retained runtime errors. GUI or GNOME restarts do not change the runtime's selection. STOP and Play explicitly
stop and restart the selected work. At each new runtime start the default is monitoring only; driving commands
are never restored or replayed.

### Telemetry-driven boot readiness

`--boot-readiness` covers the running HUD with the original `xWalkResources/xwalk-boot-artwork.png` artwork and
five segments, clockwise from the top: runtime, hardware, battery, distance and grayscale. The artwork is an
unchanged copy of the supplied xWALK artwork, fitted without distortion. The overlay never sends commands to
actuators. It reveals the HUD after all checks pass, or after the configured deadline; the HUD continuously
displays the same authoritative verdict and failure reason. READY is shown briefly before handover only while
its evidence remains valid. Safety interlocks are unchanged.

`XWalkReadiness` in the telemetry owner is the sole readiness evaluator. Its JSON verdict is exposed under
`telemetry.readiness` in `--cli sensors` and `status`; both boot and attached HUD consume that verdict. All five
checks are required; none is silently optional. Grey means no evidence, cyan means a request was actually
dispatched or battery sampling explicitly reports pending, green means valid fresh evidence, amber means
unavailable, expired or timed out, and red means explicit failure or invalid data.

| Check | Evidence and validation |
| --- | --- |
| Runtime | Successful health confirmation with a boolean `healthy=true` |
| Hardware | Successful health confirmation with a boolean `ready=true` (Controller passive-ready/active state) |
| Battery | Voltage finite, 0 < V < 9.9; integer percentage 0–100; `battery_valid=true`; integer sample age ≥ 0 |
| Distance | Finite positive cm within the configured envelope; negative timeout/invalid-pulse and zero fail |
| Grayscale | Exactly three integer 12-bit ADC channels, each 0–4095; zero is valid |

Explicit sensor validity flags must be boolean true when present. The battery voltage envelope is the existing
Controller acquisition contract, not a new low-charge safety threshold. Percentage continues to use
`battery_empty_voltage` and `battery_full_voltage` from the robot configuration. The average may remain visible
after a failure, but its physical age and latest sampling outcome prevent a retained average from passing
readiness. Distance and grayscale confirmations follow actual sensor reads; their receive time is used as
freshness evidence. The local publisher request is bounded to 1500 ms (process deadline 2500 ms).

On the Pi, each Unix telemetry socket lifetime is identified by device, inode and nanosecond change time. The
identity is checked before dispatch, on completion and on every snapshot. A changed or missing socket, owner
restart or explicit monitoring restart invalidates readiness; cross-session replies are discarded. Host fixtures
use a new UUID per monitoring session. Retained battery display values never seed readiness.

### Shutdown display

The fullscreen `XWalkBootScreen` also presents the unmodified shutdown PNG from the Qt resource
`:/shutdown-artwork.png`. It aspect-fits on black, replaces unfinished startup checks and does not simulate
progress. Reboot has a separate `RESTARTING` band. A missing image falls back to plain text. Application power
requests paint before stopping owned processes; refused power commands restore the existing session workflow. A
timed-out power command leaves robot work stopped: terminating the client cannot cancel a shutdown already
accepted by the OS. Duplicate requests do not spawn another power command.

The Yocto image arms `xwalk-shutdown-screen.service` after `the per-user systemd manager`. Reverse shutdown ordering runs
its display-only notifier before stopping the user manager. The GUI observes `/run/xwalk/shutdown-mode` every
100 ms and acknowledges painting. The notifier waits at most 600 ms for this acknowledgement and has a
four-second systemd deadline; display failure cannot veto shutdown. The HUD stops after the headless runtime and
shared camera (reverse of its `Before=` ordering), preserving the screen during their cleanup. Qt is the only
display renderer in the Yocto image; no splash daemon takes KMS after Qt exits. Shutdown before Qt starts
proceeds without artwork; once Qt exits the display may go blank during final OS cleanup.

Existing Controller safe-stop, worker cancellation, state persistence and log draining remain in their owners.
Owned processes receive SIGTERM and escalate after five seconds; the headless and camera units retain 30-second
and ten-second stop limits. The power command itself has a five-second deadline. No animation or readiness check
delays shutdown, and no timer declares it safe to disconnect power. The artwork remains only while the display
stack is available. Physical KMS handoff continuity must be checked on the Pi; host screenshots cannot
establish the absence of a hardware mode-set blank.

## 6. Build

Requirements: a C++17 compiler, CMake 3.20 or newer, Qt 5.15 Widgets and Network development packages
(`qtbase5-dev`) and desktop platform plugins. Test builds also require Qt Test and Google Test
(`libgtest-dev`). No sibling repository is needed to configure or compile standalone; host and rpi5 builds
compose the trace backend from `../xWalk-rpi5-trace`. Run the GUI in a graphical desktop session as the regular
user.

From this directory, select exactly one profile:

```bash
./build.sh --standalone
./build.sh --host
./build.sh --rpi5
```

Add `--gui` to build, verify and then open the selected desktop:

```bash
./build.sh --standalone --gui
./build.sh --host --gui
./build.sh --rpi5 --gui
```

Use `./build.sh --rpi5 --gui --fullscreen` for fullscreen; `--fullscreen` is also accepted by the executable.
`./build.sh --help` describes the launcher without building. Use `./build.sh --standalone --cli serve` for a
headless owner, then send commands with `./build-standalone/xwalk-pi5car --cli status` from another terminal.
Host and Pi use the same command interface.

For an existing build, run `./build-host/xwalk-pi5car --gui` (or the standalone or rpi5 build directory). Host
and standalone open as normal resizable windows with native minimize, maximize and close controls. Their initial
size fits the available desktop area, including space for window decorations. Qt uses logical pixels for display
scaling, and the HUD keeps the artwork proportions when resized or maximized. Use `--gui --fullscreen` or F11 for
fullscreen; `--gui` alone opens a normal window on Pi too.

Each mode has its own CMake preset and build directory; reconfiguring a build directory with a different mode is
rejected. Equivalent manual commands for standalone are:

```bash
cmake --preset standalone
cmake --build --preset standalone
ctest --preset standalone
./build-standalone/xwalk-pi5car
```

Use `host` or `rpi5` instead for the other presets. Direct CMake users can set
`-DXWALK_OS_MODE=standalone|host|rpi5`. Standalone and host enable tests by default; pass `-DBUILD_TESTING=OFF`
when tests and Google Test are unnecessary.

Pi mode requires ARM64. Build natively on the Pi, or supply a matching ARM64 Qt toolchain. `build.sh --rpi5`
uses the adjacent repository's reviewed
`rpi-guarded-build.sh` and one build
job; set `XWALK_OS_BUILD_GUARD` to its installed path if needed. It refuses an absent guard. Pi preset tests are
off by default; the same hardware-free Google Tests can be enabled explicitly. No build or test starts real robot
processes or alters Wi-Fi.

Optional installation:

```bash
sudo cmake --install build-rpi5
```

Installation adds a desktop-menu entry; it does not enable autostart, change Wi-Fi or start robot processes. Use
the desktop environment's normal startup-applications settings to start `xwalk-pi5car --fullscreen` at login.

### C++ editor setup

`XWalkBuildMode.h` is generated by CMake under `build-<mode>/generated/include`; do not copy or hand-edit it.
Configure once to generate this header and the compiler database (including Qt and each module's includes):

```bash
cmake --preset standalone
cmake --preset host
```

On the Pi use `cmake --preset rpi5`. In VS Code, select the matching C/C++ configuration (`standalone`, `host` or
`rpi5`) when opening this repository directly. The **xWalk OS: Configure** tasks generate each profile; CMake
Tools also supports selecting these presets. Pi configuration requires native ARM64 Qt. The parent and integrated
workspaces use the host profile via **xWalk: Configure desktop navigation**, also included in
**xWalk: Refresh all C++ navigation**. Generated headers and compiler databases stay untracked. If an old include
diagnostic remains after configuring, run **C/C++: Reset IntelliSense Database** and **Developer: Reload Window**.
The compiler database, rather than a recursive workspace include search, provides the authoritative include paths
and build-mode definitions.

## 7. Configuration

| CMake variable | Default | Meaning |
| --- | --- | --- |
| `XWALK_OS_MODE` | `standalone` | `standalone`, `host` or `rpi5`; `rpi5` needs an aarch64/arm64 compiler |
| `XWALK_OS_INTEGRATION_ROOT` | parent directory | `xWalkPiCarAI` checkout for path defaults and trace backend |
| `BUILD_TESTING` | `ON`; `OFF` in the rpi5 preset | Builds per-module Google Test executables |

Host defaults point at the adjacent Node `build-host/cmake/xwalk` and Traffic
`xWalkTrafCtrl/build-host/xWalkTrafCtrl`. Build those repositories separately before starting real services.
Set Desktop paths for other layouts, or
configure `-DXWALK_OS_INTEGRATION_ROOT=/path/to/xWalkPiCarAI` to generate different defaults. The GUI builds
independently of these runtime executables.

First launch copies the mode-specific embedded `desktop.cfg` into the user's Qt configuration directory, normally
`~/.config/xWalk/xwalk-desktop/<mode>/desktop.cfg`. The directory keeps the earlier `xwalk-desktop` name so
existing settings remain in use. The three profiles stay separate. Defaults are tracked in
`xWalkConfig/desktop-<mode>.cfg.in`; existing user files are never replaced. Standalone also seeds a local demo
`robot.cfg`. Relative paths resolve beside the chosen desktop profile. Use `--config /path/to/desktop.cfg` for an
explicit deployment profile.

Open **Settings → Desktop → Edit** to set these paths before starting services:

| Key | Purpose |
| --- | --- |
| `node_launcher` | Executable `runtime/run-xwalk` or a compatible full Node binary |
| `traffic_binary` | Built `xWalkTrafCtrl` executable; exported as `XWALK_TRAFFIC_BINARY` |
| `robot_config` | Existing Robot HAT/Pi configuration; exported as `XWALK_PICARX_CONFIG_FILE` |
| `config_directory` | Starting directory when browsing all `.cfg` / `.conf` files |
| `camera_frame` | Shared JPEG path, or `auto` for the existing shared-camera user service |
| `touch_keyboard` | `true` for touch entry, `false` for a physical keyboard |
| `automatic_monitoring` | `true` starts read-only health and sensor polling |

| Readiness key | Default | Meaning |
| --- | ---: | --- |
| `readiness_startup_timeout_ms` | 45000 | Maximum Qt boot-overlay wait; timeout reveals a Not ready HUD |
| `readiness_fresh_ms` | 15000 | Maximum health/distance/grayscale receive age |
| `readiness_battery_fresh_ms` | 30000 | Maximum battery receive age and physical sample age plus receive age |
| `readiness_distance_max_cm` | 1000 | Existing telemetry envelope limit; configurable for the installed sensor |

Positive freshness values and timeouts are limited to one hour; malformed settings fail readiness closed. There is
no inferred minimum battery percentage or undocumented optional sensor configuration.

**Settings → Robot / Pi → Edit** initially opens `robot_config`. **Open .cfg / .conf** can select any readable
configuration file under any directory. The editor handles the existing flat `key = value` format with relative
`include` files. Included values appear together; later definitions win. Numeric scalar fields have
synchronized sliders and number entry. Booleans have checkboxes. Strings, arrays and provider-specific values
retain text entry. Fields can be filtered by name. Secret-named fields are masked.

Saving appends only changed effective values to the selected file, preserving existing comments, includes and
calibration. It never rewrites included files. Every changed save creates a timestamped `.bak-*` copy and then
atomically replaces the selected file, preserving permissions. Changes to any included file since opening
prevent saving until the editor is reopened. Include cycles and files over 1 MiB are rejected. Choose an
operator-writable runtime file; the GUI does not elevate privileges to edit protected system files. Do not commit
live credentials, account stores or private deployment overrides.

Stop owned services before opening settings, and close settings before starting them again. Configuration is not
hot-applied. Field ranges are editing aids; the owning runtime remains responsible for semantic validation and
hardware-specific limits. Confirm wiring and calibration before applying a new profile.

### Wi-Fi

**Wi-Fi → select a detected network → enter password → Connect** uses NetworkManager in host and Pi builds
(`network-manager` / `nmcli` required). Standalone labels the dialog SIMULATED and uses two demo networks without
changing operating-system settings. The request is asynchronous, bounded to 35 seconds, and reports errors
without freezing the HUD. SSID arguments are passed directly without a shell. Passwords go over the subprocess's
standard input; they are not placed in command arguments or the desktop configuration and are cleared after the
request. Opening Wi-Fi scans automatically; **Scan networks** refreshes the list. Selecting a secured network
opens a masked password field with **Show password**, **Cancel** and **Connect**. Open networks ask for
connection confirmation without a password. Cancelling clears the password and dismisses the virtual keyboard.
The menu shows a short status message rather than command output or a log pane. Hidden networks remain available
through the CLI (`--hidden`) or the OS network editor. NetworkManager stores successful connection profiles
according to the OS's policy. Enterprise authentication and unsupported profiles can be configured with the OS's
network editor.

### OS diagnostics

Use the `OS` trace tag to enable lifecycle information:

```bash
./build-host/xwalk-pi5car --gui --trace OS.enable
./build-standalone/xwalk-pi5car --cli serve --trace OS.enable
```

Warnings and errors remain enabled independently. Records go to `<build>/log/xWalkTrace.log`, with no trace text
added to CLI JSON responses or the GUI error window. See
[trace IDs and backend details](../../07-xwalk-trace/xWalk-rpi5-trace/docs/OS_TRACES.md).

## 8. Testing

Every module has its own `<Module>GoogleTest` executable and `test/src` source, registered through
`xwalk_os_add_test` in [xWalkTest](xWalkTest/xWalkTest.md). Google Test supplies assertions and reporting; Qt Test
supplies GUI input simulation. Data, resource and deployment folders also have independent contract suites. Each
discovered test carries its module name as CTest label and a 30-second timeout.

```bash
ctest --test-dir build-standalone --output-on-failure
ctest --test-dir build-host -L xWalkKeyboard --output-on-failure
./build-host/xWalkRuntimeGoogleTest --gtest_filter="*BackendSelection"
```

Tests cover include precedence, preserved comments, backups, concurrent edits, cycle rejection, numeric sliders,
touch text entry, escaped SSIDs, stdin credential handling, mutually exclusive Controller processes, independent
Traffic shutdown, idle startup and correct HUD scaling. The Wi-Fi and process tests use a C++ fixture; they never
change host networking or access robot hardware.

Render a preview without starting robot processes:

```bash
QT_QPA_PLATFORM=offscreen ./build-host/xwalk-pi5car --config build-host/generated/desktop.cfg --screenshot build-host/desktop.png
```

The opt-in `xWalkDesktop.OptInLiveTelemetryRetention` test is labelled `hardware`; list it with
`ctest -N -L hardware`. Run it only with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.
It renders the real HUD, selects Service and Vehicle together, waits for the rolling battery average, and checks
valid readings through live refreshes. It then verifies retention across Stop and recovery after Play without
requiring voltage to remain constant. It sends no movement command. Stop the background runtime and any owning HUD
first to avoid a second hardware owner, and restore the runtime afterward; closing an attached HUD alone does not
stop its owner. Set `XWALK_OS_LIVE_TEST_CONFIG` to the preserved live desktop configuration when invoking the
test executable; without that variable the test is skipped. CTest allows 240 seconds for live acquisition and
recovery. `XWALK_OS_LIVE_START_ONLY=1` limits it to bounded startup checks.

Physical touchscreen input, real NetworkManager authentication, CSI frames and Pi hardware operation still require
deployment verification. Continuous integration is described in [xWalk-rpi5-os CI](ci/xWalk-rpi5-os%20CI.md).

## 9. Dependencies

- Qt 5.15 Widgets, Network and (for tests) Test; Google Test (`GTest::gtest`) for tests.
- `xWalk-rpi5-trace` for the `xWalkOsTrace` backend in host and rpi5 modes; standalone uses the stub in
  `xWalkStub`.
- At runtime: the Node Controller (`run-xwalk`), `xWalkTrafCtrl`, the shared camera user service, NetworkManager
  and, on Pi, `systemctl` for power actions.

## 10. Safety and constraints

- Standalone cannot start real robot processes; configured executable paths are ignored.
- Monitoring is read-only; the HUD never sends motor commands, and driving commands are never replayed.
- Only one process owner exists per profile, guarded by the instance lock; CLI clients never start a second
  Controller.
- Power and restart require confirmation, are available only in the rpi5 build and use normal user
  authorization.
- Hardware tests are opt-in and never run in CI.

## 11. Related notes

- [CLI guide](CLI_GUIDE.md)
- [xWalk-rpi5-trace](../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- [xWalk-rpi5-node](../../05-xwalk-node/xWalk-rpi5-node/xWalk-rpi5-node.md)
- [xWalkCameraSvc](../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md)
- [Deployment Tool](../../06-xwalk-tool/xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md)

---

[Previous page](../index.md) · [Chapter index](../index.md) · [Next page](ci/xWalk-rpi5-os%20CI.md)
