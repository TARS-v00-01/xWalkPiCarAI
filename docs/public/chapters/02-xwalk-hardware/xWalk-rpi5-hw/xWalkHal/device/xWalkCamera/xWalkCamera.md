<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkCamera

**2. xWalk hardware &middot; Module 56**

<!-- xwalk-page-header:end -->

# xWalkCamera

`xWalkCamera` provides bounded synchronous JPEG capture and encoded live-frame capture through a device-free
core and optional Linux backends.

## 1. Overview

The core stores a non-owning callback context, validates width, height, timeout, and destination path, and owns
no camera, process, or filesystem resource. `capture()` treats a backend failure as a required-operation error,
while `tryCapture()` returns `false` for callers that explicitly permit no image.

The optional `XWalkCameraLinux` still-capture backend supports two deployment-selected connections:

| Connection | Linux provider | Default device |
|---|---|---|
| `csi` | `rpicam-still` for the Raspberry Pi Camera Serial Interface | Camera selected by rpicam |
| `usb` | `ffmpeg` using Video4Linux2 | `/dev/video0` |

CSI is the Raspberry Pi camera connector. DSI is the display connector and is not used for camera capture. Both
providers are executed directly without a shell. A successful operation must create a regular output file from
four bytes through 32 MiB.

`XWalkCameraStream` validates and forwards camera start, stop, and JPEG-frame capture through caller-owned
callbacks. The optional `XWalkCameraStreamOpenCv` backend accepts either `v4l2` with an exact `/dev/videoN`
source for an ordinary USB camera, or `libcamera` with the exact source `csi` for a Raspberry Pi CSI camera. It
owns the camera handle while Agent owns MJPEG transport policy.

The `libcamera` selection constructs this pipeline internally from the already bounded numeric width and height
settings. The single-line pipeline is shown here split at its `!` separators:

```text
libcamerasrc
! video/x-raw,format=NV12,width=<width>,height=<height>
! videoconvert
! video/x-raw,format=BGR
! appsink drop=true max-buffers=1 sync=false
```

Configuration cannot supply GStreamer elements or pipeline text. The explicit NV12 source caps select an
ISP-processed video stream instead of a raw Bayer stream. V4L2 streaming remains independent of libcamera.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkCamera`

Source directory

## 3. Directory layout

```text
xWalkCamera/
├── CMakeLists.txt                                   Core, backend, host-test, and hardware-test targets
├── core/
│   ├── include/
│   │   ├── xHal_Rpi5CarCamera.h                     XWalkCamera still-capture API
│   │   ├── xHal_Rpi5CarCameraStream.h               XWalkCameraStream encoded-frame API
│   │   └── xHal_Rpi5CarCameraTypes.h                Connection enumeration, settings, capture callback
│   └── src/
│       ├── xHal_Rpi5CarCamera.cpp                   Still-capture validation and forwarding
│       └── xHal_Rpi5CarCameraStream.cpp             Stream validation and forwarding
├── hardware/
│   ├── include/
│   │   ├── xHal_Rpi5CarCameraLinux.h                rpicam-still and ffmpeg still-capture backend
│   │   └── xHal_Rpi5CarCameraStreamOpenCv.h         OpenCV V4L2 and libcamera streaming backend
│   ├── src/
│   │   ├── xHal_Rpi5CarCameraLinux.cpp              Process launch, timeout, and output validation
│   │   └── xHal_Rpi5CarCameraStreamOpenCv.cpp       OpenCV capture, pipeline, and JPEG encoding
│   └── test/src/xHal_Rpi5CarCameraHardwareTest.cpp  Opt-in physical still capture
├── simulation/                                      Standalone host simulation with an in-memory capture callback
└── test/
    ├── include/xHal_Rpi5CarCameraTestSupport.h      xwalk::hal::test::camera callback declarations
    └── src/
        ├── xHal_Rpi5CarCameraTest.cpp               Capture, validation, stream, OpenCV, and trace tests
        └── xHal_Rpi5CarCameraTestSupport.cpp        Reusable callback state
