<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkConfig

**5. xWalk node &middot; Module 21**

<!-- xwalk-page-header:end -->

# xWalkConfig

`xWalkConfig` holds the traffic controller's tracked runtime configuration: the default JSON profile, the host
test and Raspberry Pi CPU overlays, the MQTT connection file, the generated build-header template and the
command-line help text.

## 1. Overview

`xWalkTrafCtrl.conf` is loaded automatically from this directory, regardless of the working directory. The
`.conf` filename follows the other modules; its contents remain structured JSON. `--config FILE` merges a partial
deployment file; explicit command-line options then take precedence. Relative paths resolve against the file
containing them. The directory is located through the CMake cache entry `XWALK_TRAFCTRL_CONFIG_DIR`, which is
written into the generated `xWalkBuildConfig.h`.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkConfig` -
source directory

## 3. Directory layout

```text
xWalkConfig/
    xWalkTrafCtrl.conf        Default JSON configuration, loaded automatically
    xWalkHostTest.conf        Host-only overlay: MQTT disabled, every frame sampled
    xWalkRpi5Cpu.conf         Pi CPU overlay: local model exports, CPU device, speech settings
    xWalkMqttClient.conf      MQTT connection file: broker, client ID and CA bundle; no credentials
    xWalkBuildConfig.h.in     Template for the generated build-mode and path header
    xWalkTrafficHelp.json     Command-line help, copied to <build>/config and installed to share/xwalk/help
```

## 4. Configuration

Defaults in `xWalkTrafCtrl.conf`:

| Setting | Default and purpose |
| --- | --- |
| `host.video` | `../xWalkInput/xWalkTrafficTest.mp4`: bundled local evaluation clip; override with `--video` |
| `host.evaluation_output`, `rpi5.evaluation_output` | Empty: optional JSONL evaluation output is disabled |
| `rpi5.camera_pipeline` | libcamera/GStreamer NV12-to-BGR, 640 x 480 at 30 FPS, stale frames dropped |
| `model.model_root` | Sibling model repository `xWalkPiCarApp/xWalk-pcx86-model`, relative to this file |
| `model.weights`, `model.rf_model` | Empty: derived from `model_root` (see below) |
| `model.input_size`, `device`, `confidence` | 640, `auto`, 0.25 |
| `hailo` | `multi_process_service` true, `group_id` `xwalk`, `timeout_ms` 10000; Pi Hailo detector only |
| `llm` | `http://127.0.0.1:11434/api/chat`, model `llama3.2:3b`, `llm_timeout_ms` 180000 |
| `runtime` | `frame_stride` 30, `max_frames` 0 (unlimited), `announcement_interval` 15.0 seconds |
| `trace.trace` | `TRAFCTRL.enable`; trace filtering does not control MQTT publication |
| `mqtt.enabled` | True: publish generated advisories. False keeps local trace output |
| `mqtt.client_address` | `auto`: shared node interface detection; `XWALK_SERVER_IP` overrides detection |
| `mqtt.server_ip` | `0.0.0.0`: broadcast announcements to all connected nodes |
| `mqtt.mailbox`, `local_index`, `module_type` | Sender protocol identity: 1, 1, 0 |

Empty `weights` and `rf_model` resolve to `best.onnx` (or `best.hef` in a Hailo build) and `crosswalk-safety.json`
under `<model_root>/xWalkModelResources/xWalkOutput/xWalkNetworkWeights`. `device: auto` selects host CUDA, then
OpenCL GPU, then CPU; in a Pi build it resolves to `cpu`, or to `hailo8` when Hailo is enabled. The input size must
be a multiple of 32 between 32 and 4096 and must match the selected export. `confidence` must be greater than 0
and at most 1. `llm_timeout_ms` accepts 1 to 600000 milliseconds.

`xWalkHostTest.conf` loads
automatically in host mode, disables MQTT and samples every frame of the local video. Pi mode skips this file and
uses the CSI camera pipeline from `xWalkTrafCtrl.conf`. `--host` and `--rpi5` must match the CMake build mode;
omitting them uses the build mode automatically.

`xWalkRpi5Cpu.conf` is the tracked
Pi CPU overlay used by `run-xwalk-traffic`. It reads `best.onnx` and `crosswalk-safety.json` from
`../xWalkInput/xWalkModel`, forces the `cpu` device and selects local speech. Local speech uses
`rpi5.speech_executable`, `speech_voice`, `playback_device`, `mixer_device` and `mixer_element`; values must be
nonempty. The built-in defaults are `espeak-ng`, `en`, `default`, `default` and `PCM`; the CPU overlay selects
Espeak English with `default` PCM, `pulse` mixer and `Master` volume control. Preserve operator-specific overrides.

`xWalkMqttClient.conf` contains the existing broker hostname, CA bundle and dedicated client ID
`xwalk-traffic-controller`. Both CMake presets select this file. The shared MQTT transport appends a random
client-ID suffix to prevent concurrent processes from disconnecting each other. Credentials stay in
`HIVEMQ_NETRC_FILE` or the user's `.netrc`; they are not copied into repository files.
`XWALK_TRAFCTRL_MQTT_CONFIG_FILE` overrides the traffic connection file; an inherited IoT `HIVEMQ_CONFIG_FILE` is
ignored. `XWALK_TRAFCTRL_NETRC_FILE` selects dedicated credentials when needed. No broker connection is made while
loading configuration or running host unit tests.

`xWalkBuildConfig.h.in` is
configured into `<build>/auto-gen/include/xWalkBuildConfig.h`. It declares `MqttConfig`, `HailoEnabled`,
`BuildMode`, `HostConfig`, `DefaultConfig`, `TraceConfig` (`<runtime build dir>/generated/xwalk-traces.xml`) and
`TraceLog` (`<runtime build dir>/log/xwalk-traffic.log`).

## 5. Safety and constraints

- The video, trained exports, Ollama model and service, and MQTT credentials are external deployment inputs; this
  configuration does not download or create them.
- Never add credentials to these files; only the netrc credential contract is tracked. Keep target-local
  overrides outside this directory and restore them after synchronization.
- Unknown fields, invalid types and out-of-range values are rejected at startup.

## 6. Related notes

- [xWalkConfiguration](../xWalkConfiguration/xWalkConfiguration.md)
- [xWalkInput](../xWalkInput/xWalkInput.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkCapture/xWalkCapture.md) · [Chapter index](../../../index.md) · [Next page](../xWalkConfiguration/xWalkConfiguration.md)
