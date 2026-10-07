<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkRoadUserSafety

**2. xWalk hardware &middot; Module 30**

<!-- xwalk-page-header:end -->

# xWalkRoadUserSafety

`xWalkRoadUserSafety` is the hardware-independent safety boundary for a future camera → YOLO detector → feature
extraction → Random Forest classifier flow. It validates the supported person, car, bicycle, bus, and motorbike
classes; rejects non-finite or out-of-range output; aggregates Safe, Warning, and Dangerous decisions; and requests
stop-and-disarm after danger or any pipeline failure.

## 1. Overview

No trained detector, Random Forest, accuracy result, ONNX runtime, or model file is included. Production
integration must supply bounded callbacks and report missing/corrupt models, invalid tensors, inference timeouts,
camera loss, and classifier failures through `XWalkRoadSafetyStatus`. A non-Ok status or provider exception becomes
`FailSafeStop`; recovery and motor rearming remain explicit outside this module.

`XWalkRoadUserSafety::evaluate()` processes one detector batch:

1. A non-Ok detector status triggers the fail-safe path with that status.
2. Every detection is validated. An invalid detection triggers the fail-safe path with `InvalidOutput`.
3. Valid detections are converted to `XWalkRoadRiskFeatures` (the lateral offset becomes its absolute value) and
   classified. A non-Ok classifier status fails safe with that status; a risk above `Dangerous` fails safe with
   `ClassifierFailure`.
4. The most severe risk is aggregated. `Dangerous` requests `stopMotion`; `Warning` or `Dangerous` calls `alert`
   with the accepted detection count. An empty batch is `Safe`.

The fail-safe path calls `stopMotion`, then `reportFault`, and returns `FailSafeStop` with the failing status and a
detection count of zero. All callbacks are `noexcept` function pointers, so provider failures must be converted to
statuses inside the provider.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkRoadUserSafety`
(source directory)

## 3. Directory layout

```text
xWalkRoadUserSafety/
    CMakeLists.txt                                      Library, alias, host test, and asset-manifest test
    include/
        xAgent_Rpi5CarRoadUserSafety.h                  Model-neutral safety coordinator
        xAgent_Rpi5CarRoadUserSafetyTypes.h             Classes, risks, statuses, features, and callbacks
    src/
        xAgent_Rpi5CarRoadUserSafety.cpp                Validation, aggregation, and fail-safe handling
    test/
        include/
            xAgent_Rpi5CarRoadUserSafetyTestSupport.h   Numeric doubles and recorded-scenario backend
        src/
            xAgent_Rpi5CarRoadUserSafetyTest.cpp        Numeric risk and failure scenarios
            xAgent_Rpi5CarRoadUserSafetyRecordedTest.cpp  Generated MJPEG end-to-end scenario
            xAgent_Rpi5CarRoadUserSafetyAssetTest.cpp   Committed recorded-scenario fixture decoding
            xAgent_Rpi5CarRoadUserSafetyTestSupport.cpp Test-double and scenario implementation
