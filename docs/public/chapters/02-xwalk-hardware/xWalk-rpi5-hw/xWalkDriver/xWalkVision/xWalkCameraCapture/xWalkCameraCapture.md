<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkCameraCapture

**2. xWalk hardware &middot; Module 27**

<!-- xwalk-page-header:end -->

# xWalkCameraCapture

`xWalkCameraCapture` adapts one caller-owned `XWalkCamera` and one configured JPEG destination to the image
callback consumed by `XWalkVoiceActiveCar`.

## 1. Overview

The Agent owns no camera, process, device node, or image data. Each synchronous capture overwrites the
deployment-selected destination and returns its path to the language-model pipeline. The voice callback treats
capture as optional: a backend failure emits a warning and returns an empty path so the current request continues
without image input. Direct `capture()` calls remain strict.

`XWalkTextVisionTalk` also holds a non-owning reference to an `XWalkCameraCapture` object.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkCameraCapture`
(source directory)

## 3. Directory layout

```text
xWalkCameraCapture/
    CMakeLists.txt                                      Library, alias, and optional host test
    include/
        xAgent_Rpi5CarCameraCapture.h                   Public strict and optional capture adaptation
    src/
        xAgent_Rpi5CarCameraCapture.cpp                 HAL camera forwarding and voice fallback behavior
    test/
        include/
            xAgent_Rpi5CarCameraCaptureTestSupport.h    Reusable fake-camera test state and callback
        src/
            xAgent_Rpi5CarCameraCaptureTestSupport.cpp  Fake-camera callback implementation
            xAgent_Rpi5CarCameraCaptureTest.cpp         Strict success and optional failure verification
```

## 4. Public interface

Public header `xAgent_Rpi5CarCameraCapture.h` is in
`include`.

| Member | Behavior |
| --- | --- |
| `XWalkCameraCapture(camera, outputPath)` | Binds a camera and destination; an empty path throws |
| `capture()` | Calls `XWalkCamera::capture()`; backend errors propagate; returns the path |
| `captureImage(context)` | Static voice callback; a null context throws invalid argument |

`captureImage()` calls `XWalkCamera::tryCapture()`. On failure it emits a runtime warning and returns an empty
string; on success it returns the configured path. The camera reference is non-owning and must outlive the
object. The output path is copied and owned. The class is neither copyable nor movable.

## 5. Build

The CMake target is `xWalkCameraCapture` with the alias `xWalk::CameraCapture`. It is a C++17 static library that
links `xWalkCamera` publicly and `xWalkTrace` privately. When `xWalkCamera` is not already defined, the module adds
`xWalkHal/device/xWalkCamera`. GCC and Clang builds use `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_CAMERA_CAPTURE_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkCameraCaptureTest` |

The xWalkDriver workspace build sets this option from `XWALK_AGENT_BUILD_HOST`, and the vision group sets it when
`XWALK_AGENT_VISION_BUILD_HOST_TESTS` is enabled.

## 6. Testing

`xWalkCameraCaptureHostTest` (label `host`) uses a fake HAL camera callback. It verifies strict capture, optional
capture success, the empty-path fallback after a backend failure, and the total capture count.

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkCameraCapture -B build-camera-agent -DXWALK_CAMERA_CAPTURE_BUILD_HOST_TESTS=ON
```

```bash
cmake --build build-camera-agent --parallel
```

```bash
ctest --test-dir build-camera-agent --output-on-failure
```

The module has no hardware test. Discover hardware-labelled tests with `ctest -N -L hardware`; run them only with
explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 7. Dependencies

- `xWalkCamera` (HAL): strict `capture()` and optional `tryCapture()` operations.
- `xWalkTrace`: capture-completion trace `RPIAGENT.020`.

## 8. Safety and constraints

- Every capture overwrites the same configured file; consumers must copy an image they need to retain.
- Captured images can contain people and private surroundings. Choose a protected destination and remove images
  according to local policy.
- Captures are synchronous and not internally serialized; the owner must avoid concurrent captures to one object.

## 9. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkCamera](../../../xWalkHal/device/xWalkCamera/xWalkCamera.md)
- [xWalkVoiceActiveCar](../../xWalkVoice/xWalkVoiceActiveCar/xWalkVoiceActiveCar.md)
- [xWalkTextVisionTalk](../../xWalkVoice/xWalkTextVisionTalk/xWalkTextVisionTalk.md)
- [xWalkDriver runtime tracing](../../xWalkDriver.md#runtime-tracing)

---

[Previous page](../xWalkBullFight/xWalkBullFight.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkComputerVision/xWalkComputerVision.md)
