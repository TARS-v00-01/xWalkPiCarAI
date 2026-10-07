<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [3. xWalk interface](../index.md) / xWalk-rpi5-iw

**3. xWalk interface &middot; Module 01**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-iw

`xWalk-rpi5-iw` owns the C++17 Google Protocol Buffers (GPB) interworking contract for xWalk I2C,
lifecycle, trace, traffic, and Controller command messages. It defines serialization only: it declares no
services or RPCs and performs no hardware access.

## 1. Overview

The signal schema defines stable message and trace identifiers, while the common schema defines the shared
client address and the I2C, sound, lifecycle, movement, camera, sensor, calibration, and trace selections.
Separate request, confirmation, and rejection schemas define the payloads and mirror the plain Controller
types declared in
`xWalkControllerConfigTypes.h`.
A separate traffic schema owns the crosswalk observation contract consumed by the traffic controller.

The module requires no gRPC runtime or generator plugin. Applications choose their own transport for the
concrete request, confirmation, and rejection messages.

## 2. Source location

`xWalk-rpi5-iw` (source directory)

## 3. Directory layout

```text
xWalk-rpi5-iw/
├── CMakeLists.txt                          Schema check, Protobuf library, interface target, host tests
├── cmake/
│   └── XWalkTrafficProtocol.cmake          xwalk_generate_traffic_protocol() helper for the traffic controller
├── config/
│   ├── xHal_Rpi5CarGpbSigReq.xml           Request signal mapping
│   ├── xHal_Rpi5CarGpbSigCfm.xml           Confirmation signal mapping
│   └── xHal_Rpi5CarGpbSigRej.xml           Rejection signal mapping
├── proto/
│   ├── xHal_Rpi5CarXIwSignal.proto         Signal, trace severity, and error selector enumerations
│   ├── xHal_Rpi5CarXIwMessageCmn.proto     ClientAddr and shared operation enumerations
│   ├── xHal_Rpi5CarXIwMessageReq.proto     Request messages and supporting DTOs
│   ├── xHal_Rpi5CarXIwMessageCfm.proto     Confirmation messages
│   ├── xHal_Rpi5CarXIwMessageRej.proto     Rejection messages, including TraceRej
│   └── xHal_Rpi5CarXIwTraffic.proto        Traffic observation contract (package xwalk.traffic.protocol)
└── test/src/
    └── xHal_Rpi5CarXIwHostTest.cpp         Generated Protobuf binding host test
```

## 4. Public interface

### Generated bindings

The executable source generator is
`xHal_Rpi5CarIwGenerator`. Generated
headers and sources must not be edited manually. CMake validates the source schemas on every build.

The generated Protobuf bindings are owned by their consumers, which keep identical tracked copies in
`xWalk-rpi5-node/xWalkIoT/auto-gen` and `xWalk-rpi5-hw/xWalkController/auto-gen`. A consumer sets
`XWALK_IW_GENERATED_DIRECTORY` to its own copy before adding this module; a standalone build of this module
uses the Controller copy. Configuration fails with a fatal error naming the missing file when any generated
`.pb.h` or `.pb.cpp` file is absent.

### Naming

Message names use no more than two PascalCase operation words. Transport flows append `Req`, `Cfm`, or
`Rej`; supporting DTOs use concise names such as `ClientAddr` and `MoveArg`. Field, signal, enumeration, and
package names remain unchanged. The `xwalk.iw.v1` schemas use proto3 defaults.

### Client addressing

`ClientAddr` mirrors the generated `xwalk::iw::v1::plain::ClientAddr` structure with a mailbox ID, client
address text, process-local xWalk index, numeric module type, and `server_ip` (field `5`). Every concrete
request, confirmation, and rejection message carries this routing metadata in its `clientAddress` field at
field number `15`.

