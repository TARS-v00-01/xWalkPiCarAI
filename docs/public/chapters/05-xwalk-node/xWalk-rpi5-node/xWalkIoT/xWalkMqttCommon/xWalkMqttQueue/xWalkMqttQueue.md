<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkMqttQueue

**5. xWalk node &middot; Module 10**

<!-- xwalk-page-header:end -->

# xWalkMqttQueue

`xWalkMqttQueue` provides the bounded, thread-safe, in-process FIFOs of the xWalk node: three independent
received-message queues for Requests, confirmations (CFM) and rejections (REJ), plus a separate outgoing backend
queue with a C-compatible API.

## 1. Overview

| Message family | Class | Process-owned queue | Header |
| --- | --- | --- | --- |
| Request | `XWalkRequestQueue` | `requestMessageQueue()` | `xHal_Rpi5CarMqttRequestQueue.h` |
| Confirmation | `XWalkCfmQueue` | `cfmMessageQueue()` | `xHal_Rpi5CarMqttCfmQueue.h` |
| Rejection | `XWalkRejectQueue` | `rejectMessageQueue()` | `xHal_Rpi5CarMqttRejectQueue.h` |
| Outgoing backend input | `XWalkBackendQueue` | `backendMessageQueue()` | `xHal_Rpi5CarMqttBackendQueue.h` |

Each queue has its own storage, mutex and 64-message capacity, and each received queue accepts only its own
generated signal family. The combined `responseMessageQueue()` API has been removed; consumers read
confirmations and rejections separately. `XWalkMessageQueue` provides shared storage internally and cannot be
constructed directly. FIFO order is preserved within each queue; there is no ordering guarantee across queues.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttQueue` —
source directory

## 3. Directory layout

```text
xWalkMqttQueue/
    CMakeLists.txt     xWalkMqttMessageQueue library and four host test executables
    include/           Shared storage, family queues, backend queue and C backend API headers
    src/               Queue implementations and the C backend functions
    test/
        include/       <Queue>TestSupport.h fixtures for message, request, reject and backend tests
        src/           Queue host tests and their support sources
```

## 4. Public interface

All queue classes expose `push(signal, payload, length)`, `pop(signal, payload, capacity, length)` and `size()`.
For example, to read one confirmation:

```cpp
#include "xHal_Rpi5CarMqttCfmQueue.h"

