<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkCameraSvc

**5. xWalk node &middot; Module 19**

<!-- xwalk-page-header:end -->

# xWalkCameraSvc

`xWalkCameraSvc` is the C++ camera owner for concurrent traffic and IoT camera consumers. It opens the CSI camera
(or, on a host, a local video) once and publishes JPEG snapshots by atomic rename into a private runtime
directory.

## 1. Overview

Consumers copy a complete frame from an opened inode, independently skip older frames and never hold up capture.
Use tmpfs (`$XDG_RUNTIME_DIR`) to avoid SD-card writes. This is bounded snapshot IPC, not a zero-copy
shared-memory ring.

| Process | Responsibility |
| --- | --- |
| One full IoT subscriber, `--function all` | Controller, motors, servos, sensors and audio |
| Existing eight IoT children | Four functional MQTT request workers and four response workers, with private IPC |
| `xWalkCameraSvc` | Physical camera capture and latest-frame publication |
| `xWalkTrafCtrl` | Detection, risk classification, LLM announcements and broadcast MQTT publication |
| HailoRT multi-process service | Existing Pi accelerator scheduling |

Do not start four independent full IoT subscribers to select individual functions; each would construct a
hardware controller. Pi Boot acquires `/run/lock/xwalk-controller.lock` before device initialization and rejects a
second owner. Host simulations remain independent. Functional Driver operations still execute in threads inside
the controller owner; this service does not move every algorithm into a separate process.

The existing Controller retains operation admission, STOP cancellation, motor deadlines, sensor routing and
announcement playback. A transport-child failure cancels that controller before resources are released. These
software mechanisms do not guarantee a motor stop after the owner itself is killed or the OS hangs.

Shared capture is wired into still-image capture, MJPEG streaming, computer vision, video recording and Pi
traffic inference. Clients use the producer's dimensions. Camera control remains with the producer; consumer
requests do not resize or reconfigure CSI. Keep recording frame rate aligned with producer FPS.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc` -
source directory

## 3. Directory layout

```text
xWalkCameraSvc/
    CMakeLists.txt                              Standalone project, executable and optional host test
    xWalkConfig/xWalkCameraHelp.json            Command-line help text
    xWalkDeploy/xwalk-camera.service.in         Pi systemd user-service template
    xWalkDeploy/shared-camera.conf              User-service drop-in for IoT and traffic consumers
    xWalkMain/main.cpp                          Producer entry point
    xWalkTest/include/xWalkCameraIpcTestSupport.h  Test fixture declarations
    xWalkTest/src/xWalkCameraIpcTest.cpp        Host GoogleTests
    xWalkTest/src/xWalkCameraIpcTestSupport.cpp Test fixture implementation
```

## 4. Public interface

```text
xWalkCameraSvc --host VIDEO ABSOLUTE_FRAME_FILE
xWalkCameraSvc --rpi5 GSTREAMER_PIPELINE ABSOLUTE_FRAME_FILE
```

`--host` reads and paces a local video file; `--rpi5` captures with the supplied GStreamer pipeline. The output
frame path must be absolute. The producer holds a lease on `<frame file>.lock` and, in `--rpi5` mode, on
`/run/lock/xwalk-camera.lock`. It exits at video EOF in host mode. Stop it with Ctrl+C. Help text is defined in
`xWalkCameraHelp.json`,
copied to `<build>/config/` and installed to `share/xwalk/help`.

Consumers select the feed through the `XWALK_CAMERA_FRAME_FILE` environment variable and read it through the
common library's `xHal_Rpi5CarCameraSnapshot.h` and `xHal_Rpi5CarSharedVideoCapture.h` readers.

## 5. Build

This is a standalone CMake project; the `xWalkTrafCtrl` top-level build does not add it. Run from
`xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc`:

```bash
cmake -S . -B build-host -DXWALK_CAMERA_SERVICE_TESTS=ON
```

```bash
cmake --build build-host --parallel 4
```

`XWALK_CAMERA_SERVICE_TESTS` (default OFF) builds the host GoogleTest. Build on the Pi with tests disabled for
deployment. The build generates `<build>/xwalk-camera.service` but neither installs nor starts services.

## 6. Configuration

All camera consumers must run as the same service user and inherit the same absolute `XWALK_CAMERA_FRAME_FILE`.
The camera service needs exclusive access to `/run/lock/xwalk-camera.lock`. If the deployment precreates lock
files as root, give the service user ownership; do not unlink lock files while services are running. The snapshot
directory must be private to that user. Do not use separate filesystem namespaces or separate `PrivateTmp`
directories for participating services.

The generated `xwalk-camera.service` is a Pi user-service template. It selects CSI with a 640 x 480, 30 FPS
`libcamerasrc` pipeline and writes `%t/xwalk-camera/frame.jpg`, even when built on a host; do not start it for host
evaluation. It selects the reviewed `%h/.local/lib/aarch64-linux-gnu` camera libraries and GStreamer plugins,
matching the Node launcher. Override `LD_LIBRARY_PATH` and `GST_PLUGIN_PATH` together if the installed camera
prefix differs; the system libcamera may lack Pi 5 pipeline support.

The companion `shared-camera.conf` is a user-service drop-in for both the IoT and traffic units. It sets their
identical snapshot path and orders them after the camera service. The existing traffic retry policy handles
initial frame readiness; the IoT camera request can be retried if made before the first frame.

For a host-only producer run, create a private output directory and use the provided clip:

```bash
mkdir -m 700 -p /tmp/xwalk-camera-demo
```

```bash
build-host/xWalkCameraSvc --host ../xWalkInput/xWalkTrafficTest.mp4 /tmp/xwalk-camera-demo/frame.jpg
```

A consumer process then uses `XWALK_CAMERA_FRAME_FILE=/tmp/xwalk-camera-demo/frame.jpg`. Traffic `--host`
deliberately keeps its local video path; only its `--rpi5` capture consumes this environment override.

## 7. Testing

```bash
ctest --test-dir build-host --output-on-failure
```

`xWalkCameraIpcTest` (labels `host;gtest;ipc`, 20-second timeout) uses synthetic JPEGs and the traffic module's
local clip. No test opens CSI, GPIO or motor hardware. Tests cover independent readers, stale and missing input,
bounded waits, dead producers, process ownership and kernel lease release, exit cleanup, symlink rejection, host
evaluation ignoring the shared environment, and a real separate video-producer process. Unit tests exercise the
shared reader on the host independently of Hailo hardware.

## 8. Dependencies

- OpenCV `core`, `imgcodecs` and `videoio`; GStreamer support for Pi capture.
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md), added from the repository when the
  `xWalkTrace` target does not exist, and the common library target `xWalkLibraryCommon`.
- GoogleTest for the optional host test.

## 9. Safety and constraints

- Snapshots are at most 8 MiB and expire after two seconds. Stream readers wait at most one second for a new
  publication and fail closed; they never switch to directly opening CSI when the producer fails.
- Direct camera paths also acquire the camera lease, so a consumer missing shared configuration is rejected while
  the camera service owns the device.
- These locks coordinate updated xWalk participants, not arbitrary third-party camera programs. All updated
  components must be deployed together.

## 10. Related notes

- [xWalkTrafCtrl](../xWalkTrafCtrl.md)
- [xWalkCapture](../xWalkCapture/xWalkCapture.md)
- [xWalkLibrary Common](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkAnnouncement/xWalkAnnouncement.md) · [Chapter index](../../../index.md) · [Next page](../xWalkCapture/xWalkCapture.md)
