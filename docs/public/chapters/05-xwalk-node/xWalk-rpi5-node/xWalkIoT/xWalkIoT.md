<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [5. xWalk node](../../index.md) / xWalkIoT

**5. xWalk node &middot; Module 02**

<!-- xwalk-page-header:end -->

# xWalkIoT

`xWalkIoT` is the CMake project (`xWalkNode`) that builds the C++17 `xwalk` executable. `xwalk` sends and
receives binary IW Protobuf messages through HiveMQ Cloud over verified TLS on port 8883. RX and TX share one
MQTT connection within each process. In the full compositions the node owns the Controller, Driver and HAL
runtime that executes requests and publishes CFM/REJ replies.

## 1. Overview

The project produces one executable named `xwalk` in three separate compositions:

| Preset | Output directory | Composition |
| --- | --- | --- |
| `module` | `build-module/cmake` | Node codecs, dispatch, RX/TX and queues with a terminal endpoint |
| `host` | `build-host/cmake` | All Node, Controller, HAL and Driver libraries; simulated HOST runtime |
| `rpi5` | `build-rpi5/cmake` | All Node, Controller, HAL and Driver libraries; native ARM64 runtime |

`XWALK_MQTT_TARGET` selects the composition (`module`, `host` or `rpi5`). Changing composition in an existing
build directory is rejected. The older `host-debug` (`build-host`), `rpi5-release` (`build-rpi5`) and
`rpi5-native` (`build-rpi5-native`) presets remain available for existing workflows. `rpi5-native` builds
directly on a 64-bit Pi.

### Module composition

The terminal module uses production Node JSON/Protobuf conversion, Agent request dispatch, Transmitter response
decoding, and owned received-message queues. It prints the message retrieved from the queue, not an echo of the
input. Module mode omits Controller, Boot, HAL devices and Driver implementations. It does not connect to MQTT,
perform hardware operations, or fabricate operation confirmations. Shared IW, trace and common support remain
dependencies.

### Full compositions

The full presets add the hardware repository aggregate under `build-host/cmake/hardware` or
`build-rpi5/cmake/hardware`. An ordinary build compiles every HAL and Driver library, including Linux GPIO, I2C,
SPI, ALSA, camera/OpenCV, speech providers and the WebSocket backend. Compiling native providers does not activate
them: HOST Boot uses simulation, while RPI5 Boot uses native providers. No extra build flag is required.
Libraries are build targets, not separate robot processes; `xwalk` links its runtime dependencies.

Full builds retain typed Node-to-Controller requests and Controller-to-Node CFM/REJ publication, including copied
client correlation. Request submission uses the Controller attached to each runtime; the host suite checks all
38 request mappings and 76 typed completion encoders. Host mode uses simulated providers; RPI5 uses deployment
device and provider configuration. The previously identified Boot configuration-key mismatches remain a separate
limitation; selecting RPI5 does not validate the connected devices, installed models, or every deployment
setting.

Controller Boot resets and releases the HAT MCU before constructing PWM providers, then waits for the validated
`hardware_mcu_reset_settle_ms` interval (default 200 ms; range 1–10000 ms). Native vision and recording callback
bindings forward device operations with provider contexts and schedule waits and continuation with Controller
graph context. See the [Controller contract](../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md) for startup
and cancellation. Cancellation checks after input, recognition and model inference prevent subsequent work at
those boundaries; already-running synchronous provider calls keep their own timeout and are not forcibly
interrupted.

### Per-core request and response processes

Typed `subscribe` and `queue` commands start eight child processes in addition to the parent hardware owner.
No extra GUI flag or protocol change is required. Raw transport commands and one-shot publishers keep their
existing behavior. The transport-only module build does not create hardware or these process workers.

| Functional core | Request process | Response process | Affinity |
| --- | --- | --- | --- |
| Service | `xw-rx-0` | `xw-tx-0` | First allowed CPU |
| Vehicle | `xw-rx-1` | `xw-tx-1` | Second allowed CPU |
| Vision | `xw-rx-2` | `xw-tx-2` | Third allowed CPU |
| Voice | `xw-rx-3` | `xw-tx-3` | Fourth allowed CPU |

Each child has its own PID, MQTT connection and receive state; unique MQTT client IDs must remain enabled.
Request children subscribe only to their selected functional signals and route encoded GPB bytes to independent
parent bridges. The parent decodes the requests and keeps the bounded Controller queues, operation workers,
device leases, watchdog and calibration. Only the parent owns I2C, GPIO, camera and audio devices. Response
children publish encoded CFM/REJ; unaddressed diagnostics use the service response child. A successful IPC send
means queued locally. The response adapter reports delivery only after the matching child's successful QoS 1
completion; failed or timed-out publications are not retried automatically.

Children are created with `posix_spawn` and a fresh executable image before hardware initialization. Private
`SOCK_SEQPACKET` channels carry bounded same-build frames, sequence numbers and GPB bytes, never pointers. The
private worker entry (`--ipc-worker`) validates its socket peer, parent PID and CPU. Other endpoints are
close-on-exec. Each request child permits eight outstanding IPC frames in addition to the Controller FIFO.
Overflow fails the child and triggers parent shutdown rather than silently overwriting requests. Responses are
serialized per core; each exchange waits at most 15 seconds, including MQTT's 10-second publication timeout.
Startup requires all eight readiness handshakes and at least four allowed CPUs.

The supervisor checks child liveness every 10 milliseconds. IPC failure or unexpected child exit cancels the
hardware runtime and exits nonzero; it does not silently restart actuator state. Normal shutdown stops request
admission, cancels and drains Controller work with response children alive, then closes channels and reaps
children. Children exit if the parent dies. Inspect the process tree after starting the normal subscriber:

