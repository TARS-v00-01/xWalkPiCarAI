<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) /
xWalkVoiceActiveCar Configuration

**2. xWalk hardware &middot; Module 43**

<!-- xwalk-page-header:end -->

# xWalkVoiceActiveCar Configuration

The `config` directory of `xWalkVoiceActiveCar` holds the deterministic host image used by the Rolly
voice-active-car sequence during device-free verification.

## 1. Overview

`voice-active-car.jpg` is the deterministic host image used by the Rolly voice-active-car sequence. It is
copied from the upstream Robot HAT camera documentation asset at `robot-hat/docs/source/img/camera.jpg`.

Host verification reads the JPEG from the configured directory and validates its file signature before using
the path. Raspberry Pi captures remain writable and continue to use the deployment-controlled `camera_output`
path; this directory is never a capture destination.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVoice/xWalkVoiceActiveCar/config` -
source directory

## 3. Directory layout

```text
config/
    voice-active-car.jpg        Deterministic JPEG used by the host test
```

## 4. Configuration

CMake exposes this directory through the cache path `XWALK_VOICE_ACTIVE_CAR_CONFIG_DIRECTORY`, which defaults
to `<module>/config`. Configuration fails with a fatal error when the directory does not exist or does not
contain `voice-active-car.jpg`. The host test receives the directory as the compile definition
`XWALK_VOICE_ACTIVE_CAR_CONFIG_DIRECTORY`.

## 5. Testing

`xWalkVoiceActiveCarHostTest` (label `host`) checks that the configured image is a readable regular file whose
first three bytes are the JPEG signature `0xFF 0xD8 0xFF`. Build and run steps are described in
[xWalkVoiceActiveCar](../xWalkVoiceActiveCar.md).

## 6. Safety and constraints

- Keep the tracked image in this directory; tests must not depend on files under `/tmp`.
- Overriding `XWALK_VOICE_ACTIVE_CAR_CONFIG_DIRECTORY` requires a directory that contains a valid
  `voice-active-car.jpg`.

## 7. Related notes

- [xWalkVoiceActiveCar](../xWalkVoiceActiveCar.md) - owning voice-active-car module.
- [xWalkCameraCapture](../../../xWalkVision/xWalkCameraCapture/xWalkCameraCapture.md) - physical still-image
  capture on the Raspberry Pi.

---

[Previous page](../xWalkVoiceActiveCar.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkVoiceActiveCarGpt/xWalkVoiceActiveCarGpt.md)
