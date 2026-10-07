<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkComputerVision

**2. xWalk hardware &middot; Module 28**

<!-- xwalk-page-header:end -->

# xWalkComputerVision

`xWalkComputerVision` ports the interactive behavior of `example/7.computer_vision.py` into a C++17 Agent
submodule. The portable Agent owns detector state and key mapping while caller-owned callbacks provide camera
acquisition, color and face detection, QR decoding, photograph storage, timing, and cancellation.

## 1. Overview

The module has two layers:

- `XWalkComputerVision`, a backend-neutral key-driven state machine that owns no camera or provider resource; and
- `XWalkComputerVisionOpenCv`, an optional OpenCV provider that implements the callback table with one Linux
  camera stream.

The callback types defined here are also consumed by `xWalkFaceTracking` and `xWalkBullFight`.

### Key behavior

Keys are case-insensitive:

- `q` captures a timestamped JPEG photograph;
- `1` through `6` select red, orange, yellow, green, blue, or purple detection;
- `0` disables color detection;
- `f` toggles frontal-face detection;
- `r` toggles QR decoding and reports newly changed non-empty QR text;
- `s` reports enabled color and face detector geometry;
- every key preserves the source's 500-millisecond delay using cancellable slices no longer than 20 milliseconds.

`start()` starts the provider with all detectors disabled. `handleKey()` throws a logic error before a successful
start. `stop()` disables detectors and stops the provider; the destructor stops an active provider.

### OpenCV provider

The OpenCV provider selects a configured V4L2 device, GStreamer pipeline, video file, image sequence, or automatic
OpenCV source. It uses HSV segmentation for source-compatible color selection, uses a configured Haar cascade for
frontal faces, and uses OpenCV QR decoding. Unlike Vilib's web display, this provider does not start a network
listener; the CLI reports detection results explicitly and stores requested JPEG files locally as
`photo_<YYYY-mm-dd-HH-MM-SS>.jpg` in the photo directory.

The source is never implicitly fixed to `/dev/video0`. Device, video, image-sequence, photo-directory, and cascade
paths must be absolute; source strings reject carriage returns and line feeds; dimensions must be in range; and
finite video end-of-file is distinguished from live-camera failure. A validated 1 through 60000 millisecond read
timeout is requested from OpenCV, although support depends on the selected OpenCV backend. Recorded MJPEG video
exercises acquisition on x86 without a camera. The `libcamera`/`rpicam` CSI path remains an unverified integration
route, normally through a reviewed GStreamer pipeline; no shell command is constructed.

OpenCV's FFmpeg and GStreamer adapters commonly honor the timeout property; V4L2 support is backend and driver
dependent. This repository therefore does not yet claim that every live V4L2 read is forcibly cancellable. That
limitation must be verified on Raspberry Pi 5, and safety logic must treat acquisition failure or timeout as a stop
condition.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkComputerVision`
(source directory)

## 3. Directory layout

```text
xWalkComputerVision/
    CMakeLists.txt                                           Core, OpenCV provider, and test targets
    include/
        xAgent_Rpi5CarComputerVision.h                       Interactive state-machine contract
        xAgent_Rpi5CarComputerVisionTypes.h                  Colors, results, observations, and callbacks
    src/
        xAgent_Rpi5CarComputerVision.cpp                     Key mapping, observations, and QR change tracking
        xAgent_Rpi5CarComputerVisionLifecycle.cpp            Validation, lifecycle, and bounded timing
    hardware/
        include/
            xAgent_Rpi5CarComputerVisionOpenCv.h             OpenCV provider contract
        src/
            xAgent_Rpi5CarComputerVisionOpenCv.cpp           Linux camera and detector implementation
        test/
            include/
                xAgent_Rpi5CarComputerVisionOpenCvTestSupport.h  Recorded-media test support
            src/
                xAgent_Rpi5CarComputerVisionOpenCvTest.cpp   Recorded-media backend and failure tests
                xAgent_Rpi5CarComputerVisionOpenCvTestSupport.cpp  Test-support implementation
                xAgent_Rpi5CarComputerVisionHardwareTest.cpp Opt-in physical-camera verification
    test/
        include/
            xAgent_Rpi5CarComputerVisionTestTypes.h          Callback-driven test state
        src/
            xAgent_Rpi5CarComputerVisionTest.cpp             Deterministic callback-driven host test