```bash
ps -eo pid,ppid,psr,comm,args --forest
```

The owner starts without the broker and retries the MQTT children in the background; meanwhile it serves
read-only health and sensor requests to this node through `publish --transport local`. See
[offline start and local
telemetry](xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md#offline-start-and-process-workers).

### Background video sessions

`VideoStreamReq.background = true` starts an independently owned CSI/MJPEG worker and confirms once camera and
listener startup succeed. `stop = true` is valid only with `background = true` and confirms cleanup of that
background session. Both fields default to false, preserving the foreground streaming command. The handwritten
Node encode/decode adapters carry both fields.

The background worker owns only the streaming camera and HTTP listener. Bounded vehicle requests, camera angles,
and sensor requests keep the ordinary Controller operation slot. Camera-consuming vision modes stop the
background worker before acquiring the camera. Lifecycle Stop, Controller shutdown, and capture failure close its
clients, listener, and camera. A successful start CFM does not guarantee future camera availability; later
capture failures are traced and close the HTTP connection. The stream is loopback-only by default and the
desktop accesses it through an authenticated SSH tunnel. Deploy updated IW interfaces, Node adapters, and
Controller together before using desktop background mode.

### Traffic Controller function and announcements

Traffic Controller is an additional, explicitly selected process function in full host and Pi builds. `all`
selects only Service, Vehicle, Vision and Voice. Traffic does not accept publish/JSON signals or `--qos`; its own
configuration controls MQTT and inference. An optional `--config FILE` selects a traffic configuration, including
local video settings for host tests. The launcher replaces itself with Traffic Controller, preserving its PID,
signals, environment and exit status. It does not start another Controller or eight MQTT workers. Run Vehicle or
All separately for proximity IPC; traffic safety announcements remain suspended without an active Vehicle/All
owner. When both processes need the camera, configure the shared camera service and feed described in
[xWalkCameraSvc](../xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md).

`xWalkTrafCtrl` publishes binary IW `SoundReq` messages with operation `ANNOUNCE` (4) on
`xwalk/xwalk-pi5-controller/request/8216`, QoS 1, non-retained. The broadcast target is
`clientAddress.server_ip = "0.0.0.0"`; the nested request address matches the envelope. `TrafficObservation` is
published separately on `xwalk/xwalk-pi5-controller/traffic/observation`.

Subscribers include the SoundReq topic even when a function such as `vehicle` is selected. Only ANNOUNCE bypasses
that filter; other sound operations still require `voice` or `all`. This applies to both the single-process
runtime and the per-core request workers. The Controller validates the address, stores the announcement and
handles speech. Publisher response subscriptions are unchanged.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT` (source directory)

## 3. Directory layout

```text
xWalkIoT/
    CMakeLists.txt          xWalkNode project: composition selection, xwalk target, run targets and node tests
    CMakePresets.json       module, host, rpi5 and legacy host-debug, rpi5-release, rpi5-native presets
    main.cpp                Selects help, IPC worker, raw, typed and local-transport modes
    auto-gen/
        include/, src/      Tracked IW Protobuf C++ bindings used through XWALK_IW_GENERATED_DIRECTORY
    xWalkAgent/
        xWalkReceiver/      Request copy/dispatch, CFM and REJ encoders, Controller response adapter
        xWalkTransmitter/   Request encoding and response decoding for publishers
    xWalkDeploy/
        rpi5-csi/           Reviewed Pi launcher template and picar-x.conf CSI fragment
    xWalkMqttClient/        MQTT subscriptions and received-message callbacks
    xWalkMqttCommon/        Generated plain IW headers, JSON, queues, types and the node runtime
    xWalkMqttInit/          Configuration, netrc credentials, TLS, connection lifecycle and JSON samples
    xWalkMqttServer/        Binary message publication and responses
    test/
        include/, src/      HiveMQNodeTest sources and test support
        java/               TrafficReceiver.java used by the cross-app receiver test
        *.py                TLS, traffic, cross-app and hardware matrix test runners
```

Component directories use the `xWalk` prefix (`xWalkReceiver`, `xWalkDeploy`, `xWalkConfig`, `xWalkModule`).
Native tests use `test/src` and `test/include`; Python test runners stay in `test`. Generated `auto-gen` trees
and the runtime build `config` directory keep their existing names.

## 4. Child modules

- [xWalkReceiver](xWalkAgent/xWalkReceiver/xWalkReceiver.md): Service, Vehicle, Vision and Voice request
  handlers, CFM/REJ encoding and the Controller response adapter.
- [xWalkTransmitter](xWalkAgent/xWalkTransmitter/xWalkTransmitter.md): request encoding and response decoding.
- [Raspberry Pi 5 CSI Camera Deployment](xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md):
  reviewed CSI launcher and configuration templates.
- [xWalkMqttClient](xWalkMqttClient/xWalkMqttClient.md): subscriptions and received-message callbacks.
- [xWalkMqttCommon](xWalkMqttCommon/xWalkMqttCommon.md): Request, CFM and Reject queues, CLI, runtime and
  shutdown helpers.
- [xWalkMqttInit](xWalkMqttInit/xWalkMqttInit.md): configuration, credentials, TLS and connection lifecycle.
- [xWalkMqttServer](xWalkMqttServer/xWalkMqttServer.md): binary message publication and responses.

## 5. Public interface

### Operating modes

`main.cpp` selects the primary modes; typed-mode implementation
lives in the MQTT common runtime files. The raw `publish`, `respond`, `subscribe` and `node` commands remain
available for compatibility.

| Mode | Input | Behavior |
| --- | --- | --- |
| `test` | Built-in `hello-xwalk` fixture | Sends one raw GPB test message and keeps listening |
| `subscribe --function …` | Backend enqueue API | Receives and polls queues in the foreground until Ctrl+C |
| `publish --function …` | JSON file and signal | Sends one request, waits for its CFM/REJ, prints JSON |

Named options select typed mode; positional `publish GPB_FILE` and `subscribe TOPIC` keep raw GPB behavior.
`json` and `queue` remain compatible aliases. Typed functions are `service`, `vehicle`, `vision` and `voice`;
subscribers also accept `all`, `traffic` and comma-separated groups. Use lowercase function names. Publishing
requires one specific function and signal; there is no `publish --function all`. For the typed functions,
`--qos 0|1|2` is optional and defaults to 1. No CPU affinity is set by this option.

| Function | Example request signal | Sample relative to the build directory |
| --- | --- | --- |
| Service | `XWALK_VERSION_REQ` | `config/request/service/xWalkMqttVersionReq.json` |
| Vehicle | `XWALK_CNTRL_MOVE_REQ` | `config/request/vehicle/xWalkMqttMoveReq.json` |
| Vision | `XWALK_CNTRL_COMPUTER_VISION_REQ` | `config/request/vision/xWalkMqttVisionReq.json` |
| Voice | `XWALK_CNTRL_SOUND_REQ` | `config/request/voice/xWalkMqttSoundReq.json` |

For battery telemetry, use function `vehicle`, signal `XWALK_CNTRL_SENSOR_REQ`, and set `request.type` to
`XWALK_SENSOR_TYPE_BATTERY` in `config/request/vehicle/xWalkMqttSensorReq.json`. The node forwards
`SensorCfm.message` JSON containing `battery_voltage`, `battery_percent`, and `estimated`. The percentage is a
voltage-based estimate; invalid acquisition produces `SensorRej`.

### Module terminal

In the `module` composition, `--list` prints one JSON registry record per line for all 114 signals. Select a
symbolic name or decimal signal and a JSON file; `-` reads one complete JSON document from stdin until EOF. Each
invocation prints a compact JSON result containing `ok`, `signal`, `name`, and the decoded `message`. Errors
return a nonzero exit status.

### Typed publish semantics

Typed `publish` requests subscribe to their CFM and REJ topics before sending. The publisher waits for a response
matching the requested signal and the complete client-address structure from the transmitted request
(`clientAddress`, `mail_box_id`, `xwalk_local_index` and `module_type`), then prints the received JSON. Mismatched
or duplicate replies do not complete the wait. Terminal replies use four-space JSON indentation and their actual
message name as the outer key, for example `HealthCfm` or `HealthRej`. No response or reject file is created and
`--response-file` is not accepted.

- `--timeout-ms N` changes the 60000 ms timeout; the allowed range is 1–600000.
- Exit status is 0 for CFM, 1 for REJ or I/O failure, 2 for invalid arguments, 124 for timeout and 130 for an
  interrupted wait. A timeout does not print a fabricated response.
- `--file` is optional. The signal selects its sample filename through `xHal_Rpi5CarMqttNodeSampleMacros.h`,
  generated into the build directory from IW definitions and
  functional ownership (`xWalkMqttFunctions.json` in
  `xWalkMqttNode/xWalkConfig`).
  Defaults use absolute paths, independent of the working directory.
- JSON input is one object using the Protobuf field names and types, limited to 64 KiB. Unknown fields and
  unsupported signals are rejected. Bytes fields use Protobuf JSON base64.
- `--signal` accepts a generated `XWALK_*` macro name, a decimal number or a `0x` hexadecimal number. Its
  functional owner must match `--function`.
- Publishing CFM/REJ messages and the `json` command keep send-once behavior without waiting; JSON mode returns
  0 on success or 1 on load, publish or disconnect failure.

### Addressing

Each node detects its own IPv4 address from `wlan0`, then `eth0`, then another active interface; set
`XWALK_SERVER_IP` when several are active. Requests carry that address as `clientAddress` and the target as
`server_ip`. `publish --server HOST` accepts an SSH host alias (expanded with `ssh -G`), a DNS name or a numeric
IP. Without it, or when it resolves to loopback such as `localhost` or a hostname mapped to `127.0.1.1`, requests
target this node. Neither address is the broker address or a direct connection destination.

A subscriber processes a request only when `server_ip` is its own address. An announcement or voice-chat start
may use `0.0.0.0` to reach every node. Any other request, including one without `server_ip`, receives its own
`...Rej` with `error_signal` `XWALK_ERROR_SIGNAL_WRONG_SERVER` (`27`) and a detail naming both addresses;
`LifeMoveRej`, `HealthRej` and `VersionRej` report `code` `XWALK_LIFE_CODE_WRONG_SERVER` instead. A request with
an invalid field value, such as an undefined enumeration, is rejected with `XWALK_ERROR_SIGNAL_INVALID_ARGUMENT`
(`1`) rather than dropped.

### Topics

Typed modes use exact topics `<request-topic>/<decimal-signal>` and `<response-topic>/<decimal-signal>`. For
example, MoveReq uses `xwalk/xwalk-pi5-controller/request/8202`. The payload is native IW Protobuf without an
added binary envelope. Both endpoints must use this convention; legacy raw-topic commands keep their behavior.
Requests use the transmitter to assign client address, mailbox, module and local index. CFM/Reject JSON or
backend messages must carry the request's echoed `clientAddress`; these fields are preserved when sent.

### Controller rejections

The queue subscriber forwards decoded request structures to the Controller's four functional FIFOs. Controller
warnings and errors are traced locally and also encoded by `XWalkControllerResponse` using the IW schemas. Known
typed requests receive the matching `*Rej` on `response/<REJ signal>` with the original client address, mailbox,
local index and module type. The publisher uses QoS 1 without retention.

Unaddressed lifecycle errors, unknown signals and unsafe structure sizes use `TraceRej` on the configured status
topic, which queue mode subscribes to automatically. No client identity is fabricated. Controller construction
precedes MQTT connection; its workers start after connection, and draining precedes disconnection. Boot runs the
production operation adapters. FIFO acceptance alone is not an operation confirmation. On FIFO overflow the GPB
publish attempt finishes before process abort. Transport failures remain local traces and are never recursively
published; broker availability is required for delivery.

### Backend C/C++ interface

Link C/C++ backend code into the same process and use `xHal_Rpi5CarMqttBackend.h`:

- `xwalk_backend_enqueue(signal, payload, length)` copies one outgoing native GPB message.
- `xwalk_request_dequeue(...)` reads received requests.
- `xwalk_cfm_dequeue(...)` reads received confirmations.
- `xwalk_reject_dequeue(...)` reads received rejections.

The producer and consumers may run on backend threads. `runNodeRuntime(options)` runs on the main thread; set
`options.functionality` and `options.clientIp` and link the `xWalkMqttNodeRuntime` CMake target. Keep borrowed
options alive for the complete call and stop and join backend threads before process shutdown. Only one runtime
owns the process queues and signal handlers. Runtime functions are C++ APIs; queue entry points have C linkage
and a C-compatible header. A Python or Android process still needs a separate IPC adapter.

The main loop polls one outgoing entry every `XWALK_MQTT_CLI_SLEEP_MS` (100 ms) and stops on SIGINT/SIGTERM or
send failure. CLI `subscribe`/`queue` options enable a separate bounded received-update drain in that loop. Each
pass consumes at most `XWALK_MQTT_QUEUE_CAPACITY` observer copies from each Request, CFM and Reject queue. Agent
dispatch copies decoded request data before enqueueing the observer bytes, and Controller submission copies the
typed request into its own FIFO, so removing received observer copies cannot remove dispatched work. The drain
leaves the outgoing backend queue intact.

Directly constructed `XWalkNodeRuntimeOptions` leave `drainReceivedUpdates = false`: embedding adapters keep
ownership of `xwalk_request_dequeue`, `xwalk_cfm_dequeue`, and `xwalk_reject_dequeue`. An adapter reusing
CLI-parsed options must set that field to false before providing its own consumers. Neither `receiveNodeMessage`
nor `pollNodeBackend` consumes adapter-owned updates; only one owner should drain them. Each of the four queues
keeps its 64-message capacity, 64 KiB message limit and fatal overflow checks. The bounded drain prevents
accumulation over sustained traffic; it does not guarantee admission of a burst exceeding capacity between loop
passes. A popped outgoing message is not retried after publish failure because its delivery outcome may be
unknown.

### Controller send macros

The Node Controller macros are declared in
`xHal_Rpi5CarMqttControllerMacros.h` in
`xWalkMqttTypes/include`.
Link `xWalkMqttNodeRuntime` to use `XWALK_MQTT_SEND_REQUEST`, `XWALK_MQTT_SEND_CFM`, and `XWALK_MQTT_SEND_REJECT`.
They forward a signal, decoded structure pointer, and structure size to the Controller. `runNodeRuntime()`
initializes one process-wide Controller with MQTT response callbacks during startup. The instance is available
through `nodeController()` until shutdown; initialize before using the send macros. Lifecycle calls belong to one
owner thread. Shutdown joins MQTT callbacks and Controller workers before releasing borrowed callback state.
Typed confirmation and rejection handlers use the Node response callback to encode and publish all 76 completion
types. Publication results propagate to the Controller; failed sends are not successes.

### Functional request preparation

[`xWalkAgent`](xWalkAgent/xWalkReceiver/xWalkReceiver.md) provides Service, Vehicle, Vision, and Voice handler
classes with four signal-based admin entry points. They copy all 38 IW request types into owned local storage and
emit registered `XAGENT.xxx` diagnostics. The full Node runtime submits decoded requests to its attached
Controller. The transport must provide the signal number; typed queue/JSON modes resolve it from the topic
suffix. Legacy raw-topic callbacks remain print-only.

### Tracing

Diagnostics use the shared `xWalkTrace` module and write to `build-host/cmake/log/xWalkTrace.log` (or the
corresponding Raspberry Pi build directory). `xwalk` preserves the configured trace selection at startup,
including short-lived telemetry publishers, which avoids flooding GPIO polling logs. Trace-control messages
adjust selection through the trace module. Warnings and errors remain unfiltered. There is no separate IoT trace
switch.

| IDs | Events |
| --- | --- |
| `MQTTUL` IDs including `MQTTUL.010` | Connection lifecycle, reception and subscriptions |
| `MQTTUL.011`–`MQTTUL.013` | Request/CFM/Reject queue insertion, removal and insufficient reader buffer |
| `MQTTDL.001`–`MQTTDL.002` | Publication byte count, QoS, retained flag and response completion |
| `XAGENT.101`–`XAGENT.138` | Decoded request field values |
| `XAGENT.201`–`XAGENT.206` | Request, confirmation and rejection send attempts and results |
| `XAGENT.207`–`XAGENT.213` | Pending identities, cancellation, response matching, ignored foreign replies |

`XWALK_MQTT_WARNING`/`XWALK_MQTT_ERROR` report transport and queue failures; `XWALK_XAGENT_WARNING`/
`XWALK_XAGENT_ERROR` report invalid signals, failed encoding/decoding and exhausted request tracking. Events
contain message metadata rather than payloads or credentials. Copied request traces use the trace module's Agent
formatter for all 38 request types: the `Copied <type>:` label is followed by JSON on the next line with
four-space indentation. Strings are escaped, absent optional fields are `null`, and binary trace fields are
hexadecimal strings. This is diagnostic JSON of the copied structures; MQTT still carries encoded Protobuf.
Queue depth is a snapshot taken during the operation; trace callbacks run after the queue lock is released. CLI
help uses the trace-owned plain command-text sink, remains visible with ordinary UID traces disabled, and prints
Linux-style usage without severity or source prefixes. Structured command results and received binary output
keep their formats.

## 6. Build

Run all commands from `xWalk-rpi5-node`. Install dependencies once with the command for your machine. The root
`setup.sh` requires sudo and installs immediately the native build, MQTT/TLS, Protobuf, test, and quality
dependencies from the shared repository catalog. Supported systems are Ubuntu 24.04+ and Debian/Raspberry Pi OS
12+ (64-bit on the Pi).

```bash
sudo ../setup.sh --target host
```

```bash
sudo ../setup.sh --target rpi
```

### Node-only module

```bash
cmake --preset module -S xWalkIoT
cmake --build build-module/cmake --parallel 4
ctest --test-dir build-module/cmake --output-on-failure
./build-module/cmake/xwalk --list
./build-module/cmake/xwalk XWALK_HEALTH_REQ build-module/cmake/config/request/service/xWalkMqttHealthReq.json
./build-module/cmake/xwalk XWALK_HEALTH_CFM build-module/cmake/config/cfm/service/xWalkMqttHealthCfm.json
./build-module/cmake/xwalk XWALK_HEALTH_REJ build-module/cmake/config/reject/service/xWalkMqttHealthRej.json
printf '%s\n' '{"service":"controller"}' | ./build-module/cmake/xwalk 8337 -
```

### Full host build

```bash
cmake --preset host -S xWalkIoT
cmake --build build-host/cmake --parallel 4
ctest --test-dir build-host/cmake --output-on-failure
```

Re-run the configure command when upgrading an existing HOST build; deleting the build directory is unnecessary.

### Raspberry Pi 5 cross build

Before cross-configuring, set `XWALK_AARCH64_SYSROOT` to an ARM64 target root filesystem with the required headers
and libraries. The repository toolchain rejects a missing sysroot or a host compiler pretending to be ARM64.
Cross-built binaries run on the Pi; no hardware tests are run by these commands.

```bash
cmake --preset rpi5 -S xWalkIoT
cmake --build build-rpi5/cmake --parallel 4
```

### Raspberry Pi 5 native build

Run on a Raspberry Pi 5 with a 64-bit OS after the Pi installer. This builds with the Pi's native compiler and
libraries. The native preset disables automated host and TLS tests.

```bash
cmake -S xWalkIoT --preset rpi5-native
cmake --build build-rpi5-native --parallel 4
```

Native examples use `runtime/run-xwalk`, seeded by explicit runtime generation (and RPI configuration) from the
launcher template. The launcher expects
the native `xwalk` binary in the parent of its `runtime` directory, so run it from that build directory. The
generated launcher environment records the selected binary, configuration, camera type, and local prefix.
Existing launchers and `runtime/environment` are preserved; review older launchers against the current template.
See [CSI deployment](xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md) and the
[future Pi GPB verification checklist](xWalkDeploy/rpi5-csi/GPB_VERIFICATION.md). Pi execution has not been
verified on the development host.

### Command reference

| Task | Host | Raspberry Pi 5 |
| --- | --- | --- |
| Configure | `cmake -S xWalkIoT --preset host` | `cmake -S xWalkIoT --preset rpi5-native` |
| Build | `cmake --build build-host/cmake --parallel 4` | `cmake --build build-rpi5-native --parallel 4` |
| Automated tests | `ctest --test-dir build-host/cmake --output-on-failure` | Disabled in the native preset |
| Show help | `./build-host/cmake/xwalk --help` | `./runtime/run-xwalk --help` |
| Subscribe | `./build-host/cmake/xwalk subscribe --function all` | `./runtime/run-xwalk subscribe ...` |
| Trace log | `build-host/cmake/log/xWalkTrace.log` | `build-rpi5-native/log/xWalkTrace.log` |
| Stop subscriber | **Ctrl+C** | **Ctrl+C** |

### Run in two terminals

Start the subscriber first and wait for its `Subscribed MQTT topics=... function=... qos=1` summary
(`topics=114` for `all`). Copied requests appear as indented JSON in the subscriber terminal and trace log.

```bash
./build-host/cmake/xwalk subscribe --function all
```

In the second terminal, activate the robot, wait for `LifeMoveCfm` with state `XWALK_LIFE_STATE_ACTIVE`, then
request movement:

```bash
./build-host/cmake/xwalk publish --function service --signal XWALK_LIFE_MOVE_REQ
./build-host/cmake/xwalk publish --function vehicle --signal XWALK_CNTRL_MOVE_REQ
```

Further requests for all four function groups:

```bash
./build-host/cmake/xwalk publish --function service --signal XWALK_VERSION_REQ
./build-host/cmake/xwalk publish --function vision --signal XWALK_CNTRL_COMPUTER_VISION_REQ
./build-host/cmake/xwalk publish --function voice --signal XWALK_CNTRL_SOUND_REQ
./build-host/cmake/xwalk publish --function service --signal XWALK_HEALTH_REQ --timeout-ms 10000
```

On a Raspberry Pi 5, replace `./build-host/cmake/xwalk` with `./runtime/run-xwalk`. The publisher loads its
sample from the build `config` directory, encodes it as Protobuf, sends once, and waits for the reply. The
subscriber prints `Copied MoveReq:` followed by indented JSON and keeps listening until **Ctrl+C**. Start the
traffic function separately:

```bash
./runtime/run-xwalk subscribe --function traffic
```

On a host, use `./build-host/cmake/xwalk subscribe --function traffic`; the `queue` alias also works.

### Two computers

For a complete host-publisher/Pi-subscriber walkthrough, see the
robot control guide. It covers movement,
camera-head control, SSH video viewing, and the operation-concurrency limit.

| Arrangement | Subscriber | Publisher `--server` | Connection |
| --- | --- | --- | --- |
| Two terminals on one computer | Detected automatically | Omit; targets this computer | Same configured broker |
| Two different computers | Detected automatically | Subscriber's alias, DNS name or IP | Same broker; TLS 8883 |

Build and configure credentials on each computer. Both need internet access, the same broker hostname, and MQTT
credentials with publish/subscribe permission under `xwalk/xwalk-pi5-controller/#`; they may use separate
credentials. Keep the same request/response topics and leave unique client IDs enabled. Find the subscriber's
address with `hostname -I` (use the active interface's address if several are listed) and pass it, or an SSH
alias or DNS name, to the publisher's `--server`. Messages travel through the broker, so the computers do not
need to share a local network. Both need outbound TLS access to port **8883**; no inbound MQTT port is opened.
This supports host-to-host, host-to-Pi, and Pi-to-host testing.

### Generated IW headers and bindings

`xWalkMqttCommon/auto-gen` contains tracked C++17 structs and enums from the IW schemas plus signal macros from
all three XML registries. The headers match the Library copy, and CMake compiles every node target against the
Library copy through `xWalkLibraryCommon`, so the node, Controller and trace share one `ClientAddr` layout. They
use `xwalk::iw::v1::plain` and coexist with the Protobuf classes. String, byte, and repeated fields borrow
caller-owned storage; `has_<field>` distinguishes absent optional scalars and singular messages. These structs
are in-memory data views, not encoded MQTT payloads.

`auto-gen/include` and `auto-gen/src` contain the tracked C++ Protobuf bindings generated from the
`xWalk-rpi5-iw` schemas. Node selects this copy through `XWALK_IW_GENERATED_DIRECTORY` when it adds
`xWalk-rpi5-iw`, which builds the `xWalkIwProtobuf` target. The Controller keeps an identical copy in
`xWalk-rpi5-hw/xWalkController/auto-gen`. From the integration root, regenerate and check both destinations:

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-headers
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-headers
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-cpp
```

Generation requires `protoc` and the Python Protobuf package (`python3-protobuf` on Ubuntu). Commit regenerated
output with schema changes; do not edit generated files manually.

## 7. Configuration

| Machine | Configuration | Credentials |
| --- | --- | --- |
| Host | `build-host/cmake/config/xWalkMqttClient.conf` | Running user's `$HOME/.netrc` |
| Raspberry Pi 5 | `build-rpi5-native/config/xWalkMqttClient.conf` | Pi user's `~/.netrc` |

CMake seeds the configuration from
the source template on the
first configure and preserves existing settings later. It holds `HIVEMQ_HOST` (broker hostname),
`HIVEMQ_CLIENT_ID` (base client ID) and `HIVEMQ_CA_FILE` (CA bundle path). `HIVEMQ_CONFIG_FILE` selects another
configuration at runtime and CMake `XWALK_MQTT_CONFIG_FILE` sets the compiled default.

Credentials are never stored in the configuration file. The runtime netrc path is `HIVEMQ_NETRC_FILE`, then the
CMake `HIVEMQ_NETRC_FILE` default, then the running user's `$HOME/.netrc`; `host-debug` sets `$HOME/.netrc`
explicitly. The netrc `machine` must match `HIVEMQ_HOST` and hold the MQTT username and password created in the
broker's access management. The file must be owned by the running user with owner-only permissions. See
[credential setup](xWalkMqttInit/xWalkMqttInit.md#netrc-setup). The explicit `run-node` and `run-test-message`
targets set owner-only permissions on the netrc file; ordinary configure, build and test steps do not.

Allow publish and subscribe access to `xwalk/xwalk-pi5-controller/#`. `XWALK_MQTT_UNIQUE_CLIENT_IDS` (default ON)
adds a unique suffix to each instance's client ID, so terminals sharing settings do not disconnect each other.

### Request samples

Request, CFM and Reject examples are indexed in
[the sample configuration guide](xWalkMqttInit/xWalkConfig/xWalkConfig.md).
CMake copies them, grouped by functionality, to the matching directories under the build `config` directory. To
send different values, edit the source sample and re-run the configure command, or supply `--file PATH`.
Reconfiguration stages the updated source sample; a separate deployment must include that refreshed `config`
directory. Custom payloads supplied with `--file` keep their selected targets.

- The default LifeMoveReq (`config/request/service/xWalkMqttLifeMoveReq.json`) targets `XWALK_LIFE_STATE_ACTIVE`,
  enabling actuators on successful activation. A successful publisher exit only confirms sending.
- The default MoveReq (`config/request/vehicle/xWalkMqttMoveReq.json`) contains `request.speedPercent=15` and
  `request.durationMs=250` and still requires ACTIVE lifecycle state.
- SoundReq uses the absolute staged PCM16 horn derivative at 20% volume; rebuild after relocating the build tree.
  Use the staged sample or supply a target-local audio path for a remote publisher.

### Traffic executable

Build [xWalkTrafCtrl](../xWalkTrafCtrl/xWalkTrafCtrl.md) before selecting `traffic`. The default executable is
`xWalkTrafCtrl/build-<target>/xWalkTrafCtrl` in the configured source checkout (for example `build-host` or
`build-rpi5`). The runtime variable `XWALK_TRAFFIC_BINARY` overrides it for relocated deployments; CMake
`XWALK_NODE_TRAFFIC_BINARY` sets the compiled default. Required traffic defaults stay in its tracked `xWalkConfig`.

### Raspberry Pi deployment settings

The [reviewed CSI deployment templates](xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md)
are separate from host defaults and have not been applied remotely. They describe how to preserve an existing
runtime, check the Alan Piper model and JSON, merge quoted 640-by-480 GStreamer pipelines, and review a launcher
that preserves library and plugin search paths. Computer vision uses 30 fps and recording uses 20 fps with
`video_recording_fps = 20`. Pipeline quotation marks are required because the configuration parser removes spaces
from unquoted values. The local AArch64 library and GStreamer plugin directories are target-specific dependencies,
not paths to install in host configuration.

### Troubleshooting

- Connection failure: check the broker hostname, the matching netrc entry and the MQTT credentials.
- TLS failure: check the CA bundle, system clock and outbound access to port 8883.
- No received message: start the listener first and check publish/subscribe topic permissions.
- Missing topic or lifecycle traces: enable the relevant traces in the trace module's `xwalk-traces.xml`. Typed
  copied-message JSON uses the `XAGENT` traces; raw binary output is independent of trace selection.

## 8. Testing

Host tests are registered when `XWALK_MQTT_BUILD_HOST_TESTS=ON` (set by the `module`, `host` and `host-debug`
presets). They cover node, RX, TX and credential loading without live broker credentials. Project-level CTests:

| Test | Labels | Notes |
| --- | --- | --- |
| `HiveMQNodeHostTest` | `host;mqtt;node` | `HiveMQNodeTest` with wrapped Paho publish calls |
| `xWalkNodeTrafficFunctionHostTest` | `host;node;traffic` | Traffic function selection and launch |
| `xWalkTrafficHardwareProbeHostTest` | `host;traffic` | Hardware-probe evidence logic without broker or hardware |
| `HiveMQNodeLocalTlsTest` | `host;mqtt;tls;node` | Requires `XWALK_MQTT_BUILD_TLS_TESTS=ON` |
| `xWalkTrafficCrossAppHostTest` | `host;mqtt;tls;traffic;cross-app` | TLS option and `host` target only |

Component suites (for example `xWalkMqttNodeRuntimeHostTest`, `xWalkNodeIpcHostTest`,
`xWalkControllerResponseHostTest` and `xWalkNodeModuleTerminalTest`) are documented in the child notes. The module
suite checks all 114 message samples, JSON round trips, malformed input and build isolation.
`xWalkControllerResponseHostTest` checks all 38 rejection schemas, routing fields, lifecycle status, recursive
failure protection and GPB handoff before fatal overflow without contacting a broker. Full HOST tests also
include the centralized HAL suite, Driver suites and Controller tests.

Process-runtime host verification covers bounded and malformed IPC, startup rollback, eight distinct PIDs and CPU
masks, all four functional response paths, service traffic while the voice publisher is paused, and child-failure
cleanup.

### Local TLS tests

The optional local TLS tests use a temporary loopback broker and require Mosquitto, `mosquitto_passwd` and
OpenSSL. Enable `XWALK_MQTT_BUILD_TLS_TESTS=ON` and leave CMake's `HIVEMQ_NETRC_FILE` empty in a separate test
build so temporary test credentials are used. They use HOST simulation and never access a Robot HAT.

`xWalkTrafficCrossAppHostTest` runs the full simulated IoT node beside the native traffic process and two
independent MQTT receivers. It verifies that all 21 observations from the bundled host clip reach the Python app
and Android's production Java topic/receive logic, that both apps receive the same nonzero announcement count, that
their final risk labels agree and remain fresh, and that the IoT owner stays alive. Service, Vehicle, Vision and
Voice requests start together while traffic runs; every lane must return its correlated confirmation or rejection
within the deadline.

The fixture starts a private authenticated TLS broker on `127.0.0.1:8883` with temporary credentials and
certificates, restores trace configuration, and stops its processes on completion or failure. An occupied port
fails the test; no existing broker is stopped. It never starts Android instrumentation or Pi hardware. Prepare the
Python app `.venv` (or set `XWALK_CI_PYTHON`), Android Debug classes and cached Gradle dependencies, SDK 36
(`ANDROID_HOME` or `ANDROID_SDK_ROOT`), the traffic host binary and trained model exports, and local Ollama with
`llama3.2:3b`. The model repository and both app repositories must be checked out beneath the same workspace root
as `xWalkPiCarAI`. Java/Javac, OpenSSL, Mosquitto and `mosquitto_passwd` must be on `PATH`. The test exercises
actual inference and local LLM generation; it does not download dependencies or measure model accuracy against
labeled ground truth. Missing prerequisites fail instead of silently skipping. From the workspace root:

```bash
cmake --preset host -S xWalkPiCarAI/xWalk-rpi5-node/xWalkIoT -DXWALK_MQTT_BUILD_TLS_TESTS=ON
cmake --build xWalkPiCarAI/xWalk-rpi5-node/build-host/cmake --parallel 4
ctest --test-dir xWalkPiCarAI/xWalk-rpi5-node/build-host/cmake -R '^xWalkTrafficCrossAppHostTest$' --repeat until-fail:3 --output-on-failure
```

CTest serializes this case with other tests to protect the fixed loopback port and generated trace
configuration. Summary JSON and sanitized fixture logs are in `build-host/cmake/cross-app-test`; temporary
credentials are removed after the run. Android UI rendering and device lifecycle tests remain separate.

The script can also run directly from the `xWalkPiCarAI` integration root. Use `--fixture-llm` when Ollama is
unavailable: the loopback provider returns explicitly labelled test advisories and the report identifies that
fixture. This verifies message routing, not language-model quality or Android device behavior. The fixture
selects CPU inference and does not alter installed app or Pi settings.

```bash
../xWalkPiCarApp/xWalk-pcx86-app/.venv/bin/python xWalk-rpi5-node/xWalkIoT/test/xHal_Rpi5CarTrafficCrossAppTest.py --node xWalk-rpi5-node/build-host/cmake/xwalk --build-dir xWalk-rpi5-node/build-host/cmake --fixture-llm
```

Physical Android GUI, camera, SSH and lifecycle tests still require a device. Live Pi sensor sessions publish
episode advisories, not the periodic replay risk feed.

### Hardware tests

`XWALK_NODE_CORE_MATRIX_HARDWARE_TESTS` (default OFF) registers `xWalkNodeCoreMatrixHardwareTest`
(`hardware;concurrency`, 900 s) and `xWalkTrafficCoreMatrixHardwareTest` (`hardware;concurrency;traffic`,
1200 s). Normal host CI never registers them. List them without running:

```bash
ctest --test-dir ../build-host/cmake -N -L hardware
```

`xWalkTrafficCoreMatrixHardwareTest` extends the real-Pi matrix to all 15 combinations of service, vehicle
sensors, vision streaming, and voice. Two independent Python app MQTT subscribers must receive matching, validated,
non-retained traffic observations after each combination starts, within 15 seconds of its completion. Both must
also receive at least one matching `traffic-` announcement through the SoundReq broadcast topic during the run;
missing broadcasts fail the test. Matrix announcement FIFO checks exclude unrelated traffic announcements.

Prepare the intended Pi with its deployed Node, shared camera service, and independent `xWalkTrafCtrl` using the
Pi configuration, CSI input, and trained Hailo HEF. Use a controlled scene that generates an announcement and an
isolated test broker and account with no other traffic publishers. The test observes these services; it does not
install, start, or replace them. MQTT evidence alone does not prove which camera or inference backend produced an
observation; inspect Pi deployment logs separately for CSI and Hailo initialization. No real pedestrian or
vehicle should be put at risk to create the test scene.

Hardware execution requires explicit approval and confirmation that the correct Pi and Robot HAT are connected
and safe. The test activates the node, reads sensors, streams the camera, and plays speech; it requests camera and
lifecycle STOP in cleanup. It sends no motor commands. Only after that authorization, from this module directory:

```bash
cmake --preset host -DXWALK_NODE_CORE_MATRIX_HARDWARE_TESTS=ON
ctest --test-dir ../build-host/cmake -R '^xWalkTrafficCoreMatrixHardwareTest$' --output-on-failure
cmake --preset host -DXWALK_NODE_CORE_MATRIX_HARDWARE_TESTS=OFF
```

Results are written to `traffic-core-matrix-hardware.json` and `traffic-core-matrix-hardware.traffic.json` in the
build directory. The default Python app path is the sibling `xWalkPiCarApp/xWalk-pcx86-app`; override
`XWALK_CORE_MATRIX_PYTHON` for another environment. Direct script execution additionally requires
`--safe --traffic`, `--output`, and the Python app import path.

`xWalkTrafficHardwareProbeHostTest` checks bounded evidence storage, matching receivers, stale and mismatched
packets, missing announcements, and observation timeout without accessing a broker or hardware. Android
production subscription and decoding remain covered by `xWalkTrafficCrossAppHostTest`; the hardware case uses
Python receivers and does not claim Android device or UI execution.

## 9. Dependencies

- [xWalk-rpi5-hw](../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalk-rpi5-hw.md): added as the `hardware` subdirectory in full
  compositions (`XWALK_BUILD_ALL_BACKENDS=ON`; `XWALK_BUILD_RPI` follows the `rpi5` target).
- [xWalk-rpi5-iw](../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md): IW schemas, `xWalkIwProtobuf` and signal registries.
- [xWalk-rpi5-trace](../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md): `xWalkTrace` diagnostics and terminal help.
- Eclipse Paho MQTT C 1.3 with the TLS `paho-mqtt3cs` library, OpenSSL, Threads and Python 3.
- TLS tests: Mosquitto, `mosquitto_passwd` and OpenSSL executables.

## 10. Safety and constraints

- Wait for the matching successful `LifeMoveCfm` with state `XWALK_LIFE_STATE_ACTIVE` before requesting
  movement. The Controller keeps its ACTIVE requirement, commissioning limits, and other safety checks.
- Only one `xwalk` hardware owner should run per robot. Stop with Ctrl+C or SIGTERM; shutdown cancels operations
  and joins workers. See [shared hardware and camera deployment](../xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md)
  before running traffic alongside IoT.
- Parent-process death cannot guarantee physical actuator cleanup; the process split does not provide an
  independent hardware watchdog. Shared broker, network, CPU and hardware bus limits remain; separate PIDs do not
  guarantee real-time isolation.
- Do not share passwords in logs or screenshots, and never commit netrc files or broker account data.
- Hardware tests are opt-in and require explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalk-rpi5-node](../xWalk-rpi5-node.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl/xWalkTrafCtrl.md)
- [xWalkController](../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)
- [Deployment Tool](../../../06-xwalk-tool/xWalk-rpi5-tool/shell-agent/deploy-tool/Deployment%20Tool.md)

---

[Previous page](../xWalk-rpi5-node.md) · [Chapter index](../../index.md) · [Next page](xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md)