Both addresses are filled automatically. `clientAddress` is the sender's local broker-connection address;
`server_ip` is the IPv4 address of the target node, resolved from the paired device. A node processes a
request only when `server_ip` equals its own address. An announcement (`SoundReq` operation
`XWALK_SOUND_OPERATION_ANNOUNCE`) or a voice-chat start may use `0.0.0.0` to reach every node without that
check. Any other request, including one with an empty `server_ip`, is rejected with its own `...Rej` message,
`reason` and `error_signal` `XWALK_ERROR_SIGNAL_WRONG_SERVER` (`27`), and a detail naming both addresses.
`LifeMoveRej`, `HealthRej`, and `VersionRej` carry no error selector, so they report `code`
`XWALK_LIFE_CODE_WRONG_SERVER` (`5`) instead.

A request with an invalid field value, such as an undefined enumeration, is not dropped: it is rejected with
`XWALK_ERROR_SIGNAL_INVALID_ARGUMENT` (`1`), or as wrong-server when it addresses another node. Responses
echo the complete address, so clients can match them.

### Standard responses and signal ranges

Each transported `Req` has a matching `Cfm` and `Rej`. Standard confirmations carry returned data,
responding state, a Boolean `flag`, and a human-readable `message`. Standard rejections carry returned data,
responding state, numeric `reason`, human-readable `detail`, and a stable error selector. Lifecycle messages
retain their operation-specific state, version, health, and error fields.

Separate request, confirmation, and rejection XML registries map each message to its stable signal:

| Range | Requests | Confirmations | Rejections |
| ----- | -------- | ------------- | ---------- |
| I2C | `0x1081` | `0x1082` | `0x1083` |
| Controller commands | `0x2000`–`0x2020` | `0x2100`–`0x2120` | `0x2200`–`0x2220` |
| Lifecycle and trace enable | `0x2090`–`0x2093` | `0x2190`–`0x2193` | `0x2290`–`0x2293` |

Supporting DTOs have no standalone signal bindings.

### I2C messages

| Category | Message | Fields | Signal |
| -------- | ------- | ------ | ------ |
| Request | `I2cReq` | Operation, address, register, length, data | `0x1081` |
| Success | `I2cCfm` | Data, responding, flag, message | `0x1082` |
| Rejection | `I2cRej` | Data, responding, reason, detail, error selector | `0x1083` |

`I2cReq` uses address `1` (seven-bit), register address `2`, length `3` (bytes), data `4`, and operation
`5`. The three signal identifiers are stable protocol values. The I2C payloads are transport-independent
DTOs.

### Lifecycle messages

The lifecycle messages describe typed state movement, health, and version flows that mirror the
transport-independent Driver contract. Controller command messages may retain `LifeArg` as a nested
start/stop DTO, but it is not a separate wire signal.

| Flow | Request signal | Cfm signal | Rej signal |
| ---- | -------------: | ---------: | ---------: |
| `LifeMove` | `0x2090` | `0x2190` | `0x2290` |
| `Health` | `0x2091` | `0x2191` | `0x2291` |
| `Version` | `0x2092` | `0x2192` | `0x2292` |

`XWalkLifeState` and `XWalkLifeCode` values are stable and never renumbered; new codes are only appended.
Request, Cfm, and Rej fields retain the same presence and proto3 defaults as the corresponding plain C++
structures. Service and outcome text is bounded by the adapter to 64 and 160 bytes respectively. Every active
outcome copies the complete requesting `ClientAddr` unchanged.

### Trace enable messages

`TraceEnableReq` (`0x2093`), `TraceEnableCfm` (`0x2193`), and `TraceEnableRej` (`0x2293`) transport changes
to normal trace selection. `scope` selects one registered UID, a registered module, or all normal traces. UID
and module selection require a nonempty `target`; all-trace selection requires an empty target. Unspecified
and unknown scopes are invalid. The optional `enabled` field must be present: `true` enables traces and
`false` disables them.

A handler must validate the request before invoking the trace module. A Cfm reports the applied selection and
state after success. A Rej echoes the requested selection and enabled-field presence with its reason and
error selector; it does not promise rollback after an update failure. Both outcomes copy `clientAddress`
unchanged. The standard response `data` field stays empty. Warning and error diagnostics remain independent
of normal trace selection. Dispatch and trace mutation belong to the receiving application adapter.

