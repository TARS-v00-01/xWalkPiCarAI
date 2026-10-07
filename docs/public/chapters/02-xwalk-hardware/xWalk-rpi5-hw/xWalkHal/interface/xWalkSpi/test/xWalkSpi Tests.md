<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkSpi Tests

**2. xWalk hardware &middot; Module 83**

<!-- xwalk-page-header:end -->

# xWalkSpi Tests

The `xWalkSpi` host test suite verifies the public SPI object and the production Linux backend through the
device-free host mirror. It never opens `/dev/spidev*` and does not require a Raspberry Pi.

## 1. Overview

The `TEST_SUITE_XWALK_SPI` fixture owns an `XWalkSpiHostStub`, an `XWalkSpiLinux` backend constructed with that
stub, the placeholder path `host-spi-mirror` and the default configuration, and an `XWalkSpi` bound with
`XHAL_SPI_TRANSFER_CALLBACK`. `SetUpTestSuite()` boots the global trace service with the generated test
catalogue and a build-local log. A test-local callback returns a deliberately incomplete response.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/test` -
source directory

## 3. Directory layout

```text
test/
├── CMakeLists.txt                  xWalkSpiTest target, trace catalogue generation, CTest registration
├── include/xHal_Rpi5CarSpiTest.h   GoogleTest fixture declaration and owned test dependencies
└── src/xHal_Rpi5CarSpiTest.cpp     Individual SPI and simulation-argument tests
```

The executable also compiles `simulation/src/xHal_Rpi5CarSpiHostStub.cpp` and
`simulation/src/xHal_Rpi5CarSpiSimulationArguments.cpp` from the sibling simulation directory.

## 4. Build

The directory is added by the module build when `XWALK_SPI_BUILD_HOST_TESTS=ON`. Run from the repository
root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi -B xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host -DXWALK_SPI_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host --parallel
```

The `xWalkSpiTest` executable is written to the top of the build directory. The custom target
`xWalkSpiTestTraceConfig` runs `simulation/config/xHal_Rpi5CarSpiTraceConfig.py` against the generated
`xwalk-traces.xml` inventory to produce `test/generated/xWalkSpiTrace.xml`; the log is written to
`test/log/xWalkSpiTest.log` in the build directory.

## 5. Testing

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host -L host --output-on-failure
```

```bash
xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host/xWalkSpiTest
```

| Expected result | Value |
|---|---|
| CTest name | `xWalkSpiHostTest` |
| CTest label | `host` |
| GoogleTest cases | `9` |
| Required hardware | None |

| Test case | Verification |
|---|---|
| `Transfer` | `0x9F 0x00 0x00 0x00` returns `0x00 0xEF 0x40 0x18`; default speed, mode and word width applied |
| `TransferValidation` | Empty payload throws `std::invalid_argument`; 257 bytes throws `std::out_of_range` |
| `CallbackValidation` | A null transfer callback throws `std::invalid_argument` |
| `ResponseLengthValidation` | A short backend response throws `std::runtime_error` |
| `SimulationTraceArgumentsDefault` | No option is valid |
| `SimulationTraceArgumentsHelp` | `--help` requests help |
| `SimulationTraceArgumentsUid` | `RPI.059.enable` applies |
| `SimulationTraceArgumentsAll` | `all.disable` applies |
| `SimulationTraceArgumentsValidation` | `RPI.Camera.enable` and an unknown option are rejected |

The physical transfer test is not part of this directory; it is registered by the module build as
`xWalkSpiLinuxHardwareTransferTest` and is described in [xWalkSpi](../xWalkSpi.md).

## 6. Dependencies

- GoogleTest (`GTest::gtest_main`) and a Python 3 interpreter.
- `xWalkSpiLinux`, which brings in `xWalkSpi` and `xWalkLibraryCommon`, and `xWalkTrace`.

## 7. Safety and constraints

The suite is host-only and device-free. The fixture never constructs `XWalkSpiDeviceLinux`.

## 8. Related notes

- [xWalkSpi](../xWalkSpi.md)
- [xWalkSpi Simulation](../simulation/xWalkSpi%20Simulation.md)

---

[Previous page](../simulation/xWalkSpi%20Simulation.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkUtils/xWalkUtils.md)
