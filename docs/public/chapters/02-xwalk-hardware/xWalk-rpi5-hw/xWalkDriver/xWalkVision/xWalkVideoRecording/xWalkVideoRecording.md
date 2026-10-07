<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVideoRecording

**2. xWalk hardware &middot; Module 33**

<!-- xwalk-page-header:end -->

# xWalkVideoRecording

`xWalkVideoRecording` ports upstream `example/9.record_video.py` into a callback-driven Agent with an optional
OpenCV recording provider. Camera and encoder ownership remain with the provider.

## 1. Overview

The Agent keeps the upstream behavior:

- an 800-millisecond warm-up after the camera starts;
- `Q` (or `q`) start, pause, and continue transitions;
- `E` (or `e`) stop of an active or paused recording, returning the recorded path;
- timestamped AVI naming, using local time in the form `YYYY-MM-DD-HH.MM.SS`;
- a 100-millisecond delay after every key.

The Agent tracks the `Stopped`, `Recording`, and `Paused` states and reports `Ignored`, `Started`, `Paused`,
`Continued`, `Stopped`, or `Cancelled` events. A cancelled post-key delay reports `Cancelled`.

The optional OpenCV provider accepts the same configured V4L2, GStreamer, video-file, image-sequence, and
automatic source families as computer vision. It validates source type, absolute path requirements, pipeline
line breaks, resolution, frame rate, a 1 through 60000 millisecond best-effort read timeout, and output directory
before opening resources. It writes MJPEG-encoded AVI files from a capture worker thread. Finite
video/image-sequence exhaustion is retained separately from live-camera failure. This provides recorded-video
testing without treating it as CSI-camera verification.

OpenCV timeout and cancellation support varies by backend. FFmpeg and GStreamer may honor the requested timeout;
a V4L2 driver can still block inside `VideoCapture::read()`. The current provider joins its worker during
shutdown, so bounded V4L2 shutdown remains a Raspberry Pi 5 verification item and is not claimed from x86
recorded-media results.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkVideoRecording` (source
directory,
CMakeLists.txt)

## 3. Directory layout

```text
xWalkVideoRecording/
    CMakeLists.txt                                         Libraries, options, and tests
    include/
        xAgent_Rpi5CarVideoRecordingTypes.h                State, event, callback, and result contracts
        xAgent_Rpi5CarVideoRecording.h                     Public recording coordinator
    src/
        xAgent_Rpi5CarVideoRecording.cpp                   Key handling and state transitions
        xAgent_Rpi5CarVideoRecordingLifecycle.cpp          Validation, warm-up, cancellable delay, and stop
    test/
        include/xAgent_Rpi5CarVideoRecordingTestTypes.h    In-memory callback state for the host test
        src/xAgent_Rpi5CarVideoRecordingTest.cpp           Portable host test with in-memory callbacks
    hardware/
        include/xAgent_Rpi5CarVideoRecordingOpenCv.h       OpenCV provider and its configuration
        src/xAgent_Rpi5CarVideoRecordingOpenCv.cpp         Capture worker, AVI writer, and timestamp source
        test/include/...OpenCvTestSupport.h                Recorded-media test support declarations
        test/src/...OpenCvTestSupport.cpp                  Recorded-media test support implementation
        test/src/...OpenCvHostTest.cpp                     OpenCV host test on a generated MJPEG AVI
        test/src/...HardwareTest.cpp                       Opt-in physical-camera recording test
