<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkInput

**5. xWalk node &middot; Module 23**

<!-- xwalk-page-header:end -->

# xWalkInput

`xWalkInput` holds the traffic controller's default local evaluation input, the `xWalkTrafficTest.mp4` clip used
by host replay and by the camera-service host tests.

## 1. Overview

`xWalkTrafficTest.mp4` is copied unchanged from the model repository's
`xWalkModelResources/xWalkInput/xWalkTrafficVideos/videos/12165308_uhd_3840_2160_30fps/`
`12165308_uhd_3840_2160_30fps_s00000000.mp4`. It is a functional test clip, not an independently labelled
accuracy benchmark.

The path is configured as `host.video` in `../xWalkConfig/xWalkTrafCtrl.conf` and resolves relative to that
configuration file. The Pi CPU overlay `xWalkRpi5Cpu.conf` also expects deployment model exports in
`xWalkInput/xWalkModel/` (`best.onnx` and `crosswalk-safety.json`); those trained files are not tracked here.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkInput` -
source directory

## 3. Directory layout

```text
xWalkInput/
    xWalkTrafficTest.mp4    Default host evaluation clip
    xWalkModel/             Optional, untracked deployment copy of the trained exports for Pi CPU builds
```

## 4. Configuration

For local evaluation without MQTT risk or announcement broadcasts, run from the `xWalkTrafCtrl` directory:

```bash
./build-host/xWalkTrafCtrl --host
```

The native trained model exports and the local Ollama service must be available. Override the clip with
`--video` or its alias `--vedio`. Pi mode continues to use its camera.

## 5. Testing

`xWalkConfigurationGoogleTest` verifies that host mode selects this clip automatically, and `xWalkCameraIpcTest`
uses it as the host producer source.

## 6. Related notes

- [xWalkConfig](../xWalkConfig/xWalkConfig.md)
- [xWalkCapture](../xWalkCapture/xWalkCapture.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkConfiguration/xWalkConfiguration.md) · [Chapter index](../../../index.md) · [Next page](../xWalkModel/xWalkModel.md)