```

## 4. Public interface

Core headers `xAgent_Rpi5CarComputerVision.h` and `xAgent_Rpi5CarComputerVisionTypes.h` are in
`include`.
The provider header `xAgent_Rpi5CarComputerVisionOpenCv.h` is in
`hardware/include`.

| Member | Behavior |
| --- | --- |
| `XWalkComputerVision(context, callbacks)` | Binds a complete callback table; any null entry throws |
| `start()` | Starts the provider and resets every retained detector mode |
| `handleKey(keyText)` | Applies one key and returns `XWalkComputerVisionResult` |
| `stop()` | Disables detectors and stops the provider without throwing |
| `colorName(color)` | Returns the lowercase upstream color name |
| `XWalkComputerVisionOpenCv(configuration)` | Validates settings and loads the face cascade |
| `XWalkComputerVisionOpenCv::callbacks()` | Returns provider callbacks without `delay` and `continueOperation` |
| `XWalkComputerVisionOpenCv::backendFromString(name)` | Parses a deployment backend name |

`XWalkComputerVisionCallbacks` contains `start`, `stop`, `capture`, `setColor`, `setFace`, `setQr`, `observe`,
`delay`, and `continueOperation`. The callback context is non-owning and must outlive the Agent. Detections report
the object count, center coordinates, and bounding-rectangle size in camera pixels. Neither class is copyable or
movable.

## 5. Build

| Target | Alias | Notes |
| --- | --- | --- |
| `xWalkComputerVision` | `xWalk::ComputerVision` | Core static library; links `xWalkLibraryCommon`, `xWalkTrace` |
| `xWalkComputerVisionOpenCv` | `xWalk::ComputerVisionOpenCv` | OpenCV 4 provider |

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_COMPUTER_VISION_BUILD_HOST_TESTS` | `OFF` | Builds the core test and, with the provider, the media test |
| `XWALK_COMPUTER_VISION_BUILD_OPENCV_BACKEND` | `OFF` | Builds the OpenCV provider |
| `XWALK_COMPUTER_VISION_BUILD_HARDWARE_TESTS` | `OFF` | Builds the physical-camera test; requires the provider |

The provider uses the OpenCV `core`, `imgcodecs`, `imgproc`, `objdetect`, and `videoio` components.
Configuration fails when hardware tests are requested without the OpenCV backend. The xWalkDriver workspace build
enables the provider for host, Raspberry Pi, or all-backend builds and sets the host and hardware test options from
`XWALK_AGENT_BUILD_HOST` and `XWALK_AGENT_BUILD_RPI`.

## 6. Configuration

`XWalkComputerVisionOpenCvConfiguration` fields:

| Field | Default | Constraint |
| --- | --- | --- |
| `cameraBackend` | `V4l2` | `v4l2`, `gstreamer`, `video_file`, `image_sequence`, or `automatic` |
| `cameraDevice` | empty | Required; absolute for V4L2, video, and image-sequence sources; no CR or LF |
| `photoDirectory` | `/tmp/xwalk-pictures` | Required and absolute; created when needed |
| `faceCascadePath` | OpenCV frontal-face cascade | Absolute; empty disables face detection |
| `widthPixels` | 640 | 16 through 7680 pixels |
| `heightPixels` | 480 | 16 through 4320 pixels |
| `readTimeoutMilliseconds` | 1000 | 1 through 60000 milliseconds, best effort |

The default cascade is `/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml`.

An unsupported backend name throws an invalid-argument error. A configured cascade that cannot be loaded throws a
runtime error. Reading past the end of a video file or image sequence throws a range error; a live-camera read
failure throws a runtime error.

## 7. Testing

| CTest name | Labels | Coverage |
| --- | --- | --- |
| `xWalkComputerVisionHostTest` | `host` | Deterministic callback-driven state machine |
| `xWalkComputerVisionOpenCvHostTest` | `host;camera;recorded-media` | Backends, limits, detectors, capture, EOF |
| `xWalkComputerVisionHardwareTest` | `hardware;camera` | Live `/dev/video0` frames and one temporary JPEG |

The recorded-media test uses no camera hardware and writes photographs to an isolated directory. From a configured
workspace host build:

```bash
ctest --test-dir build-host/cmake -R xWalkComputerVision --output-on-failure
```

The hardware test opens `/dev/video0`, loads
`/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml`, processes live frames, writes one temporary
JPEG under `/tmp/xwalk-computer-vision-hardware-test`, and removes that file after verification. Discover it with
`ctest -N -L hardware`; run it only with explicit approval, a confirmed safe Raspberry Pi and Robot HAT setup, and
confirmed camera placement, consent, and storage safety.

## 8. Dependencies

- `xWalkLibraryCommon`: shared Agent types and `xHal_Rpi5CarSharedVideoCapture.h`.
- `xWalkTrace`: provider-start trace `RPIAGENT.021`.
- OpenCV 4 for the provider; GoogleTest for the recorded-media test.

## 9. Safety and constraints

Camera capture can record people, QR contents, and private surroundings. Use it only with authorization, keep the
camera indicator and storage destination visible, and protect or remove saved images according to local policy.
Hardware tests remain opt-in and must not run during ordinary host verification.

- Acquisition failure or timeout must be treated as a stop condition by any motion-controlling consumer.
- Calls are synchronous; the owner must serialize key handling, start, and stop.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkFaceTracking](../xWalkFaceTracking/xWalkFaceTracking.md)
- [xWalkBullFight](../xWalkBullFight/xWalkBullFight.md)
- [xWalkCamera](../../../xWalkHal/device/xWalkCamera/xWalkCamera.md)
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkCameraCapture/xWalkCameraCapture.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkFaceTracking/xWalkFaceTracking.md)
