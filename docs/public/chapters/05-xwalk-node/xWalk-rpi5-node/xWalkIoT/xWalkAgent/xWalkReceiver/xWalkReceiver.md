<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkReceiver

**5. xWalk node &middot; Module 15**

<!-- xwalk-page-header:end -->

# xWalkReceiver

`xWalkReceiver` is the receiving side of the xWalk node Agent. It decodes the 38 IW request messages into
generated plain structures for the Controller interface, encodes and sends confirmations (CFM) and rejections
(REJ) towards clients, and provides the `XWalkControllerResponse` adapter that publishes Controller completions.

## 1. Overview

The Agent provides four functionally named classes and four admin entry points. Every admin uses a
signal-number switch to select one private handler. Switch cases use the `XWALK_*_REQ` macros from the generated
`xHal_Rpi5CarGpbSigReq.h`. Handlers decode received Protobuf bytes directly into the `plain::*Req` structures
from the generated `xHal_Rpi5CarXIwMessageReq.h`, trace the copied fields and update their owned received-request
queues. The production Node runtime then calls `submitControllerRequest()` to enqueue the matching typed structure
on its attached Controller. A `true` return means local preparation succeeded; it does not acknowledge hardware
execution.

| Suggested CPU | Class | Admin method | Request messages |
| --- | --- | --- | --- |
| 0 | `XWalkServiceAgent` | `adminService()` | 9 service requests |
| 1 | `XWalkVehicleAgent` | `adminVehicle()` | 12 vehicle requests |
| 2 | `XWalkVisionAgent` | `adminVision()` | 7 vision requests |
| 3 | `XWalkVoiceAgent` | `adminVoice()` | 10 voice requests |

- Service: LifeMove, Health, Version, Unknown, Help, Doctor, TraceEnable, Spi, AppCtrl.
- Vehicle: I2c, Move, Turn, Camera, Sensor, Keyboard, Avoid, Cliff, LineTrack, SelfDrive, ServoZero, Calibrate.
- Vision: Vision, VideoRecord, VideoStream, Stare, BullFight, Treasure, VideoCar.
- Voice: Sound, BgMusic, VoiceChat, LlmTest, VisionTalk, ActiveCar, GptCar, VoiceCtrl, VoicePrompt, StoryRobot.

All listed names have the `Req` suffix. The CPU column records the proposed responsibility split;
these classes create no threads and set no CPU affinity.

The sibling [xWalkTransmitter](../xWalkTransmitter/xWalkTransmitter.md) encodes outgoing requests and tracks
confirmations and rejections using client IP, mailbox, local repetition index and functional module ID.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkAgent/xWalkReceiver` —
source directory

## 3. Directory layout

```text
xWalkReceiver/
    CMakeLists.txt     Agent, CFM, Reject and ControllerResponse libraries and their host tests
    xWalkRequest/
        include/       Dispatch, dispatch support, macros, message copy and four functional Agent headers
        src/           Dispatch entry, per-function dispatch, decode, copy and Agent implementations
    xWalkCfm/
        include/       XWalkCfmSender, CFM encoder and CFM macros
        src/           CFM encoding and sending
    xWalkReject/
        include/       XWalkRejectSender, Reject encoder, macros and XWalkControllerResponse
        src/           Reject encoding, sending and Controller response and completion adapters
    test/
        include/       Agent and ControllerResponse test-support headers
        src/           Agent, CFM, Reject, ControllerResponse and ControllerCompletion tests
