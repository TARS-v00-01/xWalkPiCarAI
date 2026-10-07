<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [5. xWalk node](../index.md) / xWalk-rpi5-node

**5. xWalk node &middot; Module 01**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-node

`xWalk-rpi5-node` is the Raspberry Pi 5 node component of xWalk. It contains the MQTT IoT node, which builds the
`xwalk` executable, and the separate Traffic Controller (`xWalkTrafCtrl`). The traffic process generates traffic
announcements from the crosswalk model and the shared Ollama LLM interface.

## 1. Overview

The component has two independently built applications:

- [xWalkIoT](xWalkIoT/xWalkIoT.md) builds `xwalk`, the C++17 MQTT node. It exchanges binary IW Protobuf
  messages with HiveMQ Cloud over verified TLS. In the full compositions it owns the Controller, Driver and HAL
  runtime that executes requests.
- [xWalkTrafCtrl](xWalkTrafCtrl/xWalkTrafCtrl.md) builds the Traffic Controller process. It publishes traffic
  observations and ANNOUNCE sound requests. The node starts it only through the explicit `traffic` function.

The node has three CMake compositions, each with its own preset and build directory:

| Preset | Output directory | Composition |
| --- | --- | --- |
| `module` | `build-module/cmake` | Node-only terminal module: codecs, dispatch, RX/TX, queues; no MQTT |
| `host` | `build-host/cmake` | All Node, Controller, HAL and Driver libraries with a simulated runtime |
| `rpi5` | `build-rpi5/cmake` | Complete ARM64 cross-build with native providers |

The older `host-debug`, `rpi5-release` and `rpi5-native` presets also remain. `rpi5-native` builds on the Pi
into `build-rpi5-native`. See the [xWalkIoT note](xWalkIoT/xWalkIoT.md) for build commands, terminal JSON
examples and the Node/Controller interfaces.

## 2. Source location

`xWalk-rpi5-node` (source directory)

## 3. Directory layout

```text
xWalk-rpi5-node/
    xWalkIoT/                    MQTT IoT node; CMake project, presets and main.cpp for the xwalk executable
    xWalkTrafCtrl/               Traffic Controller application and its modules
    cmake/
        xWalkPrepareMqttCredentials.cmake   Checks the netrc file and sets owner-only permissions for run targets
    eclipse-build.sh             Configures, builds and tests a Debug host node in build-host for IDE indexing
    .clangd                      Points clangd at build-host/cmake/compile_commands.json
    .gitignore                   Ignores build trees, environment files, keys, certificates and netrc files
    .gitattributes               Relaxes whitespace checks for tracked protoc output under xWalkTrafCtrl/auto-gen
    .cproject, .project, .settings/, .vscode/   Eclipse and VS Code project settings
    build-host/, build-module/   Generated build trees (ignored)
```

## 4. Child modules

- [xWalkIoT](xWalkIoT/xWalkIoT.md): MQTT IoT node, typed request/response runtime and per-core worker processes.
- [xWalkTrafCtrl](xWalkTrafCtrl/xWalkTrafCtrl.md): traffic observation, risk assessment and announcement
  publisher process.

## 5. Public interface

The `xwalk` executable is the component's operational interface. Its subscribers accept comma-separated function
groups, for example `subscribe --function service,vehicle`:

| Token | Meaning |
| --- | --- |
| `service`, `vehicle`, `vision`, `voice` | The four Controller function groups |
| `all` | Selects the four Controller groups; it does not select traffic |
| `traffic` | Replaces the launcher process with the separate Traffic Controller |
| `monitor` | Read-only desktop monitoring: health and sensor requests plus the announcement inbox route |

Unknown, empty, repeated, and mixed `all`/`traffic` selections are rejected. Vehicle safety activity is enabled
whenever `vehicle` is in the selection. `monitor` never selects vehicle activity or subscribes to movement or
lifecycle request topics; it may be combined with functional selections to keep background telemetry.

### Mode motor-power requests

Line Follower, Bull Fight, Treasure Hunt, Obstacle Avoidance, and Cliff Guard accept `motor_power_percent` in
their GPB requests. Setting `update_motor_power` to true changes the matching running mode without stopping or
restarting it. Valid power is finite and between 0 and 100 percent; STOP requests omit it. The matching CFM
echoes accepted power, and the existing REJ reports invalid, busy, or unsupported requests. Face Tracking remains
camera-only and rejects motor power. Request/reply signals and client routing are unchanged. Deploy matching IW,
Node, Controller, and Driver revisions before enabling updates.

### Host announcements

The Sound request route accepts operation 4 (ANNOUNCE). Its ID, title, and body are copied through owned request
buffers to the Controller; confirmations and rejections keep normal client correlation. The Controller stores
each announcement in session memory and reads it aloud before confirming. Upgrade IW and Controller alongside the
node. The desktop Outbox uses this route in live mode.

### Inbox FIFO

The Controller owns the robot's eight-entry received-announcement FIFO. The node forwards broadcasts from every
sender; the ninth valid announcement replaces the first. No device-address Inbox filtering is applied.

## 6. Build

Run these commands from `xWalk-rpi5-node`. Build the Node-only terminal module:

```bash
cmake --preset module -S xWalkIoT
cmake --build build-module/cmake --parallel 4
ctest --test-dir build-module/cmake --output-on-failure
./build-module/cmake/xwalk --list
```

