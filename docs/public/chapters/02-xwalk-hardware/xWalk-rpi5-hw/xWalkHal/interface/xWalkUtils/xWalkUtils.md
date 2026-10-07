<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkUtils

**2. xWalk hardware &middot; Module 84**

<!-- xwalk-page-header:end -->

# xWalkUtils

`xWalkUtils` provides generic utility services without placing terminal, shell, process, network,
environment, or descriptor ownership inside the hardware-independent embedded core. Platform operations are
injected as callbacks; the optional `xWalkUtilsLinux` backend supplies them on Raspberry Pi Linux.

## 1. Overview

The core library provides:

- `XWalkUtils` for colored output, clamped system volume, synchronous command dispatch, executable checks,
  IPv4 lookup, username lookup, and linear mapping.
- `XWalkLazyReader<ValueType>` for bounded-rate callback acquisition and caching of value-like data or
  non-owning pointers.
- `XWalkStderrGuard` for scoped standard-error redirection.

The application creates platform services in `main()` and injects callbacks. Command callbacks must validate
untrusted input; `XWalkUtils` never constructs or invokes `sudo`, `amixer`, `which`, or another shell command
itself. Terminal color rendering is likewise owned by the output callback.

An empty IP address or username represents a not-found result. Executable checks (`commandExists`,
`isInstalled`, `checkExecutable`) share one typed backend operation because only the executable-search
mechanism differs.

### Linux backend

`XWalkUtilsLinux` is the optional Raspberry Pi Linux backend. It provides ANSI output through the
standard-output descriptor, PCM volume through `amixer -M sset 'PCM' <percent>%`, shell-compatible command
execution through `/bin/sh -c` with combined output, direct `PATH` executable lookup, interface enumeration,
effective-user lookup, and RAII standard-error redirection. It never invokes `sudo`. Command text retains the
upstream shell interpretation, so applications must validate untrusted values before composing a command.

Link `xWalkUtilsLinux`, create the backend before `XWalkUtils`, and pass `backend.utilityCallbacks()` with
`&backend` as the callback context. The same backend provides the paired callbacks for `XWalkStderrGuard`
through `stderrRedirectCallback()` and `stderrRestoreCallback()`.

The deprecated `reset_mcu()`, `get_battery_voltage()`, `set_pin()`, `enable_speaker()`, and
`disable_speaker()` wrappers remain represented by `XWalkBoardControl`, where their current hardware
operations belong.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils` -
source directory

## 3. Directory layout

```text
xWalkUtils/
    CMakeLists.txt                                  Core, Linux backend, and test targets
    include/
        xHal_Rpi5CarUtils.h                         XWalkUtils public class
        xHal_Rpi5CarUtilsTypes.h                    Colors, command result, callback aliases and table
        xHal_Rpi5CarLazyReader.h                    XWalkLazyReader template
        xHal_Rpi5CarStderrGuard.h                   XWalkStderrGuard scoped redirection
    src/                                            Hardware-independent utility behavior
    hardware/
        include/xHal_Rpi5CarUtilsLinux.h            Non-owning Linux callback composition API
        src/xHal_Rpi5CarUtilsLinux.cpp              Bounded Linux platform operations
        src/xHal_Rpi5CarUtilsLinuxCallbacks.cpp     Bridges callback contexts to the backend
        test/src/xHal_Rpi5CarUtilsLinuxTest.cpp     Safe Linux software test without mixer changes
    simulation/                                     Side-effect-free stub executable and trace configuration
    test/
        include/xHal_Rpi5CarUtilsTestSupport.h      Reusable named test support
        src/xHal_Rpi5CarUtilsTest.cpp               In-memory core host test
        src/xHal_Rpi5CarUtilsTestSupport.cpp        Test support implementation
        hardware/src/xHal_Rpi5CarUtilsHardwareTest.cpp  Opt-in Raspberry Pi platform and mixer test
