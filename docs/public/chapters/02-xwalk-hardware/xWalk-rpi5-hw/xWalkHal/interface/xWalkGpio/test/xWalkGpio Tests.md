<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkGpio Tests

**2. xWalk hardware &middot; Module 74**

<!-- xwalk-page-header:end -->

# xWalkGpio Tests

The `xWalkGpio` host test suite is a GoogleTest executable that verifies the public `XWalkGpio` API, the
production `xWalkGpioLinux` backend, and the simulation argument parser without accessing a GPIO controller.

## 1. Overview

The fixture `TEST_SUITE_XWALK_GPIO` owns an `XWalkGpioHostStub`, injects it into an `XWalkGpioLinux` backend,
and binds an `XWalkGpio` object to that backend. The suite never opens `/dev/gpiochip0`.

| Test case | Verified behavior |
|---|---|
| `DigitalIo` | Output writes and input reads through the Linux request path |
| `ReadAfterPulseCloseReacquiresInput` | Closing pulse capture permits an ordinary input read before re-arming |
| `Polarity` | Logical active-high and active-low translation |
| `NamedPinMap` | `D0` to `D16` names and hardware aliases resolve to the expected lines |
| `Interrupt` | Handler registration, dispatch, and `deinit` cancellation through a fake backend |
| `Validation` | Rejection of invalid pins, names, incomplete callbacks, and null handlers |
| `SimulationTraceArgumentsDefault` | No-argument simulation invocation |
| `SimulationTraceArgumentsHelp` | `--help` handling |
| `SimulationTraceArgumentsUid` | `RPI.<number>` selectors |
| `SimulationTraceArgumentsAll` | `all` selectors |
| `SimulationTraceArgumentsValidation` | Rejection of malformed selectors |
| `KernelPulseWidthSurvivesSchedulingDelay` | Delayed userspace processing retains both kernel edge timestamps |
| `KernelPulseRejectsStaleAndIncompleteEdges` | Stale edges never pair with a new trigger; incomplete pulses fail |

The pulse cases use `PulseDevice` to inject delayed event delivery, short genuine pulses, stale edges,
missing edges, and invalid timestamps.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio/test` -
source directory

## 3. Directory layout

```text
test/
    CMakeLists.txt                          xWalkGpioTest target, trace catalogue, CTest registration
    include/
        xHal_Rpi5CarGpioTest.h              TEST_SUITE_XWALK_GPIO fixture declaration
        xHal_Rpi5CarGpioTestSupport.h       PulseDevice, interrupt records, pin mappings, callbacks
    src/
        xHal_Rpi5CarGpioTest.cpp            Test cases
        xHal_Rpi5CarGpioTestSupport.cpp     Shared device-free callback and fake implementations
```

Shared test state, fakes, mapping records, and callback declarations live in the named namespace
`xwalk::hal::test::gpio`, following the repository-wide test-support layout.

## 4. Build

The directory is added by the parent module when `XWALK_GPIO_BUILD_HOST_TESTS` is `ON`. The `xWalkGpioTest`
executable compiles the test sources together with the simulation host stub and argument parser, links
`GTest::gtest_main`, `xWalkGpioLinux`, and `xWalkTrace`, and is placed in the top-level build directory. The
build generates `generated/xWalkGpioTrace.xml` from the workspace trace inventory; the test log is
`log/xWalkGpioTest.log` under the test binary directory.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio -B build-host/xWalkGpio -DXWALK_GPIO_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/xWalkGpio --target xWalkGpioTest --parallel
```

## 5. Testing

The CTest entry is `xWalkGpioHostTest` with label `host`.

```bash
ctest --test-dir build-host/xWalkGpio -L host --output-on-failure
```

The module hardware test is defined by the parent module, not in this directory.

## 6. Dependencies

- GoogleTest (`find_package(GTest CONFIG REQUIRED)`).
- Python 3 for the trace-catalogue generator in `../simulation/config`.
- `xWalkGpioLinux`, `xWalkTrace`, and the simulation sources `xHal_Rpi5CarGpioHostStub.cpp` and
  `xHal_Rpi5CarGpioSimulationArguments.cpp`.

## 7. Related notes

- [xWalkGpio](../xWalkGpio.md)
- [xWalkGpio Simulation](../simulation/xWalkGpio%20Simulation.md)
- [xWalkHal Interface Tests](../../test/xWalkHal%20Interface%20Tests.md)

---

[Previous page](../simulation/xWalkGpio%20Simulation.md) · [Chapter index](../../../../../index.md) · [Next page](../../test/xWalkHal%20Interface%20Tests.md)