### Trace rejection message

`TraceRej` transports the error or warning values exposed by the trace callback. Its `severity` is
`XWALK_TRACE_SEVERITY_ERROR` or `XWALK_TRACE_SEVERITY_WARNING`, matching the corresponding public
`XWalkTraceLevel` numeric value. Its `error_signal` mirrors the stable `xwalk::hal::XWalkErrorSignalNumber`
selector value, while `message` contains the fully formatted callback text. Error selector values are
independent of platform POSIX signal numbers. This transport-only diagnostic has no request signal binding.

### Controller messages

The Controller support messages mirror the Controller-owned structures. They are nested or internal DTOs and
do not contain callbacks, service pointers, hardware objects, or runtime state. They do not own standalone
signal numbers or Cfm/Rej messages. Each public command owns one Req/Cfm/Rej signal triplet for its
operation.

The Controller enumeration values preserve the C++ declaration order. The command field remains an unsigned
integer because the Controller source owns those signals as `XWALK_CNTRL_*_REQ` macros rather than a C++
enum. The macros and their command-specific request messages share the contiguous signal range `0x2000`
through `0x2020`. Runtime service objects are not serialized into the public message contract.

Proto3 optional presence is retained for fields whose C++ defaults are not the scalar wire defaults. A
protocol adapter must apply the documented C++ defaults when those fields are absent and validate every value
before invoking a handler.

### Sensor requests

`SensorReq.request.type` accepts Distance (`0`), Grayscale (`1`), and Battery (`2`). Battery uses
`XWALK_SENSOR_TYPE_BATTERY` and the existing `SensorCfm` / `SensorRej` signal pair. Successful battery
responses carry JSON in `SensorCfm.message`:
`{"battery_voltage":7.2,"battery_percent":50,"estimated":true}`. Voltage is in volts; percentage is a clamped
integer estimate from configured voltage endpoints. No new signal or response layout is introduced; older
receivers can reject the new sensor enum value. Dedicated telemetry fields and responder identity remain
deferred protocol work.

### Autonomous mode motor power

`LineTrackReq`, `BullFightReq`, `TreasureReq`, `AvoidReq`, `CliffReq`, and `StareReq` add optional
`motor_power_percent` (field `2`) and `update_motor_power` (field `3`). Existing field numbers and signals are
unchanged. A normal start may supply finite power from 0 through 100 percent; omission retains the mode's
original default. Update-only requests require power and a matching active operation. They never start a new
mode. Stop requests must omit power and leave the update flag false.

The corresponding Cfm messages add optional `motor_power_percent` (field `5`). A successful update returns the
accepted setting with the original client identity. Existing Rej messages report invalid values, missing
values, idle or wrong modes, a busy update slot, cancellation before application, and unsupported
capabilities. Face Tracking is camera-only: `StareReq` with the power field present or the update flag set is
rejected.

The Controller holds one pending update and applies it on the existing operation worker, retaining
shared-device ownership. The next driver movement decision uses the new value. A Cfm acknowledges a command
setting, not measured wheel speed or completion by every robot. Treasure Hunt also services updates during
terminal-input waits. Older Protobuf receivers may ignore these fields; deploy matching IW, Node, Controller,
and Driver revisions together.

### Stored spoken announcements

`SoundArg.operation = XWALK_SOUND_OPERATION_ANNOUNCE` (`4`) extends the existing `SoundReq` family. Fields
`4`, `5`, and `6` carry `announcement_id`, `announcement_title`, and `announcement_body`. The ID is 1–64 ASCII
letters, digits, hyphens, or underscores. Title and body must be nonblank, NUL-free UTF-8, bounded to 480 and
40000 bytes respectively. Existing sound operations are unchanged.

`SoundCfm.message` contains JSON with `announcement_id`, `stored: true`, and `spoken: true` to acknowledge
both steps; hosts must check the matching ID and both Boolean outcomes. `SoundRej` carries validation,
capacity, resource, or speech errors; storage can succeed before speech fails. Consumers must update their
generated interfaces and field-copy adapters together.

