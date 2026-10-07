<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkMqttServer

**5. xWalk node &middot; Module 14**

<!-- xwalk-page-header:end -->

# xWalkMqttServer

`xWalkMqttServer` is the MQTT transmit (TX) library of the xWalk node. `HiveMQServer` publishes encoded GPB
requests and responses through the caller-owned connection of a
[`HiveMQClient`](../xWalkMqttClient/xWalkMqttClient.md); it has no subscription or receive callback methods.

## 1. Overview

`HiveMQServer` owns application publication: `publish()` sends GPB bytes to a topic and `respond()` sends an
unretained response. In this node "server" names the TX role; the HiveMQ Cloud cluster remains the broker.
Connection configuration lives with the RX connection owner, so there is no duplicate server credential file
or second MQTT session.

| Group | Responsibility |
| --- | --- |
| Main source | Binary publication, validation and QoS completion waits. |
| Lifecycle | Non-owning connection binding. |
| Macros | Payload limit, publish timeout, retained default and TX trace IDs. |

The application supplies the GPB schema, command handling, correlation and response encoding. No commands are
executed automatically.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttServer` —
source directory

## 3. Directory layout

```text
xWalkMqttServer/
    CMakeLists.txt                          xWalkMqttServer library and xWalkMqttTxTest
    .clangd                                 Editor indexing settings
    include/
        xHal_Rpi5CarMqttServer.h            HiveMQServer TX class
        xHal_Rpi5CarMqttServerMacros.h      Payload limit, publish timeout and retained default
    src/
        xHal_Rpi5CarMqttServer.cpp          Publication, validation and completion waits
        xHal_Rpi5CarMqttServerLifecycle.cpp Non-owning connection binding
    test/src/xHal_Rpi5CarMqttServerTest.cpp TX host test
```

## 4. Public interface

`xHal_Rpi5CarMqttServer.h` (include)
declares `xwalk::hal::HiveMQServer`:

- `HiveMQServer(HiveMQClient* client)` binds a non-owning transport; null is allowed and operations then fail.
- `publish(topic, payload, size, qos, retained)` supports QoS 0, 1 and 2, defaults to QoS 1 and
  `retained=false`, and rejects payloads over 1 MiB (`XWALK_MQTT_PAYLOAD_MAX_BYTES`). A null payload is accepted
  only for size zero. Topic validation follows the RX client's exact-topic contract.
- `respond(payload, size, topic, qos)` uses `XWALK_MQTT_DEFAULT_RESPONSE_TOPIC` unless a custom topic is
  supplied, and never retains responses.

CMake exports the static library as `xWalkMqttServer` with the alias `xWalk::MqttServer`. It links the RX
library publicly.

```cpp
HiveMQClient receiver;
HiveMQServer transmitter(&receiver);
const bool connected = receiver.connect();
const bool subscribed = connected && receiver.subscribe(HiveMQClient::RequestTopic, onRequest, context);
const bool sent = subscribed && transmitter.publish(HiveMQClient::RequestTopic, encodedRequest, requestSize);
// Within the application callback, when a response has been encoded:
const bool replied = transmitter.respond(encodedResponse, responseSize);
```

Paho publication and completion-wait calls exist only in the TX source. They acquire the RX connection's
instance lock followed by the shared transport lock, preserving serialization with reconnect and reception.
QoS completion waits use 10 seconds (`XWALK_MQTT_PUBLISH_TIMEOUT_MS`). A timeout means delivery is unknown.
No offline queue is provided.

`MQTTDL.001` identifies publication and `MQTTDL.002` response completion. Enable both with
`XWalkTrace::setMqttTracesEnabled(true)`. Errors use `XWALK_MQTT_ERROR` directly.

### Parallel Controller responses

Controller workers publish independently through the shared connection. QoS 1 and 2 completion polling
releases both transport locks before waiting, so a delayed acknowledgement does not hold the lock needed by
another core's response or reception. A connection epoch prevents a reconnect from falsely completing an old
token. RX uses a nonblocking Paho poll with the existing 10 ms idle sleep. Encoding and callbacks run outside
FIFO locks, and each Controller core retains its own eight-entry request queue and response correlation.

Paho's synchronous API still requires serialized API access. The synchronous fallback remains for a publication
made inside the RX callback itself, since that callback cannot wait for its own receive loop. Controller
responses normally run on functional workers, not that callback. Connect and reconnect, socket writes, the
network and physical device leases remain shared resources; this is not hard real-time isolation. See
[Paho threading](https://eclipse.dev/paho/files/mqttdoc/MQTTClient/html/async.html) for the API constraints.

## 5. Build

From `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT/xWalkMqttServer -B xWalkIoT/xWalkMqttServer/build-host -DXWALK_MQTT_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalkIoT/xWalkMqttServer/build-host --parallel
```

The standalone project adds `xWalkMqttClient` (and through it `xWalkMqttInit`) when those targets are absent.
Build the [node](../xWalkIoT.md) for the combined executable and GPB integration tests.

## 6. Testing

| CTest name | Labels | Requirement |
| --- | --- | --- |
| `xWalkMqttTxTest` | `host;mqtt;tx` | `XWALK_MQTT_BUILD_HOST_TESTS=ON` |

```bash
ctest --test-dir xWalkIoT/xWalkMqttServer/build-host --output-on-failure
```

The node's opt-in loopback TLS test holds one worker's completion token pending while another publication and
its receive callback finish. No production credentials or robot hardware are used by that test.

## 7. Dependencies

- `xWalkMqttClient` (public) for the shared `HiveMQInit` transport.
- `xWalkTrace` (private).

## 8. Safety and constraints

- The RX client must outlive all TX calls; the TX object neither owns nor closes that connection. Null
  transports and disconnected operations return false. Never destroy the RX client from a callback.
- Payload buffers must remain readable and unchanged until the call returns.
- A successful publish confirms transport completion only, not command execution.

## 9. Related notes

- [xWalkIoT](../xWalkIoT.md)
- [xWalkMqttClient](../xWalkMqttClient/xWalkMqttClient.md)
- [xWalkMqttInit](../xWalkMqttInit/xWalkMqttInit.md)
- [xWalkReceiver](../xWalkAgent/xWalkReceiver/xWalkReceiver.md)
- [xWalkTransmitter](../xWalkAgent/xWalkTransmitter/xWalkTransmitter.md)

---

[Previous page](../xWalkMqttInit/xWalkConfig/xWalkConfig.md) · [Chapter index](../../../index.md) · [Next page](../xWalkAgent/xWalkReceiver/xWalkReceiver.md)
