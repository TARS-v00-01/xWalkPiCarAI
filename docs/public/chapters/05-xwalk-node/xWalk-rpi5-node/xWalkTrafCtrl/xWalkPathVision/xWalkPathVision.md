<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkPathVision

**5. xWalk node &middot; Module 25**

<!-- xwalk-page-header:end -->

# xWalkPathVision

`xWalkPathVision` provides camera path assessment: `PathVision` estimates likely open, likely blocked or unknown
from BGR camera pixels. It is an experimental, advisory-only heuristic and never takes part in motor stopping.

## 1. Overview

`PathVision` does not measure distance or claim that an object is 8 cm away. The heuristic assumes a fixed,
forward-facing camera and requires calibration and validation with real road scenes before relying on it.

The region of interest is the central half of the image width and the lower half of its height. Canny edges and
morphological closing provide contour bounding boxes, and the largest overlap with that region determines
occupancy. Thin regions are excluded. Regions must reach the bottom 15% of the image to contribute to the
near-path estimate; connected furniture or ceiling edges higher in the image do not imply a near obstacle. A region
occupying at least 30% is a blocked candidate; occupancy of at least 10% with matched-box area growth of at least
1.35 is also a candidate. Growth requires intersection-over-union of at least 0.35 between successive boxes.
Occupancy below 5% is an open candidate; intermediate evidence is unknown. Three consecutive matching
classifications are required. These thresholds are pixel heuristics, not calibrated physical dimensions.

Empty, malformed, dark, overexposed, low-texture and blurred images return unknown. A large global image change
resets evidence. Resolution changes, non-increasing timestamps and gaps of 500 ms or more reset temporal evidence.
These checks cannot identify every covered lens or camera-pose change. Shadows and road texture can cause false
blocking; low-contrast and small objects can be missed. Likely open therefore means only that this heuristic found
no large region in its corridor.

Live traffic capture evaluates each sampled frame before model inference. Slow inference or LLM work can delay
subsequent frames. Classification changes produce local diagnostic text only: likely open, use caution, or
unknown. This component does not own a camera or GPIO.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkPathVision` -
source directory

## 3. Directory layout

```text
xWalkPathVision/
    CMakeLists.txt                      Library and host test; also usable as a standalone project
    include/xWalkPathVision.h           PathVision class
    src/xWalkPathVision.cpp             Edge, occupancy, growth and temporal evaluation
    test/src/xWalkPathVisionTest.cpp    Host GoogleTests with synthetic images
```

## 4. Public interface

Declared in
`xWalkPathVision.h` in
namespace `xwalk::traffic`. `PathVision::evaluate(frame, nowMs)` returns a `PathAssessment` with `state`,
`sampleMs`, `occupancy` and `growth`. `PathState` (`Unknown`, `LikelyOpen`, `LikelyBlocked`) and
`pathDescription` are defined in the shared
`xWalkPathAssessment.h`
in the proximity module.

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md), or standalone as `xWalkPathVisionHost`, which enables host
tests and needs only OpenCV 4 `core`/`imgproc` and GoogleTest. The library links publicly to `opencv_core` and
privately to `opencv_imgproc`.

## 6. Testing

The standalone test build needs no model assets or hardware. Run from `xWalk-rpi5-node/xWalkTrafCtrl`:

```bash
cmake -S xWalkPathVision -B /tmp/xwalk-path-vision -G Ninja && cmake --build /tmp/xwalk-path-vision && ctest --test-dir /tmp/xwalk-path-vision --output-on-failure
```

`xWalkPathVisionTest` (no CTest labels) covers temporal stabilization and gap resets, central versus side regions,
matched growth, poor images, resolution and scene changes, and distant edges above the near ground. Proximity
policy tests in [xWalkProximity](../xWalkProximity/xWalkProximity.md) verify sensor-only stopping and clearance
recovery without camera input. Synthetic tests do not constitute camera calibration or hardware
collision-avoidance validation.

## 7. Dependencies

- OpenCV 4 `core` and `imgproc`.
- `xWalkPathAssessment.h` from [xWalkProximity](../xWalkProximity/xWalkProximity.md).

## 8. Safety and constraints

Camera evaluation never requests `AllStop`, gates recovery, changes motor power or publishes an announcement. The
independent proximity sensor policy alone controls the 80 mm front-obstacle stop and sustained-clearance recovery,
including its existing handling of invalid or stale readings.

## 9. Related notes

- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkModel/xWalkModel.md) · [Chapter index](../../../index.md) · [Next page](../xWalkProtocol/xWalkProtocol.md)