Use `host` to compile all Node, Controller, HAL and Driver libraries with a simulated runtime, and `rpi5` for the
complete ARM64 cross-build with native providers. The `rpi5` preset requires `XWALK_AARCH64_SYSROOT`; see the
[xWalkIoT note](xWalkIoT/xWalkIoT.md) for target setup. Changing the composition in an existing build directory
is rejected.

For a build directly on the Raspberry Pi:

```bash
cmake --preset rpi5-native -S xWalkIoT
cmake --build build-rpi5-native --target xwalk --parallel 3
```

`eclipse-build.sh` configures a Debug host build in `build-host` with compile commands, host tests enabled and
TLS tests disabled, then builds and runs CTest. `eclipse-build.sh clean` cleans that build directory.

## 7. Configuration

On the Pi, the generated `run-xwalk` launcher selects the native binary, hardware configuration and CSI library
paths. The deployment generator seeds it from the tracked template
`xWalkIoT/xWalkDeploy/rpi5-csi/run-xwalk`
into the `runtime` directory of its build directory. The launcher expects the native `xwalk` binary in the
parent of that directory. From that build directory:

```bash
./runtime/run-xwalk subscribe --function all
```

Stop any previous subscriber before starting it. A `host` binary still uses simulation when run on a Pi; it
cannot verify the Robot HAT or provide the CSI video stream. Native Health confirmations identify
`Controller RPI5 runtime ready`; HOST confirmations explicitly identify simulation.

After building `xWalkTrafCtrl`, start the traffic process through the Node function selector:

```bash
./runtime/run-xwalk subscribe --function traffic
```

MQTT credentials are read from a netrc file that is never tracked; `.gitignore` excludes netrc files, keys,
certificates and environment files. The explicit `run-node` and `run-test-message` CMake targets run
`cmake/xWalkPrepareMqttCredentials.cmake`,
which requires an existing netrc file (CMake `HIVEMQ_NETRC_FILE`, otherwise `$HOME/.netrc`) and sets it to
owner read/write only. Ordinary configure, build and test steps do not modify the credential file or connect to
MQTT. See the [xWalkIoT note](xWalkIoT/xWalkIoT.md) for the configuration file and credential contract.

## 8. Testing

Prefer host tests. The isolated host TLS test, `HiveMQNodeLocalTlsTest`, requires a host build configured with
`XWALK_MQTT_BUILD_TLS_TESTS=ON`. It launches concurrent publishers for every nonempty subset of the four RX/TX
process pairs: four singles, six pairs, four triples and all four. Each publisher must receive its own correlated
CFM or deliberate inactive-hardware REJ. The stopped-voice-process isolation and fatal-child cleanup checks
remain. All hardware is simulated in this suite. From the integration root:

```bash
ctest --test-dir xWalk-rpi5-node/build-host/cmake -R HiveMQNodeLocalTlsTest --output-on-failure
```

`XWALK_NODE_CORE_MATRIX_HARDWARE_TESTS=ON` registers optional `hardware` CTests; the option is OFF by default.
List them without running them:

```bash
ctest --test-dir xWalk-rpi5-node/build-host/cmake -N -L hardware
```

The physical core matrix
(`xHal_Rpi5CarCoreMatrixHardwareTest.py`)
runs only with explicit
approval, against the intended Pi with a confirmed safe Robot HAT setup, and with no
other GUI or test controlling the node. A saved Python broker profile provides credentials without command-line
passwords. All 15 subsets cover Health, battery/grayscale/ultrasonic, background camera streaming and spoken
announcements. Every lane requires one terminal reply and overlapping request windows. The ninth announcement
must be stored and spoken, and its broadcast must replace the first in the test's eight-entry Inbox. It sends
no motor commands. The Controller hardware runner reuses this matrix and adds physical sensor-field validation;
one run covers both layers. GUI matrices separately test held level-1 movement alongside sensors, video and
speech. These are representative functional-core combinations, not every command permutation or a physical
accuracy test.

## 9. Dependencies

- [xWalk-rpi5-hw](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalk-rpi5-hw.md): Controller, Driver and HAL libraries composed by the full
  `host` and `rpi5` builds.
- [xWalk-rpi5-iw](../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md): IW Protobuf schemas and signal
  registries.
- [xWalk-rpi5-trace](../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md): shared `xWalkTrace` diagnostics.
- Eclipse Paho MQTT C with TLS, OpenSSL, Protobuf and Python 3, installed by the repository `setup.sh`.

## 10. Safety and constraints

- Use one IoT controller with its process workers and a separate traffic process. Do not launch separate
  hardware-owning Node instances for each function group.
- [Shared-camera service and ownership rules](xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md) describe
  concurrent camera access, Pi ownership guards, host tests and user-service deployment.
- Hardware tests are opt-in and must not run without explicit approval and a confirmed safe Raspberry Pi and
  Robot HAT setup.
- Never place passwords, tokens or broker account data on the command line, in logs or in tracked files.

## 11. Related notes

- [xWalkPiCarAI](../../01-xwalk-workspace/xWalkPiCarAI.md)
- [xWalkController](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)
- [Deployment Tool](../../06-xwalk-tool/xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md)
- [Raspberry Pi 5 CSI Camera
  Deployment](xWalkIoT/xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md)

---

[Previous page](../index.md) · [Chapter index](../index.md) · [Next page](xWalkIoT/xWalkIoT.md)