```

## 4. Child modules

- [xWalkUtils Simulation](simulation/xWalkUtils%20Simulation.md) - standalone executable that injects the
  in-memory `XWalkUtilsHostStub`.

## 5. Public interface

Headers are in `include`.

| Element | Contract |
|---|---|
| `printColor`, `info`, `debug`, `warning`, `error` | Forward text, ending, and flush flag to the output callback |
| `setVolume(volumePercent)` | Clamps to 0 through 100 percent, then calls the volume callback |
| `runCommand(command, user, group)` | Returns `XWalkCommandResult` from the command callback |
| `commandExists`, `isInstalled`, `checkExecutable` | Executable lookup through one callback |
| `ipAddress(...)`, `username()` | Empty string when not found |
| `mapping(input, inMin, inMax, outMin, outMax)` | Linear mapping; finite values, non-zero input range |
| `XWalkUtilityColor` | `Gray`, `Red`, `Green`, `Yellow`, `Blue`, `Purple`, `DarkGreen`, `White` |
| `XWalkLazyReader(context, read, clock, intervalMs)` | Re-reads after the interval; clock in microseconds |
| `XWalkStderrGuard` | Redirects standard error on construction and restores it on destruction |

The default lazy-reader interval is `XHAL_RPI5CAR_UTILS_DEFAULT_LAZY_INTERVAL_MS` (10,000 ms). Null callbacks
and invalid mapping ranges raise `XWALK_INVAL` trace error signals.

## 6. Build

| Option | Default | Effect |
|---|---|---|
| `XWALK_UTILS_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkUtilsTest`; on Linux also the backend software test |
| `XWALK_UTILS_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkUtilsLinux` and `xWalkUtilsLinuxHardwareTest` |
| `XWALK_UTILS_BUILD_LINUX_BACKEND` | `OFF` | Builds `xWalkUtilsLinux` without registering tests |

The hardware-test and Linux-backend options fail configuration on a non-Linux host. In the workspace build of
`xWalk-rpi5-hw`, the root forces the host-test option from the host profile and the hardware-test option from
`XWALK_BUILD_RPI`.

Standalone host build from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils -B build-host/xWalkUtils -DXWALK_UTILS_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/xWalkUtils --parallel
```

Linux backend for applications, without tests:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils -B build-linux/xWalkUtils -DXWALK_UTILS_BUILD_LINUX_BACKEND=ON
```

## 7. Testing

| CTest name | Label | Scope |
|---|---|---|
| `xWalkUtilsHostTest` | `host` | Backend-neutral callbacks, lazy reader, stderr guard, validation, arguments |
| `xWalkUtilsLinuxSoftwareTest` | `host` | Safe Linux backend test on Linux hosts; no `amixer` or mixer change |
| `xWalkUtilsLinuxHardwarePlatformTest` | `hardware` | Raspberry Pi platform and mixer test |

```bash
ctest --test-dir build-host/xWalkUtils -L host --output-on-failure
```

The core host test uses `assert`; build it with `CMAKE_BUILD_TYPE=Debug` so assertions are not compiled out.
Reusable callback state is declared under `test/include` in the named `xwalk::hal::test::utils` namespace.
Test and simulation diagnostics use trace macros and write to both the terminal and target-specific log files.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils -B build-rpi/xWalkUtils -DXWALK_UTILS_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-rpi/xWalkUtils --parallel
```

```bash
ctest --test-dir build-rpi/xWalkUtils -N -L hardware
```

The final command only lists the hardware test.

## 8. Dependencies

- `xWalkLibraryCommon` (public) for project types and utility constants.
- `xWalkTrace` (private) for tracing and error signals.
- Python 3 for host-test trace-catalogue generation.
- `amixer` and `/bin/sh` on the target for the Linux backend.

## 9. Safety and constraints

- The hardware test writes one ANSI terminal record, checks the shell, loopback interface, username, and
  `amixer`, and then changes the PCM playback volume to 50 percent. Run it only with explicit approval on a
  confirmed, safe Raspberry Pi setup.
- Commands passed to the Linux backend are interpreted by the shell; validate untrusted values first.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkHal Interface Tests](../test/xWalkHal%20Interface%20Tests.md)
- [xWalkBoardControl](../../layer1/xWalkBoardControl/xWalkBoardControl.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkSpi/test/xWalkSpi%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkUtils%20Simulation.md)
