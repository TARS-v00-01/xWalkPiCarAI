<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkMain

**4. xWalk software &middot; Module 12**

<!-- xwalk-page-header:end -->

# xWalkMain

`xWalkMain` is the application entry point of `xwalk-pi5car`. It composes the desktop, keyboard and CLI modules,
parses command-line options, wires keyboard shortcuts and provides the host preview entry point.

## 1. Overview

- `--gui [--fullscreen]` starts the visible owner. `--cli serve` starts the same runtime without a display; other
  `--cli` commands contact the existing GUI or headless owner through `xWalkCli`. Both interfaces share the
  mode-specific instance lock `$XDG_RUNTIME_DIR/xwalk-desktop-<mode>.lock`.
- In the rpi5 build, or with `--attach`, the GUI attaches to the background runtime as a client instead of
  owning processes; on the Pi it first requests `systemctl --user start xwalk-pi5car-headless.service`, which
  does not restart an active service or alter its selected features. A second headless owner exits with status 2.
- CLI clients never seed or modify configuration during startup. Without `--config`, the GUI and headless owner
  use `~/.config/xWalk/xwalk-desktop/<mode>/desktop.cfg`; the directory keeps the earlier `xwalk-desktop` name
  across the executable rename. Standalone also seeds a demo `robot.cfg` when absent.
- SIGINT and SIGTERM are handled by the headless event loop, which stops owned processes before exiting.
- `--help` / `-h` prints the editable help JSON: `XWALK_OS_HELP_FILE` when set, otherwise
  `config/xWalkOsHelp.json` beside the executable, `../share/xwalk-pi5car/xWalkOsHelp.json`, then the installed
  path. Help files above 64 KiB or without a non-empty `help` string array are rejected. Help needs no display,
  process owner or configuration writes.

## 2. Source location

`xWalk-rpi5-os/xWalkMain` - source directory

## 3. Directory layout

```text
xWalkMain/
    CMakeLists.txt                     Executable xwalk-pi5car, help JSON copy and its Google Test
    main.cpp                           Option parsing, instance lock, GUI/CLI/headless composition
    test/src/xWalkMainGoogleTest.cpp   Executable-level tests using the built binary
```

## 4. Public interface

| Option | Meaning |
| --- | --- |
| `--gui` | Open the HUD for the compiled backend (default without `--cli`) |
| `--fullscreen` | Fill the touchscreen |
| `--config FILE` | Use an explicit desktop configuration |
| `--attach` | Attach the HUD to the background runtime without owning processes |
| `--boot-readiness` | Show telemetry readiness before revealing the HUD |
| `--screenshot PNG` | Render a host preview and exit without starting services |
| `--capture-live PNG` | Save the running HUD after 15 seconds with its normal monitoring policy |
| `--cli COMMAND ...` | Run a CLI command; `serve` starts a headless owner |
| `--confirm` | Explicitly confirm a CLI power action |
| `--password-stdin` | Read a Wi-Fi password line from stdin; never put passwords in argv |
| `--hidden` | Connect to a hidden Wi-Fi network |
| `--trace SELECTOR` | Apply a trace selector (repeatable), for example `OS.enable` |
| `--build-mode` | Print the compiled backend and exit |
| `-h`, `--help` | Print help and exit |

CLI commands: `serve`, `status`, `start`/`stop GROUPS`, `session stop|start`, `traffic video FILE|default`,
`health`, `sensors`, `battery`, `events list|clear`, `config list|get|set`, `wifi on|off|scan|connect`,
`camera status|snapshot`, `window ...`, `keyboard on|off`, `power off|reboot` and `quit`. See the
[CLI guide](../CLI_GUIDE.md) for the complete command reference.

## 5. Build

CMake target `xwalk-pi5car` links `xWalkOsDesktop`, `xWalkOsKeyboard` and `xWalkOsCli`, embeds the generated Qt
resources and is installed to `bin`. `XWALK_OS_INSTALLED_HELP` is compiled as
`<datadir>/xwalk-pi5car/xWalkOsHelp.json`. In standalone mode the executable depends on `xwalk-os-stub`. Build
through the [desktop root](../xWalk-rpi5-os.md).

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkMain --output-on-failure
```

Tests cover the retained default configuration after the rename, help JSON edits without rebuilding or opening
the GUI, compiled-mode reporting without services, rejection of unknown arguments, GUI rendering without
services, and a headless CLI owner that owns one session and retains configuration.

## 7. Safety and constraints

- Exactly one process owner per profile; attaching clients never own processes.
- Passwords are accepted only through `--password-stdin`, never on the command line.
- Power actions require `--confirm` and are available only in the rpi5 build.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkCli](../xWalkCli/xWalkCli.md)
- [CLI guide](../CLI_GUIDE.md)

---

[Previous page](../xWalkKeyboard/xWalkKeyboard.md) · [Chapter index](../../index.md) · [Next page](../xWalkNetwork/xWalkNetwork.md)
