<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkLineTracker

**2. xWalk hardware &middot; Module 107**

<!-- xwalk-page-header:end -->

# xWalkLineTracker

C++17 fixed-channel grayscale classification and line-tracking module for the xWalk Firmware HAL. It provides
three-channel grayscale classification, linear sensor calibration, cliff detection, line detection, adaptive
references, and normalized line-position estimation.

## 1. Overview

The application creates the I2C interface and three ADC channels before constructing either consumer:

```cpp
XWalkAdc left(i2c, 0U);
XWalkAdc middle(i2c, 1U);
XWalkAdc right(i2c, 2U);
XWalkGrayscaleModule grayscale(left, middle, right);
XWalkLineTracker tracker(left, middle, right);
```

Both classes store bounded non-owning ADC pointers. The three ADC objects and their I2C dependency must outlive
the grayscale module and line tracker. Neither class creates, owns, or releases hardware objects.

Ported behavior:

- Left, middle, and right channel order.
- Default grayscale references of 1,000 ADC counts.
- Black status at or below the reference and white status above it.
- Identity slope and zero offset calibration by default.
- Calibrated readings rounded to signed counts.
- Cliff detection when any value is below the configured threshold, 120 counts by default.
- Line detection when the channel spread is greater than 200 counts and no cliff exists.
- Weighted line position from -1.0 at the left to 1.0 at the right, rounded to two decimal places.
- Adaptive background and dark-line references using a five-percent update rate, starting at 1,000 and 200.
- Light and dark calibration aligned to the channel with the largest light sample.

Fixed-size arrays prevent incorrectly sized channel data. Non-finite coefficients, invalid light and dark ranges,
invalid channel indices, and calibrated signed-count overflow are rejected with project exceptions. The
calibrated output constraint is implemented as a protected member so conversion remains local to the tracker
contract.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker`

Source directory

## 3. Directory layout

```text
xWalkLineTracker/
├── CMakeLists.txt                                   Library and host-test targets
├── include/
│   ├── xHal_Rpi5CarGrayscaleModule.h                Raw grayscale acquisition and classification API
│   ├── xHal_Rpi5CarLineTracker.h                    Calibrated line-tracking API and numeric contracts
│   └── xHal_Rpi5CarLineTrackerTypes.h               Fixed arrays and linear calibration structure
├── src/
│   ├── xHal_Rpi5CarGrayscaleModule.cpp              Raw sampling, references, and black or white status
│   ├── xHal_Rpi5CarLineTrackerCalibration.cpp       Linear calibration and adaptive references
│   ├── xHal_Rpi5CarLineTrackerLifecycle.cpp         ADC binding, validation, and conversion helpers
│   └── xHal_Rpi5CarLineTrackerReading.cpp           Calibrated sampling, detection, and position
├── simulation/                                      Standalone host simulation with an in-memory I2C bus
└── test/
    ├── include/xHal_Rpi5CarLineTrackerTestSupport.h xwalk::hal::test::linetracker bus declarations
    └── src/
        ├── xHal_Rpi5CarLineTrackerTest.cpp          Simulated ADC behavior and validation coverage
        └── xHal_Rpi5CarLineTrackerTestSupport.cpp   Named in-memory I2C and ADC test bus
```

The test-support source is also compiled into the sensor-group interaction test.

## 4. Child modules

- [xWalkLineTracker Simulation](simulation/xWalkLineTracker%20Simulation.md) - standalone host simulation over
  real I2C, ADC, grayscale, and tracker interfaces.

## 5. Public interface

Headers live in the module `include`
directory.

| Declaration | Behavior |
|---|---|
| `XWalkGrayscaleModule(XWalkAdc& left, XWalkAdc& middle, XWalkAdc& right)` | Raw grayscale module |
| `XWalkGrayscaleModule::read()`, `readChannel()` | Raw ADC counts |
| `XWalkGrayscaleModule::readStatus()`, `setReference()` | Black or white status per channel |
| `XWalkLineTracker(XWalkAdc&, XWalkAdc&, XWalkAdc&, const XWalkLineCalibration& = {})` | Tracker |
| `read(boolean raw = false)`, `readChannel(uint32, boolean raw = false)` | Calibrated or raw counts |
| `isOnCliff()`, `isOnLine()`, `getLinePosition()` | Detection and position; overloads accept sampled data |
| `calibrate(lightData, darkData)`, `setCalibrationData()`, `calibrationData()` | Linear calibration |
| `setCliffThreshold()`, `cliffThreshold()` | Cliff threshold in counts |
| `updateLineBackgroundReference()`, `updateLineReference()` | Adaptive reference updates |
| `linetrackervalues`, `linetrackerstatus`, `XWalkLineCalibration` | Fixed three-channel types |

Both classes are neither copyable nor movable.

## 6. Build

The library target is `xWalkLineTracker`, a static C++17 library linked publicly to `xWalkAdc` and
`xWalkLibraryCommon` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/sensor/xWalkLineTracker)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_LINE_TRACKER_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkLineTrackerTest`; enables ADC and I2C host tests |
| `XWALK_LINE_TRACKER_BUILD_HARDWARE_TESTS` | `OFF` | Compiles ADC and Linux I2C hardware dependencies |

## 7. Configuration

Host tests generate `generated/xWalkLineTrackerTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarLineTrackerTraceConfig.py`, preserving previously stored trace states.

## 8. Testing

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-host -DXWALK_LINE_TRACKER_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-host --output-on-failure
```

The host tests use callback-driven I2C samples and do not access physical hardware. `xWalkLineTrackerHostTest`
(label `host`) covers line tracking, validation, and persistent trace-selector behavior. Reusable callback state
lives in `xwalk::hal::test::linetracker`.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker -B xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-rpi -DXWALK_LINE_TRACKER_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/sensor/xWalkLineTracker/build-rpi -N -L hardware
```

This compiles the line tracker and its ADC and Linux I2C dependencies. It does not register an automatic
line-tracker hardware test because safe analog thresholds and sensor placement are application-specific.

## 9. Dependencies

- `xWalkAdc` - three analog channels; transitively `xWalkI2c`.
- `xWalkLibraryCommon` - fixed-width types and line-tracker constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The three ADC objects and their I2C dependency are caller-owned and must outlive both consumers.
- Listed dependency hardware tests access `/dev/i2c-1`; run them only with explicit approval on a confirmed safe
  Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Sensor Layer](../xWalkHal%20Sensor%20Layer.md)
- [xWalkHal Sensor Tests](../test/xWalkHal%20Sensor%20Tests.md)
- [xWalkAdc](../../device/xWalkAdc/xWalkAdc.md)

---

[Previous page](../xWalkLed/simulation/xWalkLed%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkLineTracker%20Simulation.md)