### Background video sessions

`VideoStreamReq` (`0x2020`), `VideoStreamCfm` (`0x2120`), and `VideoStreamRej` (`0x2220`) retain the
video-stream command payloads. `VideoStreamReq.background = true` (field `1`) starts an independently owned
CSI/MJPEG worker and confirms once camera and listener startup succeed. `stop = true` (field `2`) is valid
only with `background = true` and confirms cleanup of that background session. Both fields default to false,
preserving the existing foreground streaming command. The handwritten Node encode/decode adapters carry both
fields.

The background worker owns only the streaming camera and HTTP listener. Bounded vehicle requests, camera
angles, and sensor requests retain the ordinary Controller operation slot. Camera-consuming vision modes stop
the background worker before acquiring the camera. Lifecycle Stop, Controller shutdown, and capture failure
close its clients, listener, and camera. A successful start Cfm does not guarantee future camera
availability; later capture failures are traced and close the HTTP connection. The stream remains
loopback-only by default and the desktop accesses it through an authenticated SSH tunnel. Deploy updated IW
interfaces, Node adapters, and Controller together before using desktop background mode.

### Continuous manual movement

`MoveArg.continuous` (field `4`, default false) makes `duration_ms` a renewable lease of 200–1000 ms. A
successful `MoveCfm` with message `Continuous movement applied` acknowledges applied motor power while the
worker retains the device lease. Further continuous Move requests renew the lease and update power without
stopping between confirmations. Zero power stops the motors and ends the lease; shutdown and lost renewals
also stop output. No second response is emitted for an already acknowledged request when its lease expires.
Ordinary Move requests retain bounded pulse execution. Remote Treasure Hunt retains bounded pulses only.
Regenerate interfaces and update Node's receive/transmit adapters with the schema.

### Scoped Treasure Hunt cancellation

`TreasureReq.stop` (field `5`, default false) cancels only the matching Treasure Hunt operation. Send it
without a motor-power update; `TreasureCfm` acknowledges cleanup, while the interrupted start receives its
ordinary cancellation result. An idle stop is idempotent. Lifecycle state, independent announcement speech,
and service requests are preserved. Global lifecycle Stop retains its complete shutdown semantics. Deploy
regenerated interfaces and the matching Node receive/transmit adapters and Controller together.

### Traffic observation contract

`xHal_Rpi5CarXIwTraffic.proto` owns the
`TrafficObservation` message (package `xwalk.traffic.protocol`) formerly located in
`xWalkTrafCtrl/xWalkProtocol`. Its package and field numbers remain wire-compatible.

`XWalkTrafficProtocol.cmake` provides
`xwalk_generate_traffic_protocol(target, destination)`. The traffic controller's `xWalkProtocol` module calls
it with the controller's source-tree `auto-gen` directory. CMake runs `protoc` (Protobuf 3.15 or later) and
routes headers to `include/` and implementations to `src/` without a Python runtime or local generator
script. It also generates the existing signal, common, and request schemas needed for `SoundReq` /
`ANNOUNCE`. No new sound message or signal is introduced. Other consumers retain their existing generator
workflow.

### CMake targets

| CMake target | Responsibility |
| ------------ | -------------- |
| `xWalkIwSchemaCheck` | Validates Protobuf and XML source consistency on every build |
| `xWalkIwProtobuf` | Builds the generated public Protobuf messages as a static library |
| `xWalkIW` | Provides the public interface target |
| `xWalk::IW` | Provides the namespaced target alias |
| `xWalkIwProtobufHostTest` | Host test executable, built when `XWALK_IW_BUILD_HOST_TESTS` is `ON` |

## 5. Build

Required dependencies are CMake 3.16 or later, Python 3, a C++17 compiler, Protobuf development files, and
`protoc`.

```bash
cmake -S xWalk-rpi5-iw -B build-host/xwalk-iw -DXWALK_IW_BUILD_HOST_TESTS=ON
```

```bash
cmake --build build-host/xwalk-iw --parallel
```

