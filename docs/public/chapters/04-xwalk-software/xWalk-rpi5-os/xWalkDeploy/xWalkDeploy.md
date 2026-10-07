<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkDeploy

**4. xWalk software &middot; Module 06**

<!-- xwalk-page-header:end -->

# xWalkDeploy

`xWalkDeploy` holds the desktop-menu integration, installation rules, optional systemd user services, helper
scripts and deployment workarounds for the Pi desktop. Installation does not enable automatic hardware startup.

## 1. Overview

- `cmake --install` places the `xwalk-pi5car.desktop` menu entry, the generated `desktop.cfg`, the demo
  `robot.cfg`, `xWalkOsHelp.json`, `PI5_MODEL_LICENSE.txt` and `MODEL_SOURCES.md` under `share`; the
  `xwalk-headless-start` and `xwalk-hud-session` helpers under `bin`; and the service units,
  `headless.env.example`, `xwalk-hud-autostart.desktop`, `zz-xwalk-wifi-powersave-off.conf` and
  `pemmican-reset-service.conf` under
  `share/xwalk-pi5car/deploy`. Standalone also installs `xwalk-os-stub`.
- The menu entry runs `xwalk-pi5car --gui --fullscreen`. Installing it does not enable autostart, change Wi-Fi or
  start robot processes.
- Additional deployment guides: USB networking for a direct Pi connection and Internet sharing
  through the host, [GNOME login keyboard](GNOME_KEYBOARD.md) for the small-display login keyboard
  (`gnome-small-screen-keyboard.sh`), and touch-console login for the optional
  `gdm-autologin.conf.example`.

### Stable MQTT subscriber identity

For a Pi with both USB and Wi-Fi, give the HUD a stable MQTT subscriber identity using `XWALK_SERVER_IP`. The
HUD's child subscribers and telemetry publishers inherit the same value. Changing network interfaces then does not
change the address used by its health requests. Keep clients' paired subscriber address consistent with this
value. Android Live Video can independently use the Pi's Wi-Fi address through `ssh_host`, port `22`; leave
`ssh_host` empty when pairing already uses Wi-Fi. The optional USB camera bridge does not alter Wi-Fi settings or
the Pi camera server.

```bash
XWALK_SERVER_IP=192.0.2.10 xwalk-pi5car --gui --fullscreen --config /path/to/desktop-live.cfg
```

A desktop shortcut may use the same command with `env XWALK_SERVER_IP=192.0.2.10` and the absolute installed
binary and configuration paths. Keep those device-specific paths in the local shortcut; the packaged template
opens the GUI using the normal installed defaults.

## 2. Source location

`xWalk-rpi5-os/xWalkDeploy` - source directory

## 3. Directory layout

```text
xWalkDeploy/
    CMakeLists.txt                       Installation rules and the module's Google Test
    xwalk-pi5car.desktop                 Desktop-menu entry (GUI only)
    xwalk-pi5car-headless.service        User service running the headless owner (--cli serve)
    xwalk-headless-start                 ExecStartPost helper applying the configured function selection
    headless.env.example                 Sanitized environment template for the headless service
    xwalk-pi5car-hud.service             User service running the attached fullscreen HUD client
    xwalk-hud-session                    Login helper importing the display session and restarting the HUD
    xwalk-hud-autostart.desktop          GNOME autostart entry calling xwalk-hud-session
    zz-xwalk-wifi-powersave-off.conf     NetworkManager default wifi.powersave=2
    pemmican-reset-service.conf          Optional Type=exec drop-in for pemmican-reset.service
    usb-network-pi.sh                    USB Ethernet setup (see USB networking note)
    gnome-small-screen-keyboard.sh       GNOME 46 small-screen login keyboard workaround
    gdm-autologin.conf.example           Optional GDM automatic-login keys
    test/src/xWalkDeployGoogleTest.cpp   Desktop entry, headless helper and login helper contracts
```

## 4. Configuration

