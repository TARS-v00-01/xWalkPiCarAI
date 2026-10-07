<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkI2c
Simulation

**2. xWalk hardware &middot; Module 77**

<!-- xwalk-page-header:end -->

# xWalkI2c Simulation

The `xWalkI2cSimulation` executable runs the public `XWalkI2c` API and the production Linux backend through
a build-selected device. The default `stub` backend uses an in-memory device mirror and demonstrates
probing, register writes, fail-safe writes and sequential and register reads without opening `/dev/i2c-*`.

## 1. Overview

The standalone `main()` explicitly boots the global trace service, applies an optional trace selector,
constructs the build-selected `XWalkI2cDevice` through `createI2cDevice()`, wraps it in `XWalkI2cLinux`
with one retry attempt, binds an `XWalkI2c` with all five `XHAL_I2C_*_CALLBACK` bindings and dispatches
`XWalkI2cHandler`. It does not include or invoke GoogleTest code. CMake supplies the generated configuration,
the device path and build-local log paths.

`XWalkI2cHandler::run()` uses address `0x14` and register `0x20`:

1. probe the address (status `1` if no response);
2. write the payload `0x12 0x34`;
3. repeat the write through `tryWriteRegister()` (status `2` if rejected);
4. read two bytes sequentially and two bytes from the register; status `0` on success.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation` -
source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                  Backend selection, trace catalogue, executable
├── config/xHal_Rpi5CarI2cTraceConfig.py           Validates and merges the persistent trace catalogue
├── include/
│   ├── xHal_Rpi5CarI2cDeviceFactory.h              createI2cDevice() factory declaration
│   ├── xHal_Rpi5CarI2cHandler.h                    Operation sequence handler
│   ├── xHal_Rpi5CarI2cHostStub.h                   In-memory XWalkI2cDevice mirror
│   ├── xHal_Rpi5CarI2cSimulationArguments.h        --help and --trace parsing
│   └── xHal_Rpi5CarI2cSimulationConfig.h           Default trace, log and device path macros
└── src/
    ├── main.cpp                                    Trace boot, composition and dispatch
    ├── xHal_Rpi5CarI2cDeviceFactoryHardware.cpp    Creates XWalkI2cDeviceLinux
    ├── xHal_Rpi5CarI2cDeviceFactoryStub.cpp        Creates XWalkI2cHostStub
    ├── xHal_Rpi5CarI2cHandler.cpp                  Probe, write, safe-write and read sequence
    ├── xHal_Rpi5CarI2cHostStub.cpp                 Mirror implementation (also used by host tests)
    └── xHal_Rpi5CarI2cSimulationArguments.cpp      Argument parser implementation
```

## 4. Build

The project forces `XWALK_I2C_BUILD_LINUX_BACKEND=ON` and adds the parent module. The stub build is the safe
default. Run from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-host -DXWALK_I2C_SIMULATION_BACKEND=stub -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-host --target xWalkI2cSimulation --parallel
xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-host/xWalkI2cSimulation --trace RPI.enable
```

The hardware selection compiles the same `main()` and handler with the hardware device factory:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-hardware -DXWALK_I2C_SIMULATION_BACKEND=hardware -DXWALK_I2C_SIMULATION_DEVICE=/dev/i2c-1
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-hardware --target xWalkI2cSimulation --parallel
```

## 5. Configuration

| CMake cache value | Default | Purpose |
|---|---|---|
| `XWALK_I2C_SIMULATION_BACKEND` | `stub` | `stub` or `hardware`; any other value fails configuration |
| `XWALK_I2C_SIMULATION_DEVICE` | `/dev/i2c-1` | Device path compiled into the runner |

The runner accepts no option, `--help` or `-h`, or exactly one `--trace <selector>`:

| Selector | Effect |
|---|---|
| `RPI.enable`, `RPI.disable` | Every `RPI` trace |
| `RPI.<number>.enable`, `RPI.<number>.disable` | One trace UID, for example `RPI.031.enable` |
| `all.enable`, `all.disable` | Every trace |
| `<file>.json` | Trace argument file passed to the trace service |

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/simulation/build-host/xWalkI2cSimulation --help
```

Help reports the accepted selector forms and the compile-time trace-ID uniqueness requirement without
configuring tracing or opening a device. Invalid syntax and scanner-unknown UIDs return status `2` before the
device is created.

The custom target `xWalkI2cSimulationTraceConfig` generates `generated/xWalkI2cTrace.xml` from the scanner
inventory. New traces start disabled; successful selector changes persist in that XML and load automatically
on later runs. Enabled messages, warnings and errors appear in the terminal and in
`log/xWalkI2cSimulation.log` inside the build directory.

## 6. Dependencies

- Parent module `xWalkI2cLinux` and `xWalkI2c`, `xWalkTrace` and a Python 3 interpreter.
- Linux only; configuration fails on other systems.

## 7. Safety and constraints

The hardware binary probes `0x14` and writes `0x12 0x34` to register `0x20` twice on the real bus. Run it
only after explicit approval and after confirming that the correct Raspberry Pi and Robot HAT setup is
connected and safe.

## 8. Related notes

- [xWalkI2c](../xWalkI2c.md)
- [xWalkI2c Tests](../test/xWalkI2c%20Tests.md)

---

[Previous page](../xWalkI2c.md) · [Chapter index](../../../../../index.md) · [Next page](../test/xWalkI2c%20Tests.md)
