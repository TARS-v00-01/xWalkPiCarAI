<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkI2c Tests

**2. xWalk hardware &middot; Module 78**

<!-- xwalk-page-header:end -->

# xWalkI2c Tests

The `xWalkI2c` host test suite verifies the public I2C object and the production Linux backend through the
device-free host mirror. It never opens `/dev/i2c-*` and does not require a Raspberry Pi.

## 1. Overview

The `TEST_SUITE_XWALK_I2C` fixture owns an `XWalkI2cHostStub`, an `XWalkI2cLinux` backend constructed with
that stub, the placeholder path `host-i2c-mirror` and one retry attempt, and an `XWalkI2c` bound to the
backend with all five `XHAL_I2C_*_CALLBACK` bindings. `SetUpTestSuite()` boots the global trace service with
the generated test catalogue and a build-local log.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/test` -
source directory

## 3. Directory layout

```text
test/
├── CMakeLists.txt                  xWalkI2cTest target, trace catalogue generation, CTest registration
├── include/xHal_Rpi5CarI2cTest.h   GoogleTest fixture declaration and owned test dependencies
└── src/xHal_Rpi5CarI2cTest.cpp     Individual I2C and simulation-argument tests
```

The executable also compiles `simulation/src/xHal_Rpi5CarI2cHostStub.cpp` and
`simulation/src/xHal_Rpi5CarI2cSimulationArguments.cpp` from the sibling simulation directory.

## 4. Build

The directory is added by the module build when `XWALK_I2C_BUILD_HOST_TESTS=ON`. Run from the repository
root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host -DXWALK_I2C_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host --parallel
```

The `xWalkI2cTest` executable is written to the top of the build directory. The custom target
`xWalkI2cTestTraceConfig` runs `simulation/config/xHal_Rpi5CarI2cTraceConfig.py` against the generated
`xwalk-traces.xml` inventory to produce `test/generated/xWalkI2cTrace.xml`; the log is written to
`test/log/xWalkI2cTest.log` in the build directory.

## 5. Testing

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host -L host --output-on-failure
```

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host/xWalkI2cTest
```

| Expected result | Value |
|---|---|
| CTest name | `xWalkI2cHostTest` |
| CTest label | `host` |
| GoogleTest cases | `13` |
| Required hardware | None |
| Required sibling modules | `xWalkLibraryCommon`, `xWalkTrace` |
| Expected passing CTest entries | `1` |

| Test case | Verification |
|---|---|
| `Probe` | Probing `0x14` succeeds and selects that address |
| `ProbeValidation` | Address `0x80` throws `std::out_of_range` |
| `WriteRegister` | Address, register and payload reach the device mirror |
| `TryWriteRegister` | Valid payload returns `true`; empty payload returns `false` |
| `Read` | Sequential two-byte read returns the mirrored bytes |
| `ReadRegister` | Register-addressed read returns the mirrored bytes |
| `WriteRegisterThenRead` | Command write followed by a two-byte read |
| `ReadRegisterCallbackValidation` | Missing register-read callback throws `std::runtime_error` |
| `SimulationTraceArgumentsDefault` | No option is valid and requests no help |
| `SimulationTraceArgumentsHelp` | `--help` and `-h` request help |
| `SimulationTraceArgumentsUid` | `RPI.031.disable` and `RPI.031.enable` apply |
| `SimulationTraceArgumentsAll` | `all.disable` and `all.enable` apply |
| `SimulationTraceArgumentsValidation` | Malformed selector such as `RPI.Camera.enable` is rejected |

The physical probe test is not part of this directory; it is registered by the module build as
`xWalkI2cLinuxHardwareProbeTest` and is described in [xWalkI2c](../xWalkI2c.md).

## 6. Dependencies

- GoogleTest (`GTest::gtest_main`) and a Python 3 interpreter.
- `xWalkI2cLinux`, which brings in `xWalkI2c` and `xWalkLibraryCommon`, and `xWalkTrace`.

## 7. Safety and constraints

The suite is host-only and device-free. The fixture never constructs `XWalkI2cDeviceLinux`.

## 8. Related notes

- [xWalkI2c](../xWalkI2c.md)
- [xWalkI2c Simulation](../simulation/xWalkI2c%20Simulation.md)

---

[Previous page](../simulation/xWalkI2c%20Simulation.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkLanguageModel/xWalkLanguageModel.md)
