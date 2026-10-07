<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / Raspberry Pi 5 CSI Camera
Deployment

**5. xWalk node &middot; Module 03**

<!-- xwalk-page-header:end -->

# Raspberry Pi 5 CSI Camera Deployment

`xWalkDeploy/rpi5-csi` holds the reviewed deployment templates for a Raspberry Pi 5 with Robot HAT v4 and a CSI
camera: a configuration fragment with GStreamer camera pipelines and the native `run-xwalk` launcher. These files
were used for the bounded Pi GUI checks.

## 1. Overview

The templates are merged into, or seeded beside, the target's runtime configuration; they are not a complete
runtime directory. The host checkout has no `xWalk-rpi5-node/runtime` directory and no target Alan voice or local
library assets. Keep these templates separate from host configuration and do not copy a complete runtime
directory over a target.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkDeploy/rpi5-csi` —
source directory

## 3. Directory layout

```text
rpi5-csi/
    picar-x.conf.fragment   CSI GStreamer pipelines, recording rate and optional Alan voice setting
    run-xwalk               Native AArch64 launcher seeded as runtime/run-xwalk
```

## 4. Public interface

### Configuration fragment

Review `picar-x.conf.fragment` (rpi5-csi)
and merge only its applicable settings into the existing primary configuration, after the primary configuration's
includes so the intended deployment overrides win.

| Setting | Value |
| --- | --- |
| `computer_vision_camera_backend`, `video_recording_camera_backend` | `gstreamer` |
| `computer_vision_camera_device` | `libcamerasrc` NV12 640x480 at 30 fps, converted to BGR, `appsink` |
| `video_recording_camera_device` | `libcamerasrc` NV12 640x480 at 20 fps, converted to BGR, `appsink` |
| `video_recording_fps` | 20, matching the recording pipeline |
| `voice_piper_model` | Commented Alan model path; enable only after checking the files exist |

Both pipelines use `appsink drop=true max-buffers=1 sync=false`, so stale frames are dropped. Keep the double
quotes around each complete pipeline: the configuration parser removes ASCII spaces from unquoted values. Do not
split a pipeline across physical configuration lines.

### Native launcher

`run-xwalk` is seeded as
`runtime/run-xwalk` by the existing runtime generator, only when no launcher exists. Explicit deployment uses
`generate-rpi-runtime.sh --build-directory /path/to/native-build`; RPI CMake also supplies its exact binary and
retained configuration paths. Ordinary generation does not execute the launcher or touch hardware. Existing
launchers are preserved: review and merge this template manually when upgrading an operator-owned copy.

The launcher:

- resolves its own location and exits with status 2 unless the machine is `aarch64`;
- sources `runtime/generated/launcher.env` (configured defaults), then the optional operator-owned
  `runtime/environment`; existing environment variables override generated defaults;
- selects `XWALK_PICARX_CONFIG_FILE` (default `runtime/picar-x.conf`) and `XWALK_NATIVE_BINARY` (default
  `../xwalk`) and requires both to be readable or executable;
- prepends `XWALK_LOCAL_PREFIX/lib/aarch64-linux-gnu` to `LD_LIBRARY_PATH` and its `gstreamer-1.0` directory to
  `GST_PLUGIN_PATH` without discarding existing entries; `XWALK_LOCAL_PREFIX` defaults to `$HOME/.local`;
- rejects missing CSI library or plugin directories with a diagnostic when `XWALK_CAMERA_CONNECTION` is `csi`
  (the default); USB selection does not require CSI paths;
- exports `ORT_DISABLE_TELEMETRY=1` and executes the native binary with the supplied arguments.

No broker settings or credentials are embedded in this launcher.

## 5. Build

Build with the native preset only on the Pi, from the workspace root:

```bash
cmake -S xWalk-rpi5-node/xWalkIoT --preset rpi5-native
```

```bash
cmake --build xWalk-rpi5-node/build-rpi5-native --parallel 4
```

The host preset uses simulated providers and build-generated configuration. Neither these native build commands
nor the host tests establish that a connected vehicle is safe for live operation.

## 6. Configuration

On the intended 64-bit Raspberry Pi, inspect the existing `runtime/picar-x.conf`, its included `.conf` files,
`runtime/run-xwalk` and the selected native binary before editing. Keep a private backup outside tracked source;
configuration may contain local secrets. Preserve broker settings and credentials, motor output limits, user
calibration and existing include ordering.

Keep `picarx_calibration_verified = false` unless actual commissioning established otherwise. Calibration status
does not clamp motor power. The configured output ceiling defaults to 100 percent; the GUI selects the requested
power, with steering and balance compensation.

### Voice model

Check the Alan voice model and its companion JSON on the target before enabling the commented model setting:

```bash
test -r /usr/share/xwalk/models/piper/en_GB-alan-medium.onnx && test -r /usr/share/xwalk/models/piper/en_GB-alan-medium.onnx.json
```

If either file is missing, retain the installed voice selection. This check does not install or validate a
model. The default deployment voice is the Alan `.onnx` path, but the operator may select any installed supported
Piper model. Run the existing configure tool's `--validate-model-only` mode to check the effective model and
companion JSON before live speech. Generation does not download or substitute voices and remains usable without
Pi assets.

### Camera plugins

The pipelines require an OpenCV build with GStreamer support, the `libcamerasrc`, `videoconvert` and `appsink`
plugins, and the target's compatible libcamera runtime. Device-free plugin inventory can be inspected on the Pi:

```bash
gst-inspect-1.0 libcamerasrc
```

```bash
gst-inspect-1.0 videoconvert
```

```bash
gst-inspect-1.0 appsink
```

Do not treat successful plugin discovery as a physical camera capture test.

### Deployment paths

A `.local` prefix in the runtime account's home directory was the tested example, not a universal path. Use the
configured runtime account and local prefix. Check ELF architecture and camera and plugin ABI on the target;
directory existence and a successful host fixture do not establish camera compatibility. Review existing launchers
and environment files after a library upgrade, especially if they still select system libcamera 0.2.0.

### Deployed configuration and source parity

The 2026-09-19 comparison against the connected Pi found all deployed production source changes already present
in this workspace, including direct motor power, remote Treasure Hunt, asynchronous speech, background CSI
streaming and their protocol adapters. Host tests and documentation include newer coverage. The native launcher
matched this directory's template.

The Pi's generated configuration differences are produced by the existing
runtime generator:

- CSI executable under the selected runtime user's `.local/bin` directory.
- Microphone `plughw:CARD=Device,DEV=0`, Pulse mixer and `Master` volume control.
- Piper executable `/opt/xwalk/piper-tts/venv/bin/piper` and the installed Alan voice model.
- Ollama `llama3.2:3b` with a manifest under the selected runtime user's home directory.
- Native binary and library paths resolved for the target deployment.

Keep these values in the deployment generator and its configuration inputs. Do not copy generated runtime files
over portable source defaults.

### ONNX Runtime telemetry

`run-xwalk` exports `ORT_DISABLE_TELEMETRY=1` before starting the native process, and speech subprocesses inherit
it. Optional ONNX diagnostic uploads and device-ID persistence are disabled; xWalk logs, speech inference and
robot sensor telemetry are unchanged. Existing deployments must update their retained `runtime/run-xwalk`
launcher and restart the subscriber for the setting to apply.

## 7. Testing

The host-only
`rpi-local-runtime-test.sh` (test)
verifies generation and preservation of operator overrides without connecting to hardware. See
[the Pi GPB checklist](GPB_VERIFICATION.md) for target-only verification. Do not run it on a host or without the
reviewed Pi and Robot HAT setup. Discover registered hardware tests with:

```bash
ctest -N -L hardware
```

Hardware execution needs explicit approval and a freshly confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- OpenCV with GStreamer support, libcamera and the `libcamerasrc`, `videoconvert` and `appsink` plugins.
- Piper and the selected voice model for speech.
- The [Deployment Tool](../../../../../06-xwalk-tool/xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md) runtime
  generator and configure scripts.

## 9. Safety and constraints

- Preserve original calibration, broker settings, credentials and deployment overrides; keep backups private.
- Never commit target secrets, account stores or generated runtime files into this directory.
- Calibration status does not limit motor power; confirm commissioning before live operation.

## 10. Related notes

- [xWalkIoT](../../xWalkIoT.md)
- [Deployment Tool](../../../../../06-xwalk-tool/xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md)
- [xWalkController](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)

---

[Previous page](../../xWalkIoT.md) · [Chapter index](../../../../index.md) · [Next page](GPB_VERIFICATION.md)
