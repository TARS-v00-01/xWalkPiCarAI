<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkCapture

**5. xWalk node &middot; Module 20**

<!-- xwalk-page-header:end -->

# xWalkCapture

`xWalkCapture` provides native OpenCV frame acquisition for the traffic controller: a local video or still image
on the host, or the Raspberry Pi CSI camera through GStreamer or the shared camera feed, with frame sampling and
scoped cleanup.

## 1. Overview

`Capture` reads the next sampled BGR frame together with its source-frame index and timestamp. Host videos are
sampled every `frame_stride` frames; the timestamp is the frame index divided by the source FPS. Live capture
uses elapsed monotonic time. A still image yields exactly one frame. `max_frames` limits emitted frames, with zero
meaning unlimited. A decode failure after at least one readable host frame is treated as end of input; a failure
on the first frame or during live capture raises an error.

Pi capture uses `XWalkSharedVideoCapture`, which opens the configured GStreamer pipeline directly or consumes the
[xWalkCameraSvc](../xWalkCameraSvc/xWalkCameraSvc.md) snapshot feed when `XWALK_CAMERA_FRAME_FILE` is set.
`frameTimeMs()` returns the most recent frame's conservative monotonic capture or publication time, so that the
runtime can reject frames acquired before a proximity blockage.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkCapture` -
source directory

## 3. Directory layout

```text
xWalkCapture/
    CMakeLists.txt                  Static library and GoogleTest registration
    include/xWalkCapture.h          Capture class
    src/xWalkCapture.cpp            Video, image and CSI acquisition
    test/src/xWalkCaptureTest.cpp   Host GoogleTests
```

## 4. Public interface

Declared in `xWalkCapture.h`
in namespace `xwalk::traffic`:

| Member | Contract |
| --- | --- |
| `Capture(const Settings&)` | Open the selected image, host video or Pi pipeline; throws on failure |
| `next(frame, index, seconds)` | Return the next sampled frame, or false at end of input or frame limit |
| `frameTimeMs()` | Monotonic acquisition time of the latest frame in milliseconds |

Construction rejects a zero frame stride, an unreadable image, a host input that is not a regular file, an
unopenable source and an invalid host FPS.

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). Links publicly to `xWalkConfiguration`, `opencv_core` and
`opencv_videoio`, and privately to `opencv_imgcodecs`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkCapture --output-on-failure
```

`xWalkCaptureGoogleTest` (labels `host;gtest;xWalkCapture`) covers real local-video sampling, timestamps and
limits, single-frame still images, rejection of a missing local video without opening hardware, and preservation
of pre-blockage frame age for shared frames. It opens no camera device.

## 7. Dependencies

- [xWalkConfiguration](../xWalkConfiguration/xWalkConfiguration.md) for `Settings`.
- OpenCV `core`, `videoio` and `imgcodecs`; Pi capture needs OpenCV with GStreamer plus compatible
  `libcamerasrc`, `videoconvert` and `appsink` plugins and libcamera.
- `xHal_Rpi5CarSharedVideoCapture.h` from
  [xWalkLibrary Common](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md).

## 8. Safety and constraints

- The default Pi pipeline drops stale frames (`appsink drop=true max-buffers=1`).
- There is no added hard timeout around OpenCV capture; a blocked read delays the session.
- File inputs are host-only; no fallback source opens silently. Pi CSI capture has not been run as part of host
  verification.

## 9. Related notes

- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkInput](../xWalkInput/xWalkInput.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkCameraSvc/xWalkCameraSvc.md) · [Chapter index](../../../index.md) · [Next page](../xWalkConfig/xWalkConfig.md)
