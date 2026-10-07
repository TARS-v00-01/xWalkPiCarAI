<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkUtils
Simulation

**2. xWalk hardware &middot; Module 85**

<!-- xwalk-page-header:end -->

# xWalkUtils Simulation

The `xWalkUtilsSimulation` executable runs `XWalkUtils` through the in-memory `XWalkUtilsHostStub`. It mirrors
output, volume, command, executable, network, and username operations without changing the mixer, executing
commands, redirecting descriptors, or querying host network and user state.

## 1. Overview

`runUtilsSimulation` writes an info message, sets the volume to 45 percent, runs the command `status`, checks
the executable `xwalk-tool`, and reads the IP address and username. It returns 0 when the stub records the
expected values (IP address `192.0.2.10`, username `xwalk`) and `XWalkUtils::mapping(5, 0, 10, 0, 100)` yields
50; otherwise it returns 1. Invalid arguments or a selector absent from the trace inventory return 2.

There is no hardware backend for this simulation.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils/simulation` -
source directory

## 3. Directory layout

```text
simulation/
    CMakeLists.txt                                  Trace catalogue and executable target
    config/xHal_Rpi5CarUtilsTraceConfig.py          Validates and merges the persistent trace XML
    include/
        xHal_Rpi5CarUtilsHostStub.h                 Side-effect-free callback mirror
        xHal_Rpi5CarUtilsSimulation.h               runUtilsSimulation declaration
        xHal_Rpi5CarUtilsSimulationArguments.h      Trace-option parser
        xHal_Rpi5CarUtilsSimulationConfig.h         Simulation configuration constants
    src/
        main.cpp                                    Entry point
        xHal_Rpi5CarUtilsHostStub.cpp               Host stub implementation
        xHal_Rpi5CarUtilsSimulation.cpp             Simulation scenario
        xHal_Rpi5CarUtilsSimulationArguments.cpp    Selector validation, shared with the host test
```

## 4. Build

The project adds the parent `xWalkUtils` module and requires Python 3. From the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkUtils/simulation -B build-stub/xWalkUtilsSimulation -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-stub/xWalkUtilsSimulation --target xWalkUtilsSimulation --parallel
```

```bash
build-stub/xWalkUtilsSimulation/xWalkUtilsSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no argument, `--help` or `-h`, or `--trace <selector>`. A selector targets `RPI`,
`all`, or one `RPI.<number>` trace UID with an `.enable` or `.disable` suffix, or names a `.json` file applied
through the shared trace API.

The build generates `<build>/generated/xWalkUtilsTrace.xml` from the workspace trace inventory. Trace selectors
persist in that XML, and a later run loads their saved state without another flag. Enabled messages appear in
the terminal and in `<build>/log/xWalkUtilsSimulation.log`.

## 6. Testing

The simulation has no CTest entry. Its argument parser is compiled into `xWalkUtilsTest`; see the Testing
section of [xWalkUtils](../xWalkUtils.md).

## 7. Dependencies

- `xWalkUtils` from the parent module.
- `xWalkTrace` and its `xWalkTraceMetadata` target.
- Python 3 for the trace-catalogue generator.

## 8. Safety and constraints

The simulation is side-effect free and safe for routine host use.

## 9. Related notes

- [xWalkUtils](../xWalkUtils.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkUtils.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkWebSearch/xWalkWebSearch.md)