```

Request routing is split into `xHal_Rpi5CarServiceDispatch.cpp`, `xHal_Rpi5CarVehicleDispatch.cpp`,
`xHal_Rpi5CarVisionDispatch.cpp` and `xHal_Rpi5CarVoiceDispatch.cpp`, with helper declarations in
`xHal_Rpi5CarAgentDispatchSupport.h`. `xHal_Rpi5CarAgentDispatch.cpp` retains the public `dispatchAgentRequest()`
entry point. Each helper distinguishes an unrecognized signal from a failed handler, so an invalid request stops
at its owning group. Unknown signals produce one shared Agent warning.

## 4. Public interface

| Target | Alias | Public headers | Content |
| --- | --- | --- | --- |
| `xWalkNodeAgent` | `xWalk::NodeAgent` | `xWalkRequest/include` | Functional Agents and `dispatchAgentRequest()` |
| `xWalkNodeCfm` | `xWalk::NodeCfm` | `xWalkCfm/include` | `XWalkCfmSender` for all 38 CFM types |
| `xWalkNodeReject` | `xWalk::NodeReject` | `xWalkReject/include` | `XWalkRejectSender` for all 38 REJ types |
| `xWalkControllerResponse` | — | `xWalkReject/include` | Controller completion and diagnostic publisher |

### MQTT boundary

The MQTT callback provides topic, payload and byte count. It does not provide a transmitted signal number: the IW
`cxx_signal` option is schema metadata and is not embedded in serialized requests. The Agent therefore does not
guess a request type from the first Protobuf field or change the wire format. A transport adapter supplies the
resolved signal explicitly:

```cpp
#include "xHal_Rpi5CarAgentDispatch.h"

// service, vehicle, vision, and voice are long-lived functional class instances.
// receivedSignalNumber comes from the application's agreed message framing.
const xwalk::node::XWalkAgentRequest request{
    service, vehicle, vision, voice, receivedSignalNumber, mqttMessage->payload, mqttMessage->payloadSize};
const bool copied = xwalk::node::dispatchAgentRequest(request);
```

`XWalkAgentRequest` groups borrowed owner references, the signal, payload and byte count.
`dispatchAgentRequest()` chooses exactly one of the four admin methods. Confirmation, rejection and unknown
signals return `false`. The raw `xwalk` receive callback is not automatically wired to command dispatch; envelope
or topic-based signal framing remains a separate transport decision.

### Local ownership and validation

Each admin returns `true` after successful decoding and copying, or `false` for rejected input. Each functional
class directly owns the corresponding generated `plain::*Req` structures and two fixed 64 KiB byte buffers. No
Agent snapshot, mailbox, group enum, schema table, binding or message wrapper is used.

A handler creates its concrete `xwalk::iw::v1::*Req` from the IW module and parses the encoded MQTT payload with
native Protobuf. Typed copy functions read the generated getters and assign the generated plain fields, including
optional presence and nested messages. Strings and bytes are copied into class-owned storage; their views never
depend on temporary Protobuf objects or the MQTT receive buffer.

Successful copying commits the new request; failure preserves the last successful request. Use a typed accessor
such as `vehicle.messageMoveReq()` to obtain the generated `plain::MoveReq`. It returns null before a successful
MoveReq or when another request type was most recently committed. Encoded input is bounded to 64 KiB
(`XWALK_AGENT_PAYLOAD_MAX_BYTES`) and recursion to 16 (`XWALK_AGENT_MAX_DEPTH`). Copying rejects invalid enum
values, non-finite doubles and exhausted byte storage. The typed copy functions must be updated when IW fields
change.

### Shared send arguments

Requests, confirmations and rejections share `xWalksSignal` from
[xWalkMqttTypes](../../xWalkMqttCommon/xWalkMqttTypes/xWalkMqttTypes.md). It contains `signal`, `topic`, `qos` and
`void* payload`. The pointer must reference the generated plain message type matching the signal; each send
function casts it internally. Null payloads and unknown signals are rejected before casting. Set `message.topic`
explicitly to the response topic for CFM and REJ; the shared struct defaults to the request topic. The structure is
owned by `xWalk-rpi5-hw/xWalkLibrary/common/include/xHal_Rpi5CarSignalTypes.h`; hardware-library consumers use
`xwalk::hal::xWalksSignal`, and the node exposes the same type as `xwalk::node::xWalksSignal`.

### Confirmations towards the client

`XWalkCfmSender` provides `sendCfm()` dispatch for all 38 generated confirmation structures. Each typed sender
checks its matching `XWALK_*_CFM` signal, converts the plain structure into the native IW Protobuf message and
sends one encoded message through `HiveMQServer::respond()`. Responses are never retained. A caller can supply its
client response topic and QoS 0, 1 or 2.

```cpp
#include "xHal_Rpi5CarCfmSender.h"

