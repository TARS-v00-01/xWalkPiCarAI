<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkNetwork

**4. xWalk software &middot; Module 13**

<!-- xwalk-page-header:end -->

# xWalkNetwork

`xWalkNetwork` provides the asynchronous Wi-Fi configuration dialog through NetworkManager and the cached
wireless-link check used by the HUD status indicator.

## 1. Overview

- Host and Pi builds use NetworkManager's `nmcli` (`network-manager` package required). Without `nmcli` the
  dialog reports that NetworkManager must be installed. Standalone labels the dialog SIMULATED and uses the
  `xwalk-os-stub` Wi-Fi simulation with two demo networks, without changing operating-system settings.
- Each `nmcli` request is asynchronous, bounded to 35 seconds, and reports errors without freezing the HUD.
- SSID arguments are passed directly without a shell. Passwords go over the subprocess's standard input; they are
  not placed in command arguments or the desktop configuration and are cleared after the request, on cancel and
  on destruction.
- Opening Wi-Fi scans automatically; **Scan networks** refreshes the list. Selecting a secured network opens a
  masked password field with **Show password**, **Cancel** and **Connect**. Open networks ask for connection
  confirmation without a password.
- The menu shows a short status message rather than command output or a log pane. Hidden networks remain
  available through the CLI (`--hidden`) or the OS network editor.
- The link indicator reads cached `/sys/class/net/*/operstate` for wireless interfaces. It does not poll
  `/proc/net/wireless`, whose legacy statistics path can issue firmware queries on every display refresh.

## 2. Source location

`xWalk-rpi5-os/xWalkNetwork` - source directory

## 3. Directory layout

```text
xWalkNetwork/
    CMakeLists.txt                         Static library xWalkOsNetwork and its Google Test
    include/XWalkWifi.h                    Wi-Fi dialog, nmcli field decoding and link check
    src/XWalkWifi.cpp                      Scan, join, deadline and credential handling
    test/src/xWalkNetworkGoogleTest.cpp    Escaped SSID, cached link state and connection tests
```

## 4. Public interface

`xwalk::hal::XWalkWifi` (`QDialog`):

- `explicit XWalkWifi(QWidget* parent = nullptr)`; the destructor stops pending `nmcli` work and clears the
  in-memory credential buffer.
- `static QStringList splitEscaped(const QString& line)` decodes `nmcli` colon-separated fields with backslash
  escapes.
- `static bool hasWirelessLink(const QString& networkRoot = "/sys/class/net")` reads cached kernel link state
  without querying wireless firmware.

## 5. Build

CMake target `xWalkOsNetwork` (static, C++17) links `Qt5::Widgets`, `xWalkOsBuild` and `xWalkOsTrace`, and
compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through the
[desktop root](../xWalk-rpi5-os.md) to compose its dependencies.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkNetwork --output-on-failure
```

`EscapedNetworkNames`, `CachedWirelessLinkState` and `WifiConnection` use the C++ process fixture and a temporary
sysfs-like tree; they never change host networking.

## 7. Dependencies

Qt 5 Widgets, `xWalkOsTrace`, and at runtime NetworkManager (`nmcli`) on host and Pi.

## 8. Safety and constraints

- NetworkManager stores successful connection profiles according to the OS's policy.
- Enterprise authentication and unsupported profiles are configured with the OS's network editor.
- Wi-Fi power-saving guidance is in [xWalkDeploy](../xWalkDeploy/xWalkDeploy.md#wi-fi-power-saving).

## 9. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkStub](../xWalkStub/xWalkStub.md)

---

[Previous page](../xWalkMain/xWalkMain.md) · [Chapter index](../../index.md) · [Next page](../xWalkResources/xWalkResources.md)