unsigned char payload[XWALK_MQTT_QUEUE_PAYLOAD_MAX_BYTES]{};
xwalk::hal::uint32 signal = 0U;
size_t length = 0U;
const bool received = xwalk::node::cfmMessageQueue().pop(signal, payload, sizeof(payload), length);
```

- Each entry owns the signal number and the exact encoded Protobuf bytes, including binary zeroes, optional,
  nested and unknown fields. It never retains pointers into a decoder object or MQTT receive buffer. Consumers
  select the IW Protobuf schema from the signal and decode its fields.
- `pop()` copies and removes the oldest message. A short output buffer returns false with the required length
  and head signal, preserving the queued message. An empty queue returns false with signal and length zero.
- Multiple consumers compete for entries; the queues do not broadcast an entry to every consumer.
- `push()` validates the signal family, pointer and byte bound; callers remain responsible for Protobuf
  validation.

The C-compatible
`xHal_Rpi5CarMqttBackend.h`
(include)
exposes `xwalk_backend_enqueue` and the independent `xwalk_request_dequeue`, `xwalk_cfm_dequeue` and
`xwalk_reject_dequeue` functions. Return 1 means success; 0 means invalid input, an empty queue or an
insufficient dequeue buffer. A short buffer reports the required length without removing the entry. Signal and
length output pointers are required.

The backend queue accepts any generated Request, CFM or Reject signal. The runtime subsequently enforces the
selected functionality and validates and encodes before publishing. It has its own 64-message capacity, bounded
copies, mutex, traces and process-fatal overflow policy, and never reads from the received queues. See the
[node note](../../xWalkIoT.md) for operating modes and backend integration.

CMake exports the static library as `xWalkMqttMessageQueue` with the alias `xWalk::MqttMessageQueue`.

### Decoder integration

All 38 receiver request handlers enqueue once after successful native decoding and copying into generated local
structures. Direct handler calls, functional admin calls and `dispatchAgentRequest()` share that path. Malformed
or rejected requests do not enter any queue. Sending a request alone does not enqueue an update.

The 38 CFM decoder paths enqueue only into `cfmMessageQueue()` and the 38 REJ paths only into
`rejectMessageQueue()`. Valid Protobuf and client-address presence are required. Enqueue occurs before
pending-request completion is attempted. Valid unmatched or duplicate responses remain available to consumers
without completing an unrelated pending request.

The legacy raw-topic CLI callback remains print-only. Typed `queue` and `json` modes resolve the signal from an
exact topic suffix, then invoke request handlers or response decoders. No type is guessed from GPB bytes.

## 5. Configuration

`xHal_Rpi5CarMqttMessageQueueMacros.h` in [xWalkMqttTypes](../xWalkMqttTypes/xWalkMqttTypes.md) defines 64
messages per queue and a 64 KiB maximum per message. The three received queues can hold 192 messages in total.

## 6. Testing

Run from `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT -B build-host -DXWALK_MQTT_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host --parallel 4
```

```bash
ctest --test-dir build-host -L queue --output-on-failure
```

| CTest name | Labels | Enabled by |
| --- | --- | --- |
| `xWalkMqttMessageQueueHostTest` | `host;mqtt;queue` | MQTT or Transmitter host tests |
| `xWalkMqttRequestQueueHostTest` | `host;mqtt;queue;request` | MQTT or Agent host tests |
| `xWalkMqttRejectQueueHostTest` | `host;mqtt;queue;reject` | MQTT or Transmitter host tests |
| `xWalkMqttBackendQueueHostTest` | `host;mqtt;queue;backend` | MQTT host tests |

Host tests cover owned binary copies, FIFO order, short buffers, wraparound and concurrent producers for each
queue. Isolated subprocesses verify process-fatal overflow. Isolation tests fill all three received queues at
once and reject cross-family inputs. Agent tests cover all 38 request types; transmitter tests cover all 76
response types. No live broker or hardware is required.

## 7. Dependencies

- [xWalkMqttTypes](../xWalkMqttTypes/xWalkMqttTypes.md) and POSIX threads (public).
- `xWalkTrace` (private).

## 8. Safety and constraints

- Payload storage is allocated on push and freed on pop or normal destruction. Stop all callers before
  destroying a queue; never delete a process-owned instance.
- All queues reuse the registered `MQTTUL.011`–`MQTTUL.013` events for insertion, removal and short reads. The
  generated signal identifies the message family. Trace callbacks run after releasing the queue mutex.
- If a valid message arrives at its full queue, the shared trace module emits `XWALK_MQTT_ERROR` identifying the
  queue, then `_Exit(EXIT_FAILURE)` terminates the whole process. Allocation failure follows the same policy.
  Trace output is flushed synchronously; ordinary destructor-based MQTT shutdown is skipped. Consumers must
  drain each queue independently to prevent overflow.
- The queues live in the C++ process and are not persistent. A separate Android app or Python process needs a
  binding or IPC adapter that calls the appropriate `pop()` method and exposes its signal and bytes; no such
  bridge or cross-process protocol is implemented here.

## 9. Related notes

- [xWalkMqttCommon](../xWalkMqttCommon.md)
- [xWalkReceiver](../../xWalkAgent/xWalkReceiver/xWalkReceiver.md)
- [xWalkTransmitter](../../xWalkAgent/xWalkTransmitter/xWalkTransmitter.md)
- [xWalkMqttNode](../xWalkMqttNode/xWalkMqttNode.md)

---

[Previous page](../xWalkMqttNode/xWalkModule/xWalkModule.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkMqttTypes/xWalkMqttTypes.md)