using xwalk::node::XWalkCfmSender;
XWalkCfmSender confirmations(server); // Existing HiveMQServer must outlive this sender.
XWalkCfmSender::MoveCfm response{};
// Assign the response fields supplied by your caller before sending.
xwalk::node::xWalksSignal message{XWALK_CNTRL_MOVE_CFM, XWALK_MQTT_DEFAULT_RESPONSE_TOPIC, 1, &response};
const bool sent = confirmations.sendCfm(message);
```

The sender uses the supplied status, result and client-address fields directly and does not modify them. There is
no automatic mapping from a client-address field to an MQTT topic. The signal selects the sender locally; it is
not prepended to the payload. The encoder bounds the encoded message to 64 KiB (`XWALK_CFM_MAX_BYTES`). Invalid
views, enum values, non-finite numbers, insufficient output space, invalid send arguments and disconnected
transport fail. `sendCfm()` returns the transport result; a timeout does not prove the broker never received the
message.

### Rejections towards the client

`XWalkRejectSender` provides `sendReject()` dispatch for all 38 generated rejection structures with the same
explicitly selected response topic, configurable QoS 0–2, non-retained publication, 64 KiB bound
(`XWALK_REJECT_MAX_BYTES`), borrowed-view lifetime and validation rules as confirmations. Receiving a request does
not automatically generate a rejection.

```cpp
#include "xHal_Rpi5CarRejectSender.h"

