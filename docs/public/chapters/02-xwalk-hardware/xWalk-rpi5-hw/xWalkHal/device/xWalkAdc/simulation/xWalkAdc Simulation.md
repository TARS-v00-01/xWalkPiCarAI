<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkAdc
Simulation

**2. xWalk hardware &middot; Module 53**

<!-- xwalk-page-header:end -->

# xWalkAdc Simulation

The executable exercises `XWalkAdc` through an in-memory I2C backend. It demonstrates address selection, sample
acquisition, and voltage conversion without opening `/dev/i2c-1` or accessing a Robot HAT.

## 1. Overview

`xWalkAdcSimulation` is a standalone, device-free host executable. It links the public `xWalkAdc` library and
`xWalkTrace`, replaces hardware access with an in-memory I2C device, and returns 0 only when every expected
observation holds. It never opens `/dev/i2c-1` or a Robot HAT.

Scenario:

1. Creates `XWalkI2c` over `XWalkAdcHostStub` probe, register-write, and read callbacks.
2. Constructs `XWalkAdc` for channel `A3` with automatic addressing.
3. Expects selection of `0x15` after two probes, two command writes, raw sample `0x0800`, and a voltage between
   1.64 V and 1.66 V.

| Exit status | Meaning |
|---|---|
| `0` | Help printed, or the scenario met every expectation |
| `1` | A scenario expectation failed, or help could not be read |
| `2` | Invalid arguments, or the trace identifier is absent from the trace inventory |

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/simulation`

Source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                              Standalone project and `xWalkAdcSimulation` target
├── config/
│   └── xHal_Rpi5CarAdcTraceConfig.py           Persistent trace-catalogue generator
├── include/
│   ├── xHal_Rpi5CarAdcHostStub.h               In-memory backend declaration
│   ├── xHal_Rpi5CarAdcSimulation.h             Scenario entry point declaration
│   ├── xHal_Rpi5CarAdcSimulationArguments.h    Command-line parser declaration
│   └── xHal_Rpi5CarAdcSimulationConfig.h       Default trace-configuration and log paths
└── src/
    ├── main.cpp                                Help, argument, and trace handling
    ├── xHal_Rpi5CarAdcHostStub.cpp             In-memory backend callbacks
    ├── xHal_Rpi5CarAdcSimulation.cpp           Scenario implementation
    └── xHal_Rpi5CarAdcSimulationArguments.cpp  Trace selector parsing
```

## 4. Public interface

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`. A selector is
`RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a trace-update JSON path
ending in `.json`.

The simulation emits trace UIDs `RPI.179` at start, `RPI.178` when the scenario completes, and `RPI.180` with the
final status.

## 5. Build

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/simulation -B xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/simulation/build-host --target xWalkAdcSimulation --parallel
```

```bash
./xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/simulation/build-host/xWalkAdcSimulation --trace RPI.enable
```

The project adds the parent module with `add_subdirectory` and forces these dependency options `OFF`:
`XWALK_I2C_BUILD_HOST_TESTS`, `XWALK_I2C_BUILD_HARDWARE_TESTS`.

## 6. Configuration

The build generates `generated/xWalkAdcTrace.xml` from the trace inventory `generated/xwalk-traces.xml` with
`config/xHal_Rpi5CarAdcTraceConfig.py`. The generator preserves previously stored enable and disable states.
Successful trace changes update the generated XML and load automatically on the next run.

Enabled messages appear in the terminal and in `log/xWalkAdcSimulation.log` below the build directory. Without the
build-time definitions, `xHal_Rpi5CarAdcSimulationConfig.h` falls back to `xwalk-traces.xml` and
`log/xWalkAdcTrace.log`.

## 7. Testing

The executable is a demonstration, not a registered CTest. Its exit status reports whether the scenario held.
Automated coverage is in the [xWalkAdc](../xWalkAdc.md) host tests.

## 8. Dependencies

- `xWalkAdc` library and its transitive HAL dependencies.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory from `xWalk-rpi5-trace`.
- Python 3 interpreter for trace-catalogue generation.

## 9. Safety and constraints

- The simulation never opens `/dev/i2c-1` or a Robot HAT; it is safe on any host.
- Physical behavior remains unverified by this executable; hardware validation uses the opt-in module hardware
  tests.

## 10. Related notes

- [xWalkAdc](../xWalkAdc.md)
- [xWalkHal Device Layer](../../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../../test/xWalkHal%20Device%20Tests.md)
- [xWalkI2c](../../../interface/xWalkI2c/xWalkI2c.md)

---

[Previous page](../xWalkAdc.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkAdxl345/xWalkAdxl345.md)
