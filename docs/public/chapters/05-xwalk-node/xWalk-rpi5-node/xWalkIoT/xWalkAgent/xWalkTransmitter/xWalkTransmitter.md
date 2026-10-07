<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkTransmitter

**5. xWalk node &middot; Module 16**

<!-- xwalk-page-header:end -->

# xWalkTransmitter

`xWalkTransmitter` is the sending side of the xWalk node Agent. `XWalkTransmitter` encodes all 38 generated
request structures with the native IW Protobuf classes, stamps their routing identity, publishes them through an
existing `HiveMQServer` and completes pending requests when the matching confirmation (CFM) or rejection (REJ)
arrives.

## 1. Overview

`XWalkTransmitter` fills the existing `ClientAddr` fields directly inside the caller's mutable request structure.
`sendRequest()` takes an `xWalksSignal` argument group with `signal`, `topic`, `qos` and `void* payload`. The
signal selects a private typed sender, which casts the pointer (for example to `DoctorReq*`) and updates its
`clientAddress` and `has_clientAddress` fields; command fields are preserved.

| Field | Meaning |
| --- | --- |
| `clientAddress` | Numeric IPv4 or IPv6 client address, copied and canonicalized at construction; not the broker |
| `server_ip` | Target node address stamped into every request; defaults to the client itself |
| `mail_box_id` | Increasing message number within the functional module |
| `xwalk_local_index` | Lowest free repetition slot for pending requests of the same command, starting at 1 |
| `module_type` | Functional module ID selected from the request signal |

| Module macro | ID | Functional owner | Suggested CPU |
| --- | --- | --- | --- |
| `XWALK_TX_SERVICE` | 1 | Service | 0 |
| `XWALK_TX_VEHICLE` | 2 | Vehicle | 1 |
| `XWALK_TX_VISION` | 3 | Vision | 2 |
| `XWALK_TX_VOICE` | 4 | Voice | 3 |

The functional grouping matches [xWalkReceiver](../xWalkReceiver/xWalkReceiver.md). IDs identify functionality,
not physical CPU numbers. This library creates no threads and sets no CPU affinity.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkAgent/xWalkTransmitter` —
source directory

## 3. Directory layout

```text
xWalkTransmitter/
    CMakeLists.txt     xWalkNodeTransmitter library and its host test
    xWalkRequest/
        include/       XWalkTransmitter, request encoder and transmitter and request macros
        src/           Request encoding, construction, pending state and sending
    xWalkCfm/
        include/       XWalkCfmDecoder for all 38 incoming confirmations
        src/           CFM decoding and receiveCfm()
    xWalkReject/
        include/       XWalkRejectDecoder for all 38 incoming rejections
        src/           REJ decoding and receiveReject()
    test/
        include/       xHal_Rpi5CarTransmitterTestSupport.h
        src/           Transmitter host test and support
```

This mirrors `xWalkReceiver` with reversed message direction. `xWalkRequest` owns request encoding, sending and
pending state. `xWalkCfm` and `xWalkReject` decode native IW Protobuf responses and complete the exact pending
identity through the transmitter; they do not send responses.

## 4. Public interface

`xHal_Rpi5CarTransmitter.h`
(include)
declares `xwalk::node::XWalkTransmitter`. CMake exports the static library `xWalkNodeTransmitter` with the alias
`xWalk::NodeTransmitter`.

```cpp
#include "xHal_Rpi5CarTransmitter.h"