```

## 4. Child modules

- [xWalkCamera Simulation](simulation/xWalkCamera%20Simulation.md) - standalone host simulation and trace
  selection.

## 5. Public interface

Core headers live in `core/include`
and backend headers in
`hardware/include`.

| Type | Contract |
|---|---|
| `XWalkCameraConfiguration` | Width 16-7680 px, height 16-4320 px, timeout 1-300,000 ms |
| `XWalkCamera` | `capture(outputPath)` returns the path or throws; `tryCapture(outputPath)` returns `false` |
| `XWalkCamera::connectionFromString` | Converts `csi` or `usb` to `XWalkCameraConnection` |
| `XWalkCameraStreamConfiguration` | Backend, source, size, JPEG quality 1-100, read timeout 1-60,000 ms |
| `XWalkCameraStream` | `start()`, `capture(bytevector&)`, `stop()`, and `started()` |
| `XWalkCameraLinux` | Connection, executable, and USB device; exposes a capture `callback()` |
| `XWalkCameraStreamOpenCv` | Production or injected OpenCV operations; exposes stream `callbacks()` |

Defaults: still capture 640 x 480 pixels with a 5000 ms timeout; streaming `v4l2` on `/dev/video0` at 640 x 480
pixels, JPEG quality 80, and a 1000 ms read timeout. Every class is neither copyable nor movable.

## 6. Build

| Target | Alias | Built when |
|---|---|---|
| `xWalkCamera` | `xWalk::Camera` | Always; static core library |
| `xWalkCameraStreamOpenCv` | `xWalk::CameraStreamOpenCv` | OpenCV backend or host tests enabled |
| `xWalkCameraLinux` | `xWalk::CameraLinux` | Linux backend or hardware tests enabled |

| CMake option or cache variable | Default | Effect |
|---|---|---|
| `XWALK_CAMERA_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkCameraTest`; requires OpenCV |
| `XWALK_CAMERA_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkCameraHardwareTest`; requires Linux |
| `XWALK_CAMERA_BUILD_LINUX_BACKEND` | `OFF` | Builds `xWalkCameraLinux`; requires Linux |
| `XWALK_CAMERA_BUILD_OPENCV_BACKEND` | `OFF` | Builds `xWalkCameraStreamOpenCv`; requires Linux and OpenCV |
| `XWALK_CAMERA_HARDWARE_CONNECTION` | `usb` | Connection passed to the hardware test |
| `XWALK_CAMERA_HARDWARE_EXECUTABLE` | `ffmpeg` | Capture executable passed to the hardware test |
| `XWALK_CAMERA_HARDWARE_DEVICE` | `/dev/video0` | USB V4L2 device passed to the hardware test |
| `XWALK_CAMERA_HARDWARE_OUTPUT` | `/tmp/xwalk-camera-hardware-test.jpg` | JPEG destination of the hardware test |

The OpenCV backend requires the OpenCV `core`, `imgcodecs`, and `videoio` components.

## 7. Configuration

Host tests generate `generated/xWalkCameraTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarCameraTraceConfig.py`, preserving previously stored trace states. The hardware test
reads its connection, executable, device, and output path from the cache variables listed under Build.

## 8. Testing

Host verification:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkCamera -B xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-host -DXWALK_CAMERA_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-host --output-on-failure
```

The CTest `xWalkCameraHostTest` has label `host`. It covers capture, validation, streaming, the OpenCV stream
backend through injected operations, and persistent trace-selector behavior. Reusable callback state lives in
`xwalk::hal::test::camera`.

Raspberry Pi verification: install `rpicam-apps` for CSI still capture or `ffmpeg` for USB still capture. CSI
streaming additionally requires OpenCV GStreamer support and the GStreamer `libcamerasrc` and `videoconvert`
plugins. Configure the selected hardware test, compile it, and list it before any approved physical execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkCamera -B xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-rpi -DXWALK_CAMERA_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkCamera/build-rpi -N -L hardware
```

The listed test is `xWalkCameraStillHardwareTest` with label `hardware`.

## 9. Dependencies

- `xWalkLibraryCommon` - fixed-width types, source-string helpers, and the shared video-capture lease.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.
- OpenCV `core`, `imgcodecs`, and `videoio` for the streaming backend and host tests.
- Runtime providers: `rpicam-still` (CSI), `ffmpeg` (USB), and GStreamer `libcamerasrc` for CSI streaming.

## 10. Safety and constraints

- The caller owns the backend context, which must outlive every `XWalkCamera` or `XWalkCameraStream` using it.
- Providers run without a shell, and configuration cannot inject GStreamer pipeline text.
- Hardware tests open a physical camera and write the configured output file. Run them only with explicit
  approval on a confirmed safe Raspberry Pi setup.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkAdxl345/simulation/xWalkAdxl345%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkCamera%20Simulation.md)
