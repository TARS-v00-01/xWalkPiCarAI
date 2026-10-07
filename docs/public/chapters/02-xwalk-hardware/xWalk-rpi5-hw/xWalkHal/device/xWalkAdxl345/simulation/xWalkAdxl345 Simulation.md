<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkAdxl345
Simulation

**2. xWalk hardware &middot; Module 55**

<!-- xwalk-page-header:end -->

# xWalkAdxl345 Simulation

The executable exercises `XWalkAdxl345` through an in-memory I2C backend. It demonstrates measurement
configuration, discarded samples, signed conversion, and axis ordering without opening `/dev/i2c-1`.

## 1. Overview

`xWalkAdxl345Simulation` is a standalone, device-free host executable. It links the public `xWalkAdxl345` library
and `xWalkTrace`, replaces hardware access with an in-memory I2C device, and returns 0 only when every expected
observation holds. It never opens `/dev/i2c-1` or an accelerometer.

Scenario:

1. Creates `XWalkI2c` over `XWalkAdxl345HostStub` probe, register-write, read, and register-read callbacks.
2. Constructs `XWalkAdxl345` with its default address and reads all three axes.
3. Expects `{1.0, 0.0, -1.0}` g, six register writes, and six register reads.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                  Standalone project and `xWalkAdxl345Simulation` target
├── config/
│   └── xHal_Rpi5CarAdxl345TraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarAdxl345HostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarAdxl345Simulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarAdxl345SimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarAdxl345SimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                    Help, argument, and trace handling
    ├── xHal_Rpi5CarAdxl345HostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarAdxl345Simulation.cpp           Scenario implementation
    └── xHal_Rpi5CarAdxl345SimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.198` at start, `RPI.197` when the scenario completes, and `RPI.199` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/simulation/build-host --target xWalkAdxl345Simulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkAdxl345/simulation/build-host/xWalkAdxl345Simulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_I2C_BUILD_HOST_TESTS`, `XWALK_I2C_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkAdxl345Trace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarAdxl345TraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkAdxl345Simulation.log` below the build directory. Without
the build-time definitions, `xHal_Rpi5CarAdxl345SimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkAdxl345Trace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkAdxl345](../xWalkAdxl345.md) host tests.

## 8. Dependencies

- `xWalkAdxl345` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-1` or an accelerometer; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkAdxl345](../xWalkAdxl345.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../../interface/xWalkI2c/xWalkI2c.md)

---

[Previous page](../xWalkAdxl345.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkCamera/xWalkCamera.md)