### Headless field operation

The independent `--cli serve` runtime uses Qt offscreen and survives display removal, GNOME failure and desktop
logout. On Pi, `--gui` attaches to this runtime automatically. Closing the HUD never stops its processes.
Reopening the HUD reads the current selections, telemetry and retained errors; it does not replay commands. STOP
stops the selected work, and Play starts the saved selection from the beginning.

The optional user service expects the Pi executable at `~/.local/bin/xwalk-pi5car` and the normal saved
`~/.config/xWalk/xwalk-desktop/rpi5/desktop.cfg`. Install the shipped helper and service explicitly:

```bash
install -Dm755 xWalkDeploy/xwalk-headless-start ~/.local/bin/xwalk-headless-start
install -Dm644 xWalkDeploy/xwalk-pi5car-headless.service ~/.config/systemd/user/xwalk-pi5car-headless.service
```

Create `~/.config/xWalk/xwalk-desktop/rpi5/headless.env` from `headless.env.example` only if it is absent;
preserve an existing file and keep it private. Set `XWALK_HEADLESS_FUNCTIONS=service,vehicle,vision,traffic` only
when those hardware functions are required and the hardware is ready. The default is `monitor`; accepted groups
are `monitor`, `service`, `vehicle`, `vision`, `voice`, `traffic` and `all`. `all` still excludes Traffic; select
`traffic` explicitly. Set `XWALK_SERVER_IP` to the address used by paired clients when required. Never put
credentials in this environment file.

Enable lingering once so the user manager survives logout, then enable the service for future boots:

```bash
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable xwalk-pi5car-headless.service
```

Install the HUD client service and login helper, then add its desktop entry to this user's autostart:

```bash
install -Dm755 xWalkDeploy/xwalk-hud-session ~/.local/bin/xwalk-hud-session
install -Dm644 xWalkDeploy/xwalk-pi5car-hud.service ~/.config/systemd/user/xwalk-pi5car-hud.service
install -Dm644 xWalkDeploy/xwalk-hud-autostart.desktop ~/.config/autostart/xwalk-hud-autostart.desktop
systemctl --user daemon-reload
systemctl --user start xwalk-pi5car-headless.service
~/.local/bin/xwalk-hud-session
```

Run the last command inside the Pi desktop session. The autostart helper imports that session's display
connection and recreates only the HUD. The HUD unit runs `xwalk-pi5car --gui --attach --fullscreen` and selects
Qt's `xcb` backend through XWayland to avoid the native Qt 5 Wayland hotplug crashes observed on this Pi. GNOME
itself can remain on Wayland. The runtime is not part of `graphical-session.target` and keeps running when the
desktop disappears. Leave `XWALK_HEADLESS_FUNCTIONS=monitor` to select functions on screen after each boot;
selection survives HUD reconnection, but is not replayed across a runtime restart.

No manual GUI/headless handover is required when unplugging the touchscreen. The HUD itself stays alive during
normal screen removal. Display changes are coalesced before restoring fullscreen at the returning screen's actual
desktop coordinates; the original screen is preferred when it is available again. This does not recreate the HUD
or its runtime connection. A desktop crash is a separate failure: recovery then necessarily creates a new HUD
client while the background runtime remains alive.

The service restores only the configured functional selection after a failure; it never replays a drive or
autonomous-mode request. Its startup helper verifies that the instance lock belongs to the service's PID before
sending any function-selection command. `session stop` remains stopped until Play or an explicit service restart;
changing `headless.env` takes effect on the next service start. When Traffic is selected, startup waits up to 30
seconds for NetworkManager connectivity (`nm-online`, when installed) and, when `XWALK_CAMERA_FRAME_FILE` is set,
for the first nonempty shared frame. Failed readiness stops startup and uses the service's bounded restart policy
(`Restart=on-failure`, three starts per 120 seconds, no restart on exit status 2).

