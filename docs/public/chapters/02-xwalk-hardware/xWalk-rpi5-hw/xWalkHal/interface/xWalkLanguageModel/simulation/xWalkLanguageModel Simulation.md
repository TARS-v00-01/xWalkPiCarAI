<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) /
xWalkLanguageModel Simulation

**2. xWalk hardware &middot; Module 80**

<!-- xwalk-page-header:end -->

# xWalkLanguageModel Simulation

The standalone `xWalkLanguageModelSimulation` executable exercises `XWalkLanguageModel` through an in-memory
callback backend. It performs no provider selection, credential access, process launch, or network request.

## 1. Overview

The scenario sets instructions and welcome text, adds a prior assistant message, sends one prompt, and verifies
the stubbed response and the prompt text received by the host stub. It does not compose the HTTP provider.
Prompt, response, endpoint, model, image, and credential content are not logged.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/simulation` -
source directory

## 3. Directory layout

```text
simulation/
    CMakeLists.txt                                          Standalone project
    config/xHal_Rpi5CarLanguageModelTraceConfig.py          Validates and merges the persistent trace catalogue
    include/
        xHal_Rpi5CarLanguageModelHostStub.h                 In-memory backend callbacks
        xHal_Rpi5CarLanguageModelSimulation.h               Simulation entry point
        xHal_Rpi5CarLanguageModelSimulationArguments.h      Trace-option parsing
        xHal_Rpi5CarLanguageModelSimulationConfig.h         Trace configuration and log paths
    src/
        main.cpp                                            Executable entry point
        xHal_Rpi5CarLanguageModelHostStub.cpp               Host stub implementation
        xHal_Rpi5CarLanguageModelSimulation.cpp             Network-free conversation scenario
        xHal_Rpi5CarLanguageModelSimulationArguments.cpp    Selector validation and persistence
```

## 4. Build

From the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/simulation/build-host -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/simulation/build-host --target xWalkLanguageModelSimulation --parallel
```

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/simulation/build-host/xWalkLanguageModelSimulation --trace RPI.enable
```

## 5. Configuration

Trace selectors accept `RPI.<digits>.enable`, `RPI.enable`, `all.enable`, their `.disable` counterparts, or a
trace-update JSON path. Successful changes update `generated/xWalkLanguageModelTrace.xml` and load automatically
on the next run. Enabled traces appear in the terminal and
`<build directory>/log/xWalkLanguageModelSimulation.log`.

## 6. Dependencies

`xWalkLanguageModel`, `xWalkTrace`, and Python 3 for the trace catalogue. libcurl and json-c are not required.

## 7. Related notes

- [xWalkLanguageModel](../xWalkLanguageModel.md)
- [xWalkHal Interface Layer](../../xWalkHal%20Interface%20Layer.md)

---

[Previous page](../xWalkLanguageModel.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkSpi/xWalkSpi.md)
