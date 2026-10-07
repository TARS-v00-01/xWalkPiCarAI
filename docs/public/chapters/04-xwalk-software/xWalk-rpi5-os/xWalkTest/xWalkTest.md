<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkTest

**4. xWalk software &middot; Module 18**

<!-- xwalk-page-header:end -->

# xWalkTest

`xWalkTest` provides the shared Google Test main, the harmless C++ process and NetworkManager fixture, and the
`xwalk_os_add_test` CMake function that gives every desktop module its own test executable and CTest label.

## 1. Overview

- Each module owns its `test/src/<Module>GoogleTest.cpp`, executable and CTest label. Google Test supplies
  assertions and reporting; Qt Test drives GUI events only.
- Default tests use harmless fixtures and do not command real actuators or change networking. Standalone exercises
  the bundled stubs; host tests substitute the local fixture for external executables. The separately opted-in
  live desktop check uses the configured Pi controller for stationary telemetry and camera verification.
- The shared test runner defaults to `QT_QPA_PLATFORM=offscreen` only when no backend is supplied. Set
  `QT_QPA_PLATFORM=xcb`, `DISPLAY` and the session's `XAUTHORITY` to exercise visible windows on the Pi
  touchscreen.
- Desktop artwork checks cover all six function keys, repeat-click deselection, Stop, fullscreen, error clearing,
  Wi-Fi, settings and events dialogs and symbol keyboard input. On the Pi build, power and restart prompts are
  cancelled; the tests never confirm an OS shutdown or restart.
- `xWalkProcessFixture` is a long-running process that never connects to MQTT or hardware. It imitates `nmcli`
  scan and connect output, Node `publish` replies (optionally gated by `XWALK_TEST_TELEMETRY_READY_FILE`) and a
  host service that echoes its arguments and `XWALK_TRAFFIC_PREVIEW_FILE`. `XWALK_TEST_IGNORE_TERM` makes it
  ignore SIGTERM to test forced cleanup.

## 2. Source location

`xWalk-rpi5-os/xWalkTest` - source directory

## 3. Directory layout

```text
xWalkTest/
    CMakeLists.txt                       xWalkProcessFixture, xwalk_os_add_test and the module's own test
    src/XWalkGoogleTestMain.cpp          Shared QApplication and Google Test main
    src/XWalkProcessFixture.cpp          Harmless process, nmcli and publisher fixture
    test/src/xWalkTestGoogleTest.cpp     Fixture lifetime test
```

## 4. Public interface

`xwalk_os_add_test(<module> <libraries...>)` builds `<module>GoogleTest` from
`<module>/test/src/<module>GoogleTest.cpp`, the shared main and the generated resources. It adds
`<module>/test/include` and `xWalkTest/include` to the include path, links `xWalkOsBuild`, `GTest::gtest`,
`Qt5::Test` and `Qt5::Widgets`, and defines `XWALK_OS_SOURCE_DIR`. `xWalkRuntime`, `xWalkNetwork` and
`xWalkDesktop` tests depend on `xWalkProcessFixture` and `xwalk-os-stub`. Tests are discovered with
`gtest_discover_tests` (`DISCOVERY_MODE PRE_TEST`), prefixed `<module>.`, labelled `<module>` and limited to 30
seconds each.

## 5. Build

Built from the [desktop root](../xWalk-rpi5-os.md) when `BUILD_TESTING` is on (default in the standalone and host
presets).

## 6. Testing

```bash
ctest --test-dir build-standalone --output-on-failure
ctest --test-dir build-standalone -L xWalkTest --output-on-failure
ctest --test-dir build-host -N -L hardware
```

The only hardware-labelled test is `xWalkDesktop.xWalkDesktop.OptInLiveTelemetryRetention` (labels
`xWalkDesktop;hardware`, 240-second timeout, skipped unless `XWALK_OS_LIVE_TEST_CONFIG` is set). It is excluded
from ordinary discovery. Run it only with explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 7. Safety and constraints

- Fixtures never connect to MQTT, robot hardware or the host's NetworkManager.
- CI unsets the live-test variables, so physical-device tests never run there.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalk-rpi5-os CI](../ci/xWalk-rpi5-os%20CI.md)
- [xWalkStub](../xWalkStub/xWalkStub.md)

---

[Previous page](../xWalkStub/xWalkStub.md) · [Chapter index](../../index.md) · [Next page](../CLI_GUIDE.md)