The separately installed `xwalk-camera.service` remains the single camera producer. A disconnected HUD shows
reconnecting or unknown state and disables commands. Reads reconnect automatically; a command whose reply is lost
is reported as uncertain and is never retried automatically. Error history is bounded and survives HUD restarts,
but not a runtime restart. Inspect runtime failures with:

```bash
journalctl --user -u xwalk-pi5car-headless.service -u xwalk-pi5car-hud.service -b
```

GNOME must be running to show the HUD when the screen returns. If it was manually stopped for testing, start it
with `sudo systemctl start gdm`. This design isolates robot operation from a GNOME crash; it does not fix GNOME
itself or guarantee display hotplug behavior on every touchscreen.

### Wi-Fi power saving

The HUD link indicator reads cached `/sys/class/net/*/operstate` for wireless interfaces. It does not poll
`/proc/net/wireless`, whose legacy statistics path can issue firmware queries on every display refresh. Scanning
and joining remain explicit NetworkManager operations in the Wi-Fi dialog.

On a Pi that reports Wi-Fi firmware query timeouts, inspect the effective policy using
`NetworkManager --print-config`. A local `wifi.powersave=3` can override the Raspberry Pi package default. The
supplied `zz-xwalk-wifi-powersave-off.conf` sets the NetworkManager default to `2` (disabled):

```bash
sudo install -m644 xWalkDeploy/zz-xwalk-wifi-powersave-off.conf /etc/NetworkManager/conf.d/zz-xwalk-wifi-powersave-off.conf
sudo nmcli general reload conf
```

Explicit per-connection settings take priority. Set the chosen profile's `802-11-wireless.powersave` to `2` and
reconnect it during a maintenance window; reconnection can interrupt SSH and video briefly. Preserve SSID,
authentication, IP, DNS, routing and unrelated profiles. This mitigates power-save latency; it does not repair
undervoltage or prove the cause of every firmware timeout. Verify kernel logs and actual packet delivery under the
intended camera/MQTT load after applying it.

### Desktop waiting for a power notification

Some Raspberry Pi images ship `pemmican-reset.service` as `Type=oneshot`. If its interactive power notification
remains open with the display disconnected, `graphical-session.target` and login autostart can wait indefinitely.
Inspect `systemctl --user list-jobs` before applying this optional drop-in:

```bash
install -Dm644 xWalkDeploy/pemmican-reset-service.conf ~/.config/systemd/user/pemmican-reset.service.d/xwalk.conf
systemctl --user daemon-reload
systemctl --user restart pemmican-reset.service
```

The drop-in changes readiness to `Type=exec`; it does not disable the power notification, alter its thresholds or
suppress undervoltage reporting. The desktop may finish starting while the notification is visible. Install it
only on systems with the corresponding distribution service.

## 5. Testing

```bash
ctest --test-dir build-standalone -L xWalkDeploy --output-on-failure
```

Tests verify that the desktop entry starts only the GUI, that the headless helper rejects invalid selections and
foreign lock owners, that desktop restarts never stop the background runtime, and that the login helper starts an
unloaded HUD without touching the runtime. They use fake `systemctl` and executables; nothing is installed.

## 6. Safety and constraints

- Hardware functions start only when explicitly listed in `headless.env`; the default is read-only `monitor`.
- Drive and autonomous-mode requests are never replayed after a restart.
- Both services use `UMask=0077`. Keep `headless.env` private and free of credentials; preserve existing local
  overrides during cleanup or reinstallation.
- Automatic login is an operator choice that permits physical access without a password; it is never enabled by
  the application or CMake install.

## 7. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- USB networking
- [GNOME login keyboard](GNOME_KEYBOARD.md)
- Touch-console login
- [xWalkCameraSvc](../../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md)

---

[Previous page](../xWalkConfiguration/xWalkConfiguration.md) · [Chapter index](../../index.md) · [Next page](GNOME_KEYBOARD.md)

> `192.0.2.10` is a documentation-only example address; select your own authorized target.
