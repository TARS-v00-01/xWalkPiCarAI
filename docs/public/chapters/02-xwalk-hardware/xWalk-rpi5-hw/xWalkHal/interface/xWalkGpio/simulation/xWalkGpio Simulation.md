<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkGpio
Simulation

**2. xWalk hardware &middot; Module 73**

<!-- xwalk-page-header:end -->

# xWalkGpio Simulation

The `xWalkGpioSimulation` executable runs the public `XWalkGpio` API through the production Linux
request-building logic of `xWalkGpioLinux`. The default `stub` backend mirrors chip metadata, line
configuration, reads, and writes without opening a physical GPIO controller.

## 1. Overview

`main.cpp` configures global tracing, parses an optional trace selector, creates the selected
`XWalkGpioDevice`, and constructs an `XWalkGpioLinux` owner that requires at least 27 lines. It binds an
`XWalkGpio` to the `LED` line (GPIO26), and `XWalkGpioHandler` drives the line low and then samples it.

| Backend | Device implementation | Effect |
|---|---|---|
| `stub` (default) | `XWalkGpioHostStub` | Device-free mirror; no controller is opened |
| `hardware` | `XWalkGpioDeviceLinux` | Opens `XWALK_GPIO_SIMULATION_DEVICE` and drives the `LED` line |

Exit status is 0 after a completed run and 2 for invalid arguments or a selector absent from the trace
inventory.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio/simulation` -
source directory

## 3. Directory layout

```text
simulation/
    CMakeLists.txt                                  Backend selection, trace catalogue, executable target
    config/xHal_Rpi5CarGpioTraceConfig.py           Validates and merges the persistent trace XML
    include/
        xHal_Rpi5CarGpioDeviceFactory.h             createGpioDevice factory declaration
        xHal_Rpi5CarGpioHandler.h                   Stateless simulation handler
        xHal_Rpi5CarGpioHostStub.h                  Device-free XWalkGpioDevice mirror
        xHal_Rpi5CarGpioSimulationArguments.h       Trace-option parser
        xHal_Rpi5CarGpioSimulationConfig.h          Simulation configuration constants
    src/
        main.cpp                                    Entry point
        xHal_Rpi5CarGpioDeviceFactoryStub.cpp       Factory for the stub backend
        xHal_Rpi5CarGpioDeviceFactoryHardware.cpp   Factory for the physical Linux device
        xHal_Rpi5CarGpioHandler.cpp                 Drives the line low and reads it back
        xHal_Rpi5CarGpioHostStub.cpp                Host mirror implementation, shared with host tests
        xHal_Rpi5CarGpioSimulationArguments.cpp     Selector validation and trace update
```

## 4. Build

| Cache variable | Default | Effect |
|---|---|---|
| `XWALK_GPIO_SIMULATION_BACKEND` | `stub` | Selects `stub` or `hardware`; any other value fails configuration |
| `XWALK_GPIO_SIMULATION_DEVICE` | `/dev/gpiochip0` | Device path compiled into the executable |

The project forces `XWALK_GPIO_BUILD_LINUX_BACKEND` to `ON`, adds the parent module, and requires a Linux
host and Python 3. From the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio/simulation -B build-stub/xWalkGpioSimulation -DXWALK_GPIO_SIMULATION_BACKEND=stub -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-stub/xWalkGpioSimulation --target xWalkGpioSimulation --parallel
```

```bash
build-stub/xWalkGpioSimulation/xWalkGpioSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no argument, `--help` or `-h`, or `--trace <selector>`. A selector is one of:

- `RPI.enable`, `RPI.disable`, `all.enable`, or `all.disable`;
- `RPI.<number>.enable` or `RPI.<number>.disable` for one trace UID; or
- a path ending in `.json`, applied through the shared trace API.

The build generates `<build>/generated/xWalkGpioTrace.xml` from the workspace trace inventory. New traces start
disabled. A successful selector persists in that XML and loads automatically on later runs; regenerating the
catalogue preserves existing global, module, and trace states. Enabled messages appear in the terminal and in
`<build>/log/xWalkGpioSimulation.log`; warnings and errors always appear in both.

## 6. Testing

The simulation has no CTest entry. Its host stub and argument parser are compiled into the module host suite;
see [xWalkGpio Tests](../test/xWalkGpio%20Tests.md).

## 7. Dependencies

- `xWalkGpioLinux` and `xWalkGpio` from the parent module.
- `xWalkTrace` for tracing, trace metadata (`xWalkTraceMetadata`), and selector handling.
- Python 3 for the trace-catalogue generator.

## 8. Safety and constraints

The `hardware` backend opens a physical GPIO controller and drives GPIO26 (`LED`) low. Build or run it only
with explicit approval and a confirmed, safe Raspberry Pi and Robot HAT setup. Use the `stub` backend for all
routine verification.

## 9. Related notes

- [xWalkGpio](../xWalkGpio.md)
- [xWalkGpio Tests](../test/xWalkGpio%20Tests.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkGpio.md) · [Chapter index](../../../../../index.md) · [Next page](../test/xWalkGpio%20Tests.md)