```

The shared recorded fixtures live in the vision group's `test/assets` directory.

## 4. Public interface

Public headers `xAgent_Rpi5CarRoadUserSafety.h` and `xAgent_Rpi5CarRoadUserSafetyTypes.h` are in
`include`.

| Type | Contents |
| --- | --- |
| `XWalkRoadUserClass` | `Person` 0, `Car` 1, `Bicycle` 2, `Bus` 3, `Motorbike` 4 |
| `XWalkRoadRisk` | `Safe`, `Warning`, `Dangerous`, `FailSafeStop` |
| `XWalkRoadSafetyStatus` | `Ok` plus ten camera, stream, line, model, inference, and classifier faults |
| `XWalkRoadUserDetectionBatch` | Detector status and owned detection vector |
| `XWalkRoadUserSafetyCallbacks` | `detect`, `classify`, `alert`, `stopMotion`, `reportFault` |
| `XWalkRoadUserSafetyResult` | Aggregate risk, status, and accepted detection count |

The constructor throws an invalid-argument error when any callback is null. The callback context is non-owning and
may be null when the callbacks permit it. `evaluate()` is `noexcept`. The class is neither copyable nor movable.

Detection validation ranges:

| Field | Accepted range |
| --- | --- |
| `classIdentifier` | 0 through 4 |
| `confidence` | finite, 0 through 1 |
| `distanceMeters` | finite, non-negative meters |
| `closingSpeedMetersPerSecond` | finite meters per second |
| `lateralOffsetNormalized` | finite, -1 through 1 |
| `boundingAreaNormalized` | finite, 0 through 1 of the frame area |

## 5. Build

The CMake target is `xWalkRoadUserSafety` with the alias `xWalk::RoadUserSafety`. It is a C++17 static library
that links `xWalkLibraryCommon` publicly and `xWalkTrace` privately, and adds `xWalkLibrary/common` when that
target is missing. GCC and Clang builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_ROAD_USER_SAFETY_BUILD_HOST_TESTS` | `OFF` | Builds the host tests with GoogleTest, OpenCV 4, Python 3 |

The test build requires the OpenCV `core`, `imgproc`, and `videoio` components. The xWalkDriver workspace build
sets the option from `XWALK_AGENT_BUILD_HOST`.

## 6. Testing

| CTest name | Coverage |
| --- | --- |
| `xWalkRoadUserSafetyHostTest` | All GoogleTest cases |
| `xWalkVisionAssetManifestTest` | `validate-assets.py` manifest and checksum validation |

`xWalkRoadUserSafetyHostTest` carries the labels
`host;vision;risk;fault-injection;recorded-media;recorded-scenario`.
`xWalkVisionAssetManifestTest` carries `host;vision;recorded-media;fixture-validation`.

The recorded scenario test generates a four-frame MJPEG AVI. OpenCV reads the complete file in order, a
deterministic image detector extracts two person rectangles, the normal feature and risk path transitions through
Safe, Warning, and Dangerous, and danger activates simulated red-LED and buzzer outputs. A missing grayscale line
and normal end-of-video both request stop-and-disarm. Additional numeric scenarios cover multiple road users,
low-confidence output, camera loss, model failure, and invalid output.

The asset test decodes twelve committed 320-by-240, five-frame recorded scenarios twice each and checks frame
order, clean end of video, and deterministic content. It also verifies that malformed JPEG fixtures produce
no frames.
Tests use no physical device, network, or trained model.

Build and run the focused test from `xWalk-rpi5-hw`; the preset places its build tree in `build-host/cmake` at the
repository root:

```bash
cmake --preset host-debug
```

```bash
cmake --build ../build-host/cmake --target xWalkRoadUserSafetyTest
```

```bash
ctest --test-dir ../build-host/cmake -R 'xWalkRoadUserSafetyHostTest|xWalkVisionAssetManifestTest' --output-on-failure
```

This module is verified on x86 with deterministic doubles and recorded media only. A production backend, target
ARM64 build, Raspberry Pi 5 camera path, model evaluation, and physical PiCar-X stop response all remain required.
The module has no hardware test.

## 7. Dependencies

- `xWalkLibraryCommon`: shared Agent types.
- `xWalkTrace`: configuration trace `RPIAGENT.032`.
- Test only: GoogleTest, OpenCV 4, Python 3, and the
  vision test assets.

## 8. Safety and constraints

- Every non-Ok status, invalid detection, or invalid classifier result requests stop-and-disarm and reports
  a fault.
- The module never rearms motors; recovery requires an explicit external decision.
- Callbacks must be bounded and non-throwing; detector and inference deadlines belong to the provider.
- Deterministic doubles and recorded fixtures do not demonstrate detection accuracy or real-world safety.

## 9. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkVision Test Assets](../test/assets/xWalkVision%20Test%20Assets.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkFaceTracking/xWalkFaceTracking.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkTreasureHunt/xWalkTreasureHunt.md)
