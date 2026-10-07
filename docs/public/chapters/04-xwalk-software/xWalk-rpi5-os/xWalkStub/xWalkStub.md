<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkStub

**4. xWalk software &middot; Module 17**

<!-- xwalk-page-header:end -->

# xWalkStub

`xWalkStub` provides the hardware-free C++ service and Wi-Fi simulator used by standalone builds and tests, and
the file-only trace adapter that replaces the shared trace backend in the standalone profile.

## 1. Overview

- `xwalk-os-stub` performs no hardware, MQTT or NetworkManager access. `--describe` states this and exits.
- Each simulated function (Service, Vehicle, Vision, Voice, Traffic and All) emits a readiness line and a
  one-second heartbeat log; SIGTERM and SIGINT stop its event loop. Unknown functions are rejected.
- `--wifi` serves one fake Wi-Fi request: it returns demo networks and consumes credentials without saving them.
- The executable is built beside the GUI whenever the profile is standalone or tests are enabled, and is
  installed with standalone only. Standalone ignores configured executable paths and always runs this stub.
- In standalone, `XWalkOsTrace` substitutes the shared trace adapter with a file-only Qt stub
  (`XWALK_OS_TRACE_STUB`). It supports `OS.enable`, `OS.disable`, `all` and individual OS IDs with
  `.enable`/`.disable` without sibling repositories; normal traces start disabled. Records are written below
  `<build>/log` without console output. Host and Pi builds use the actual adapter, catalogue and sink from
  `xWalk-rpi5-trace`.

## 2. Source location

`xWalk-rpi5-os/xWalkStub` - source directory

## 3. Directory layout

```text
xWalkStub/
    CMakeLists.txt                            xwalk-os-stub executable, standalone xWalkOsTrace and tests
    include/XWalkStub.h                       Stub process entry and signal handler
    include/XWalkOsTrace.h                    Standalone OS trace selection and file sink
    include/xHal_Rpi5CarTraceOutput.h         Standalone copy of the byte-preserving output helpers
    src/main.cpp                              Stub executable entry point
    src/XWalkStub.cpp                         Simulated functions and Wi-Fi
    src/XWalkOsTrace.cpp                      Standalone trace implementation
    test/src/xWalkStubGoogleTest.cpp          Stub lifecycle tests
    test/src/XWalkStubTraceGoogleTest.cpp     Trace-selector tests (standalone only)
```

## 4. Public interface

- `xwalk::hal::XWalkStub::run(argc, argv)` and `stop(signal)`
  (`XWalkStub.h`).
- `XWalkOsTrace::configure(selector, error)`, `enabled(uid)`, `write(...)` and `commandText(text)`
  (`XWalkOsTrace.h`).

## 5. Build

`xwalk-os-stub` links `Qt5::Core` and `xWalkOsOutput`. In standalone, the static `xWalkOsTrace` library is built
here with `XWALK_OS_TRACE_DIRECTORY="<build>/log"`. Build through the [desktop root](../xWalk-rpi5-os.md).

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkStub --output-on-failure
```

`RejectsUnknownFunction` and `RunsAndStopsWithoutHardware` always run; the `xWalkOsTrace` selector tests are added
to `xWalkStubGoogleTest` in standalone only.

## 7. Safety and constraints

- The stub never accesses hardware, MQTT or NetworkManager and never stores Wi-Fi credentials.
- It does not emulate sensors, MQTT or the complete robot protocol.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkTest](../xWalkTest/xWalkTest.md)
- [xWalk-rpi5-trace](../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkSettings/xWalkSettings.md) · [Chapter index](../../index.md) · [Next page](../xWalkTest/xWalkTest.md)