using xwalk::node::XWalkRejectSender;
XWalkRejectSender rejections(server); // Existing HiveMQServer must outlive this sender.
XWalkRejectSender::MoveRej response{};
response.detail = {"Request rejected", 16U};
xwalk::node::xWalksSignal message{XWALK_CNTRL_MOVE_REJ, XWALK_MQTT_DEFAULT_RESPONSE_TOPIC, 1, &response};
const bool sent = rejections.sendReject(message);
```

### Controller response adapter

Boot owns Controller execution and shared-device arbitration. Node owns `XWalkControllerResponse`, which borrows a
connected `HiveMQServer`, encodes typed completions and Controller warning or error records with the IW schemas,
and publishes them with QoS 1. `rejectWrongServer()` publishes a request's typed rejection with
`XWALK_ERROR_SIGNAL_WRONG_SERVER`, echoing its complete client address; an undecodable request falls back to its
signal's `...Rej` schema, or an unaddressed `TraceRej` for an unknown signal. The Node-only module build omits this
adapter.

### Tracing

`XWALK_XAGENT_TRACE_UIDn` is registered in `xWalk-rpi5-trace` with the `XAGENT` tag. The trace module owns field
traversal, formatting, escaping and output in `xWalk-rpi5-trace/src/xHal_Rpi5CarTraceAgentMessage.cpp`; its
optional `xWalkTraceAgent` target reads the generated plain request structures without depending on Agent-owned
types. Each handler emits its copied fields through `XWALK_XAGENT_TRACE_UID1` using the trace module's
`XAGENT_FORMAT()` macro, with one unique identifier from `XAGENT.101` through `XAGENT.138`. Enable selected IDs or
the `XAGENT` module through the existing trace controls; these classes have no private trace-enable flag.

Strings are escaped so control characters cannot create forged log lines. Byte fields are hexadecimal. Formatted
request text uses a per-thread 8 KiB buffer, valid until the next formatting call on that thread. Long values are
shortened with `...` and the original byte count remains visible. Malformed-input warnings use the shared warning
path and do not dump rejected payload data.

## 5. Build

Run from `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT -B build-host/agent-check -DXWALK_MQTT_BUILD_HOST_TESTS=ON -DXWALK_MQTT_BUILD_TLS_TESTS=OFF -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/agent-check --parallel 4
```

The Agent can also be configured independently; it adds the common library, trace, IW, MQTT common, MQTT server
and, outside module builds, Controller projects when those targets are absent:

```bash
cmake -S xWalkIoT/xWalkAgent/xWalkReceiver -B build-host/agent-only -DXWALK_AGENT_BUILD_HOST_TESTS=ON
```

```bash
cmake --build build-host/agent-only --parallel 4
```

| CMake option | Default | Meaning |
| --- | --- | --- |
| `XWALK_AGENT_BUILD_HOST_TESTS` | `OFF` | Build bounded Agent copy and dispatch tests |
| `XWALK_WORKSPACE_ROOT` | `../../../..` | Workspace root used for sibling projects |

## 6. Testing

| CTest name | Labels |
| --- | --- |
| `xWalkNodeAgentHostTest` | `host;mqtt;node;agent;protobuf` |
| `xWalkNodeCfmHostTest` | `host;mqtt;node;cfm;protobuf` |
| `xWalkNodeRejectHostTest` | `host;mqtt;node;reject;protobuf` |
| `xWalkControllerCompletionHostTest` | `host;controller;protobuf` (not in module builds) |
| `xWalkControllerResponseHostTest` | `host;controller;protobuf` (not in module builds) |

```bash
ctest --test-dir build-host/agent-check --output-on-failure
```

Tests populate all 38 requests and check copied fields, optional presence, nested values and ownership after
overwriting the encoded MQTT input. The confirmation and rejection tests cover empty and populated messages for
all 38 types against native Protobuf decoding, nested fields and binary content, malformed views, oversized input,
small output buffers, unknown signals, null payloads, invalid QoS and sending without a connection. The completion
tests check all 76 CFM and REJ encoders, including routing metadata. Host tests do not connect to HiveMQ or access
Raspberry Pi hardware; live broker delivery is not covered.

## 7. Dependencies

- `xWalkLibraryCommon` and `xWalkMqttMessageQueue` (Agent, public); `xWalkTraceAgent` and `xWalkIwProtobuf`.
- `xWalkMqttTypes` and `xWalkMqttServer` (CFM and Reject, public); `xWalkTrace` and `xWalkIwProtobuf`.
- `xWalkController`, `xWalkMqttServer` and `xWalkIwProtobuf` (ControllerResponse, public).

## 8. Safety and constraints

- Each Agent instance requires external serialization of its admin calls and snapshot readers. Separate instances
  own separate storage. Do not concurrently run competing vehicle behaviors or open the same camera or audio
  device independently; composite behaviors must send work to the corresponding hardware owner through the
  Controller interface.
- Pointers returned by typed accessors and their views are borrowed and valid only until the next admin call or
  owner destruction. Copy pointed-to data if it must outlive that boundary.
- A `void*` payload cannot validate the actual object type; never supply a mismatched object.
- The `HiveMQServer` must outlive every sender and the Controller response adapter must outlive the Controller.
- Request strings and byte data may contain application-sensitive values; enable diagnostic traces only when
  appropriate.

## 9. Related notes

- [xWalkTransmitter](../xWalkTransmitter/xWalkTransmitter.md)
- [xWalkMqttQueue](../../xWalkMqttCommon/xWalkMqttQueue/xWalkMqttQueue.md)
- [xWalkMqttServer](../../xWalkMqttServer/xWalkMqttServer.md)
- [xWalkMqttNode](../../xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md)
- [xWalkController](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- [xWalkIoT](../../xWalkIoT.md)

---

[Previous page](../../xWalkMqttServer/xWalkMqttServer.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkTransmitter/xWalkTransmitter.md)