### Validate and generate

Run these commands from the workspace root after changing a Protobuf or XML input:

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check
```

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-cpp
```

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-cpp
```

Generation requires `protoc`, the Protobuf development schemas, and `python3-protobuf`. `--generate-cpp`
updates the Protobuf bindings below `auto-gen/include` and `auto-gen/src` in both `xWalk-rpi5-node/xWalkIoT`
and `xWalk-rpi5-hw/xWalkController`, and also writes plain struct/enum and signal macro headers to Library
and MQTT Common. See the
[plain-header generator
contract](../../06-xwalk-tool/xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md#plain-iw-header-generation)
for destinations, borrowed storage, presence flags, and `--generate-headers` / `--check-headers` usage.

## 6. Configuration

The default Controller copy is `xWalk-rpi5-hw/xWalkController/auto-gen`.

| Option or variable | Default | Effect |
| ------------------ | ------- | ------ |
| `XWALK_IW_BUILD_HOST_TESTS` | `OFF` | Builds the host test executable and registers the CTest host tests |
| `XWALK_IW_GENERATED_DIRECTORY` | Controller `auto-gen` | Generated binding copy used by the build |

The tool root resolves to `xWalk-rpi5-tool`, or to `scripts/integration` when that directory exists beside
the module.

## 7. Testing

All tests are host tests:

```bash
ctest --test-dir build-host/xwalk-iw --output-on-failure
```

| CTest test | Labels | Checks |
| ---------- | ------ | ------ |
| `xWalkIwProtobufHostTest` | `host;protobuf;serialization` | Lifecycle defaults, Rej round trips, routing |
| `xWalkIwGeneratorHostTest` | `host;schema;generator` | Python unit tests of the IW generator |
| `xWalkIwSchemaHostTest` | `host;schema` | Generator `--check` of Protobuf and XML consistency |
| `xWalkIwBindingHostTest` | `host;schema;generator` | Fails on a missing or stale consumer binding copy |

The host tests validate the schema and signal mapping; compilation verifies generated C++ compatibility. They
do not open an I2C device or validate physical Robot HAT hardware. The module registers no hardware tests.

Build and verify the traffic-controller consumer from the integration directory:

```bash
cmake --preset host -S xWalk-rpi5-node/xWalkTrafCtrl
```

```bash
cmake --build xWalk-rpi5-node/xWalkTrafCtrl/build-host --parallel 4
```

```bash
ctest --test-dir xWalk-rpi5-node/xWalkTrafCtrl/build-host --output-on-failure
```

## 8. Dependencies

- Protobuf (`protobuf::libprotobuf`, `protoc`) and Python 3.
- `xWalkLibraryCommon` from [xWalkLibrary Common](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md),
  added automatically when the target does not already exist.
- `xWalk-rpi5-hw/xWalkLibrary/XWalkDependencies.cmake` for dependency resolution.
- The IW generator in [Developer Tool](../../06-xwalk-tool/xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md).

## 9. Safety and constraints

- `xWalk-rpi5-iw` performs no hardware access.
- Never edit generated bindings manually; regenerate them and keep both consumer copies identical.
- Signal identifiers, field numbers, and lifecycle enumeration values are stable; append new values only.
- Protocol changes require deploying matching IW, Node, Controller, and Driver revisions together.

## 10. Related notes

- [xWalkController](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)
- [xWalkDriver](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkDriver/xWalkDriver.md)
- [xWalkLibrary Common](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalkIoT](../../05-xwalk-node/xWalk-rpi5-node/xWalkIoT/xWalkIoT.md)
- [xWalkMqttCommon](../../05-xwalk-node/xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttCommon.md)
- [xWalkTrafCtrl](../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkTrafCtrl.md)
- [xWalkProtocol](../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkProtocol/xWalkProtocol.md)
- [xWalk-rpi5-trace](../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- [Developer Tool](../../06-xwalk-tool/xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md)

---

[Previous page](../index.md) · [Chapter index](../index.md) · [Next page](../../04-xwalk-software/index.md)
