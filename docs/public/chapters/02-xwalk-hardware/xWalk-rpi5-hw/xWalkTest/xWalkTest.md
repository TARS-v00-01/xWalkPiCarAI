<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [2. xWalk hardware](../../index.md) / xWalkTest

**2. xWalk hardware &middot; Module 114**

<!-- xwalk-page-header:end -->

# xWalkTest

`xWalk-rpi5-hw/xWalkTest` contains the root cross-module hardware sequence tests. One shared GoogleTest fixture
runs the same production Controller, Driver, and HAL sequences for the Robot HAT v4 and v5 profiles with
deterministic HOST providers, and a target runs the complete hardware component regression.

## 1. Overview

The parameterized `XWalkHardwareSequence` fixture owns one real Controller Boot graph (`controller::XWalkBoot`) per
test. `SetUp()` writes an isolated board configuration below the build directory and starts the HOST graph;
`TearDown()` joins every worker before releasing the graph and the capture synchronization. Requests are submitted
through the production request queue, and each exchange waits for its response and operation lease release.

The sequences verify lifecycle and restart, motor PWM output and cleanup, camera servos, ADC failure propagation
and recovery, request correlation, battery averaging, camera failure recovery, and announcement and shutdown.
They do not validate electrical behavior, real cameras, speakers, or physical motion.

The directory is added by the `xWalk-rpi5-hw` root only when `BUILD_TESTING`, `XWALK_HAL_BUILD_HOST`, and
`XWALK_CONTROLLER_BUILD_HOST` are all enabled.

## 2. Source location

`xWalk-rpi5-hw/xWalkTest` (source directory)

## 3. Directory layout

```text
xWalkTest/
    CMakeLists.txt                       Host-only GoogleTest registration and full-test target
    include/
        xWalkHardwareTestSupport.h       Shared graph ownership and parameterized fixture
    src/
        xWalkHardwareTestSupport.cpp     Isolated configuration, bounded requests, motor output checks
        xWalkHardwareSequenceTest.cpp    Identical multi-device sequences for both board profiles
```

Related entry points outside this directory:

| File | Responsibility |
| --- | --- |
| `ci/run-module-tests.py` | Complete component regression |
| `ci/test-module-runner.py` | Inventory filter regressions |
| `xWalkController/test/src/xControllerOperationTestSupport.cpp` | Shared Controller operation capture |

## 4. Public interface

| Target or test | Description |
| --- | --- |
| `xWalkHardwareSequenceTest` | GoogleTest executable for the root sequences |
| `xWalkHardwareFullTest` | Runs `ci/run-module-tests.py --no-build` against the current build directory |

Test cases, each instantiated as `RobotHatProfiles` with `robot_hat_v4` and `robot_hat_v5`:

| Test case | Sequence |
| --- | --- |
| `MultiDeviceLifecycleAndRestart` | Activation, multi-device operation, stop, and restart |
| `SensorFailureRecoveryAndCorrelation` | ADC failure propagation, recovery, and request correlation |
| `BatteryWindowWithSharedSensorBus` | Battery averaging with a shared sensor bus |
| `AnnouncementAndShutdownSequence` | Announcement followed by shutdown |
| `CameraFailureRecoveryBetweenMovements` | Camera failure recovery between forward and reverse movements |

The fixture code lives in `namespace xwalk::hardware::test`.

## 5. Build

Configure the `xWalk-rpi5-hw` host preset, then build the sequence executable from `xWalk-rpi5-hw`:

```bash
cmake --build --preset host --target xWalkHardwareSequenceTest
```

The executable compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -UNDEBUG` on GCC and Clang.
Test data is written to `test-data` in the test build directory (`XWALK_HW_TEST_DIRECTORY`), never to a deployment
configuration.

## 6. Testing

| Test | Labels | Properties |
| --- | --- | --- |
| `xWalkHardwareSequenceHostTest` | `host;hw-integration;sequence` | `TIMEOUT 90`, `RUN_SERIAL` |
| `xWalkHardwareRunnerHostTest` | `host;hw-integration` | `TIMEOUT 15` |

Run the sequences alone after configuring and building the host preset:

```bash
ctest --test-dir ../build-host/cmake -R '^xWalkHardwareSequenceHostTest$' --output-on-failure
```

Build and run every hardware component suite, the root sequences, Library architecture checks, and audio assets:

```bash
python3 ci/run-module-tests.py --jobs 4
```

With an already fully built host tree, use `--no-build --build-dir ../build-host/cmake`, or invoke:

```bash
cmake --build ../build-host/cmake --target xWalkHardwareFullTest
```

The full-test target requires the normal aggregate build first. All runs exclude hardware-labelled tests and reject
a non-HOST cache. Each test command has a bounded timeout. Hardware integration CI adds the full regression after
its five component checks and requires it before the gate.

`xWalkHardwareRunnerHostTest` checks, without running devices, that the inventory filter selects every required
component group, excludes hardware-labelled, disabled, and unrelated suites, fails when a component is missing,
and includes the root Library architecture checks.

These tests use HOST providers only. Hardware tests elsewhere in the aggregate are opt-in; list them with
`ctest -N -L hardware` and never run them without explicit approval and a confirmed, safe Raspberry Pi and Robot
HAT setup.

## 7. Dependencies

- GoogleTest (`GTest::gtest_main`) and Python 3.
- `xWalkControllerBoot`, `xWalkUtilsLinux`, and the `xWalkRobotHatSimulation` HOST simulation.
- Controller test support headers from `xWalkController/test/include`.

## 8. Safety and constraints

- The fixture keeps response capture alive until every borrowed worker callback is joined.
- Only the test thread writes the acknowledged-response counter.
- Configuration stays under the build directory; deployment configuration is never touched.

## 9. Related notes

- [xWalk-rpi5-hw](../xWalk-rpi5-hw.md)
- [Building xWalk hardware](../BUILDING.md)
- [xWalkController](../xWalkController/xWalkController.md)
- [xWalkDriver](../xWalkDriver/xWalkDriver.md)
- [xWalkHal](../xWalkHal/xWalkHal.md)

---

[Previous page](../xWalkLibrary/common/xWalkLibrary%20Common.md) · [Chapter index](../../index.md) · [Next page](../BUILDING.md)