```

## 4. Public interface

Public headers are in the module
`include` directory; the
provider header is in
`hardware/include`.

- `xAgent_Rpi5CarVideoRecording.h` declares the non-copyable, non-movable
  `xwalk::agent::XWalkVideoRecording`, constructed from a non-owning callback context and an
  `XWalkVideoRecordingCallbacks` table. Members are `start()`, `handleKey(keyText)`, `stop() noexcept`,
  `state()`, and `started()`. `handleKey()` throws a logic error before `start()` and a runtime error when the
  timestamp or the returned recording path is empty.
- `xAgent_Rpi5CarVideoRecordingTypes.h` defines the state and event enumerations, the callback aliases, and
  `XWalkVideoRecordingResult`. Every callback (`startCamera`, `stopCamera`, `beginRecording`, `pauseRecording`,
  `continueRecording`, `stopRecording`, `delay`, `continueOperation`, `timestamp`) is required.
- `xAgent_Rpi5CarVideoRecordingOpenCv.h` declares `XWalkVideoRecordingOpenCv`, whose `callbacks()` table binds
  the Agent to the provider, and `backendFromString()`, which accepts `v4l2`, `gstreamer`, `video_file`,
  `image_sequence`, and `automatic`. The provider owns its shared video capture, AVI writer, and capture thread.

## 5. Build

| Target | Alias | Notes |
| --- | --- | --- |
| `xWalkVideoRecording` | `xWalk::VideoRecording` | Portable static library; links `xWalkLibraryCommon` |
| `xWalkVideoRecordingOpenCv` | `xWalk::VideoRecordingOpenCv` | Requires OpenCV 4 `core`, `imgcodecs`, `videoio` |

| CMake option | Default | Purpose |
| --- | --- | --- |
| `XWALK_VIDEO_RECORDING_BUILD_HOST_TESTS` | `OFF` | Build the host tests |
| `XWALK_VIDEO_RECORDING_BUILD_OPENCV_BACKEND` | `OFF` | Build the OpenCV provider |
| `XWALK_VIDEO_RECORDING_BUILD_HARDWARE_TESTS` | `OFF` | Build the opt-in physical-camera test |

Hardware tests require the OpenCV backend; configuration fails otherwise. In the workspace build,
`xWalkDriver` sets the host-test option from `XWALK_AGENT_BUILD_HOST`, the hardware-test option from
`XWALK_AGENT_BUILD_RPI`, and the OpenCV backend option when either is enabled or `XWALK_BUILD_ALL_BACKENDS` is set.

## 6. Configuration

`XWalkVideoRecordingOpenCvConfiguration` is validated before any resource opens:

| Field | Default | Valid range |
| --- | --- | --- |
| `cameraBackend` | `V4l2` | one of the five source families |
| `cameraDevice` | empty | non-empty; absolute for path sources; no line breaks |
| `videoDirectory` | `/tmp/xwalk-videos` | non-empty absolute path |
| `widthPixels` | 640 | 16 to 7680 pixels |
| `heightPixels` | 480 | 16 to 4320 pixels |
| `framesPerSecond` | 20.0 | finite, 1 to 120 frames per second |
| `readTimeoutMilliseconds` | 1000 | 1 to 60000 milliseconds |

## 7. Testing

| CTest name | Labels | Scope |
| --- | --- | --- |
| `xWalkVideoRecordingHostTest` | `host` | Agent state machine with in-memory callbacks |
| `xWalkVideoRecordingOpenCvHostTest` | `host;camera;recorded-media` | OpenCV provider on recorded media |
| `xWalkVideoRecordingHardwareTest` | `hardware;camera;recording` | Physical camera recording |

The portable host test uses only in-memory callbacks. The OpenCV host test programmatically generates a small
MJPEG AVI, opens it as finite input, checks missing-source and configuration failures, and verifies idempotent
shutdown without opening a camera device. The vision group test `xWalkDriverVisionGroupHostTest` also runs the
module host test. From the repository root:

```bash
cmake -S xWalk-rpi5-hw --preset host-debug
```

```bash
cmake --build build-host/cmake --target xWalkVideoRecordingTest xWalkVideoRecordingOpenCvHostTest
```

```bash
ctest --test-dir build-host/cmake -R xWalkVideoRecording --output-on-failure
```

The hardware-labelled test records approximately one second from `/dev/video0` into
`/tmp/xwalk-video-recording-hardware-test`. Build discovery with `ctest -N -L hardware` is safe, but run it only
with explicit approval after confirming the correct Raspberry Pi and camera setup, destination, privacy, and disk
capacity. Ordinary host verification never executes it.

## 8. Dependencies

- `xWalkLibraryCommon` for shared types and `hal::XWalkSharedVideoCapture`;
- OpenCV 4 and `Threads::Threads` for the optional provider;
- `xWalkTrace` for trace and error reporting;
- GoogleTest for the OpenCV host test.

## 9. Safety and constraints

- Recordings can capture people and surroundings; confirm privacy before recording on a device.
- Output files accumulate in the configured directory; confirm disk capacity.
- Bounded V4L2 shutdown is not verified on Raspberry Pi 5.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkComputerVision](../xWalkComputerVision/xWalkComputerVision.md)
- [xWalkVision Test Assets](../test/assets/xWalkVision%20Test%20Assets.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkVideoCar/xWalkVideoCar.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkVideoStreaming/xWalkVideoStreaming.md)