using xwalk::node::XWalkTransmitter;
// server is a connected, long-lived HiveMQServer. The first address is this client's own IP; the second is
// the target node stamped into every request as server_ip (omit it to target the client itself).
XWalkTransmitter transmitter(server, "192.0.2.10", "198.51.100.7");
XWalkTransmitter::MoveReq request{};
// Set the command's generated fields before sending.
xwalk::node::xWalksSignal message{XWALK_CNTRL_MOVE_REQ, XWALK_MQTT_DEFAULT_REQUEST_TOPIC, 1, &request};
const bool sent = transmitter.sendRequest(message);
const auto identity = request.clientAddress;
```

A second constructor accepts a C-style `XWalkRequestPublish` callback with a context instead of a server; custom
callbacks must support concurrent invocation.

Set a custom client topic and QoS in `message.topic` and `message.qos`. Defaults use the request topic and QoS 1.
All requests are non-retained. The IP field is routing metadata and does not select an MQTT connection or topic.
`request.clientAddress.clientAddress` borrows the transmitter's IP storage until destruction. Use one shared
transmitter instance for all callers in the same client routing domain; separate instances do not share mailbox
sequences or pending state.

### Receiving responses

The receiving application must echo the request's entire `ClientAddr` unchanged in its confirmation or rejection.
A response is accepted, queued and matched only when its `clientAddress` equals this client's IP and its
`server_ip` equals the transmitter's target. Any other response, including one without a client address, belongs
to another client or target: it is ignored without an error and reported only through the low-level
`XAGENT.213` trace, which names the echoed (empty when missing) and expected addresses.

```cpp
// responseSignal comes from the application's agreed signal framing or topic mapping.
const bool completed = transmitter.receiveResponse(responseSignal, mqttMessage->payload, mqttMessage->payloadSize);
const auto remaining = transmitter.pendingCount(XWALK_TX_VEHICLE, XWALK_CNTRL_MOVE_REQ);
```

`receiveResponse()` decodes the concrete CFM or REJ using the generated signal macros. It releases one entry only
when the request family, IP, module, mailbox and local index match. Wrong, malformed and duplicate responses leave
pending state unchanged. All 38 CFM and 38 REJ signal paths are supported. Applications may call `receiveCfm()`
or `receiveReject()` directly when the response family is already known; each rejects other signal families.
`receiveResponse()` remains a compatibility entry point delegating to those two methods.

The MQTT callback supplies raw bytes and a topic without a signal number, so these APIs are ready for the
application's receive adapter; the raw `xwalk` CLI is not automatically wired to typed request or response
dispatch. No wire envelope or signal-prefix format is introduced.

Every valid CFM or REJ is also copied into the shared CFM or Reject queue of
[xWalkMqttQueue](../../xWalkMqttCommon/xWalkMqttQueue/xWalkMqttQueue.md), including unmatched and duplicate valid
responses; `receiveResponse()` still returns true only when a pending request completes. Each queue holds 64
messages; overflow logs an error and terminates the process with failure.

### Pending repetitions

| Event for one command | Allocated local index | Pending count |
| --- | --- | --- |
| Send first request | 1 | 1 |
| Send again before a reply | 2 | 2 |
| Receive CFM or REJ for index 1 | Slot 1 released | 1 |
| Send again | 1 reused with a new mailbox number | 2 |

Completing an earlier request does not renumber later requests already on the wire. Mailbox numbers are not
decremented or reused, so a late duplicate reply cannot complete a newer request in the same slot.

Each instance starts its mailbox sequence at a random offset below `XWALK_TX_MAILBOX_BASE_LIMIT` (2^30). Separate
client processes on one host share an IP, so without this a late reply to another or an earlier process would
carry a valid mailbox. Tests pass an explicit `mailboxBase` of zero for fixed numbering. The desktop and Android
clients use the same rule.

Pending capacity is 64 requests per module (`XWALK_TX_PENDING_PER_MODULE`). Sends fail when a module is full or
its 32-bit mailbox sequence is exhausted; sequences never wrap. There is no automatic expiry, retry or persistence
across destruction or process restart. Before replacing an instance, drain its requests; the random mailbox start
keeps old responses from matching the new instance.

Encoding failures release the allocated slot and clear `request.clientAddress` and `request.has_clientAddress`.
If the publisher returns false, the request stays pending because an MQTT timeout can mean unknown delivery.
Inspect `request.clientAddress` and await a response, or use `cancelPending(requestSignal, identity)` only when
the application decides it is safe to abandon that request. A successful MQTT publish means transport completion,
not command completion.

## 5. Build

Run from `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT -B build-host -DXWALK_MQTT_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host --parallel 4
```

The project can also be configured on its own with `XWALK_TRANSMITTER_BUILD_HOST_TESTS=ON`; it then adds the MQTT
server, IW and MQTT common projects when those targets are absent.

| CMake option | Default | Meaning |
| --- | --- | --- |
| `XWALK_TRANSMITTER_BUILD_HOST_TESTS` | `OFF` | Build request encoding and pending-state host tests |

## 6. Testing

| CTest name | Labels |
| --- | --- |
| `xWalkNodeTransmitterHostTest` | `host;mqtt;node;transmitter;protobuf` |

```bash
ctest --test-dir build-host -L transmitter --output-on-failure
```

Host tests cover all 38 request encodings, all 76 response paths, IPv4 and IPv6 identity, out-of-order and
duplicate responses, slot reuse, independent module capacity, invalid inputs, uncertain publication and
concurrent sends with synchronous responses. They do not connect to HiveMQ or operate Raspberry Pi hardware.

## 7. Dependencies

- `xWalkMqttServer` and `xWalkMqttMessageQueue` (public).
- `xWalkTrace` and `xWalkIwProtobuf` (private).
- The shared `xWalksSignal` type from [xWalkMqttTypes](../../xWalkMqttCommon/xWalkMqttTypes/xWalkMqttTypes.md),
  owned by `xWalk-rpi5-hw/xWalkLibrary/common/include/xHal_Rpi5CarSignalTypes.h`.

## 8. Safety and constraints

- `message.payload` must point to the generated plain request type selected by `message.signal`. A `void*` has no
  runtime type information; a mismatched object cannot be detected and must not be supplied. Null payloads and
  unknown signals are rejected before casting.
- Each concurrent send must use a separate mutable request object. If a request object is reused while its
  previous send is still pending, save the previous `clientAddress` first when explicit cancellation is needed.
- Pending-state operations use a mutex. Encoding, publishing and external callbacks run without that mutex, so
  synchronous responses and concurrent calls from multiple functional cores are supported. Stop all callers before
  destroying the transmitter.
- The server and any borrowed request views must remain valid throughout each call.

## 9. Related notes

- [xWalkReceiver](../xWalkReceiver/xWalkReceiver.md)
- [xWalkMqttQueue](../../xWalkMqttCommon/xWalkMqttQueue/xWalkMqttQueue.md)
- [xWalkMqttServer](../../xWalkMqttServer/xWalkMqttServer.md)
- [xWalkIoT](../../xWalkIoT.md)

---

[Previous page](../xWalkReceiver/xWalkReceiver.md) · [Chapter index](../../../../index.md) · [Next page](../../../xWalkTrafCtrl/xWalkTrafCtrl.md)
