<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkConnectivity

**2. xWalk hardware &middot; Module 12**

<!-- xwalk-page-header:end -->

# xWalkConnectivity

`xWalkConnectivity` is the Connectivity functional group of the xWalk Agent layer. It groups `xWalkAppControl`
and `xWalkSpiTransfer` for externally controlled vehicle and bounded SPI transaction workflows behind the
`xWalk::AgentConnectivity` interface target.

## 1. Overview

Network and Linux SPI ownership remains in optional providers and the Raspberry Pi composition. Each child
remains an independent CMake target with its own public headers.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity`
(source directory)

## 3. Directory layout

```text
xWalkConnectivity/
    CMakeLists.txt                  Group options, xWalk::AgentConnectivity target, and group test registration
    test/
        src/                        xWalkDriverConnectivityGroupTest host suite
        hardware/src/               xWalkDriverConnectivityGroupHardwareTest hardware-profile suite
    xWalkAppControl/                SunFounder app-control coordinator and optional WebSocket provider
    xWalkSpiTransfer/               Bounded full-duplex SPI transaction coordinator
```

## 4. Child modules

| Note | Responsibility |
| --- | --- |
| [xWalkAppControl](xWalkAppControl/xWalkAppControl.md) | Mobile-app driving, camera, voice, and autonomous modes |
| [xWalkSpiTransfer](xWalkSpiTransfer/xWalkSpiTransfer.md) | Bounded full-duplex requests on a caller-owned SPI |

## 5. Public interface

`xWalkDriverConnectivity` (alias `xWalk::AgentConnectivity`) is a C++17 `INTERFACE` target that links
`xWalkAppControl` and `xWalkSpiTransfer`. The optional `xWalk::AppControlWebSocket` provider is not part of the
group interface; consumers link it explicitly.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_CONNECTIVITY_BUILD_HOST_TESTS` | `OFF` | Builds the group suite; forces the SPI test on |
| `XWALK_AGENT_CONNECTIVITY_BUILD_HARDWARE_TESTS` | `OFF` | Builds the hardware-profile group suite |

Either option includes `xWalkLibrary/XWalkDependencies.cmake` and requires GoogleTest.

## 7. Testing

`xWalkDriverConnectivityGroupHostTest` (labels `host`, `agent-group`) contains four cases. The `AppControl`
cases exercise the coordinator directly against the `xWalkRobotHatSimulation`, the shared
`xAgent_Rpi5CarAppControlTestSupport.cpp` fake transport, and the PiCar-X test support; the `SpiTransfer` case
runs the child host test in an isolated process.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkDriverConnectivityGroupHostTest
```

`xWalkDriverConnectivityGroupHardwareTest` (labels `hardware`, `agent-group`) checks the RPi build graph. Discover
hardware tests with `ctest -N -L hardware`; do not run them without explicit approval and a confirmed safe
Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkPicarx](../xWalkVehicle/xWalkPicarx/xWalkPicarx.md) and
  [xWalkComputerVision](../xWalkVision/xWalkComputerVision/xWalkComputerVision.md) for app control.
- [xWalkSpi](../../xWalkHal/interface/xWalkSpi/xWalkSpi.md) for SPI transfer.
- [xWalkRobotHat](../../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md) for the group host suite.

## 9. Safety and constraints

Every Connectivity child module owns a registered `RPIAGENT` bounded-operation trace. Use the authoritative
[Agent trace table](../xWalkDriver.md#runtime-tracing) to select AppControl or SpiTransfer without recording
network or SPI payload contents.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)

---

[Previous page](../xWalkCalibration/xWalkServoZeroing/xWalkServoZeroing.md) · [Chapter index](../../../index.md) · [Next page](xWalkAppControl/xWalkAppControl.md)
