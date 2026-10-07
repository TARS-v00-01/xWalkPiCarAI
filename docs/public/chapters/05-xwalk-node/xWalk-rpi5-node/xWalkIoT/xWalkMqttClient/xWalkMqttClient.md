<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkMqttClient

**5. xWalk node &middot; Module 05**

<!-- xwalk-page-header:end -->

# xWalkMqttClient

`xWalkMqttClient` is the MQTT receive (RX) library of the xWalk node. `HiveMQClient` provides exact-topic
subscriptions and serial message callbacks over the verified TLS connection owned by its
[`HiveMQInit`](../xWalkMqttInit/xWalkMqttInit.md) member.

## 1. Overview

`HiveMQClient` provides receive subscriptions and callbacks. Its `HiveMQInit` member owns the verified TLS
connection, configuration, synchronization and worker lifetime. Publication is implemented exclusively by
[`HiveMQServer`](../xWalkMqttServer/xWalkMqttServer.md); the RX class has no `publish()` method.
`HiveMQServer` borrows the client's `HiveMQInit` member so RX and TX use the same transport and mutexes.

| Group | Responsibility |
| --- | --- |
| Main source | Subscription registration and lookup. |
| Lifecycle | Delegates setup and shutdown to the owned `HiveMQInit` member. |
| Receive | Message callbacks, reconnect and subscription restoration. |

Configuration helpers live in `xWalkMqttInit/src/xHal_Rpi5CarMqttInitConfigurationSupport.cpp`.
MQTT trace selection and priorities are owned by `xWalk-rpi5-trace`.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttClient` —
source directory

## 3. Directory layout

```text
xWalkMqttClient/
    CMakeLists.txt                         xWalkMqttClient library and xWalkMqttRxTest
    .clangd                                Editor indexing settings
    include/
        xHal_Rpi5CarMqttClient.h           HiveMQClient RX class and default topic constants
        xHal_Rpi5CarMqttClientMacros.h     RX macro header forwarding to the initialization macros
    src/
        xHal_Rpi5CarMqttClient.cpp         Subscription registration and lookup
        xHal_Rpi5CarMqttClientLifecycle.cpp Construction, connect and disconnect delegation
        xHal_Rpi5CarMqttClientReceive.cpp  Receive worker, callbacks, reconnect and restoration
    test/src/xHal_Rpi5CarMqttClientTest.cpp RX host test
```

## 4. Public interface

`xHal_Rpi5CarMqttClient.h` (include)
declares `xwalk::hal::HiveMQClient` with `connect()`, `subscribe(topic, callback, context, qos)`,
`isConnected()` and `disconnect()`, plus the static `RequestTopic`, `ResponseTopic` and `StatusTopic` constants.
CMake exports the static library as `xWalkMqttClient` with the alias `xWalk::MqttClient`.

RX contract:

- Callbacks receive a borrowed `HiveMQMessage` with topic, payload pointer and exact payload size. Payload
  bytes may contain zeros and are not decoded.
- Topics are exact, valid UTF-8 strings of at most 65535 bytes without wildcards or control characters.
- QoS 0, 1 and 2 are accepted. At most `XWALK_MQTT_MAX_SUBSCRIPTIONS` (128) subscriptions are stored.
- Callbacks run serially outside transport locks and must return promptly without throwing exceptions. They may
  transmit through a `HiveMQServer` attached to this client, or subscribe or disconnect through this client.
- After connection loss, the receive worker retries at 1-to-30-second intervals and restores subscriptions.
  Initial connection failure returns false. There is no durable or offline queue.
- Paho synchronous calls share one process-wide mutex; timeouts, DNS resolution and lock contention can delay
  calls.

The implementation uses C-style buffers, function pointers, pthreads and return codes inside a C++17 class.
The destructor releases resources without logging. Common-library timing functions supply sleeps and deadlines.
RX and connection events use `MQTTUL.001`, `.002`, `.004`, `.005` and `.006`; warnings and errors use the MQTT
macros. No application TX code or TX trace selection is compiled into the RX library.

## 5. Build

Install dependencies as described in the [node note](../xWalkIoT.md). Adjacent `xWalk-rpi5-hw` and
`xWalk-rpi5-trace` checkouts are required. From `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT/xWalkMqttClient -B xWalkIoT/xWalkMqttClient/build-host -DXWALK_MQTT_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalkIoT/xWalkMqttClient/build-host --parallel
```

This component builds the RX library and its RX test; it adds `xWalkMqttInit` when that target is absent.
Build the [node](../xWalkIoT.md) for the combined `xwalk` command.

## 6. Configuration

The client reads a `KEY=value` configuration file. `HIVEMQ_CONFIG_FILE` selects its path; when unset or empty,
the default is the build directory's `config/xWalkMqttClient.conf`, unless a custom path was selected with
CMake. The five connection settings are read only from the file, not from environment variables.

| File key | Meaning |
| --- | --- |
| `HIVEMQ_HOST` | Required broker hostname, without scheme, port or path |
| `HIVEMQ_USERNAME` | Optional with netrc; otherwise the MQTT username |
| `HIVEMQ_PASSWORD` | Optional with netrc; otherwise the MQTT password |
| `HIVEMQ_CLIENT_ID` | Defaults to `xwalk-pi5-controller` when missing or empty |
| `HIVEMQ_CA_FILE` | Optional PEM CA file; missing or empty uses system trust |

The broker is a HiveMQ Cloud cluster. Create MQTT access credentials with publish and subscribe permission for
the required topics under **Access Management**; use MQTT credentials rather than a dashboard login. The
[HiveMQ Cloud quick start](https://docs.hivemq.com/hivemq-cloud/quick-start-guide.html) describes cluster and
credential setup.

The tracked `xWalkMqttClient.conf`
(xWalkConfig)
template contains no username or password. From `xWalk-rpi5-node`, create a private runtime copy outside the
repository and supply the broker host and credentials there:

```bash
mkdir -p "$HOME/.config/xwalk"
```

```bash
install -m 600 xWalkIoT/xWalkMqttInit/xWalkConfig/xWalkMqttClient.conf "$HOME/.config/xwalk/xWalkMqttClient.conf"
```

```bash
export HIVEMQ_CONFIG_FILE="$HOME/.config/xwalk/xWalkMqttClient.conf"
```

File format:

- Use one key per line. Blank lines and lines whose first non-whitespace character is `#` are ignored.
- Values are literal: do not add quotes, escapes or inline comments. Spaces after `=` are part of the value;
  `#` and additional `=` characters in passwords are preserved. LF and CRLF line endings are supported.
- Duplicate keys, unknown keys, embedded NUL bytes, lines longer than 65535 bytes and files larger than 1 MiB
  are rejected. Use an absolute CA file path; relative paths resolve from the process working directory.
- Configuration is retained after initialization. Create a new client to load edited settings.
- Give simultaneous clients different `HIVEMQ_CLIENT_ID` values. The default topics do not change with the
  client ID. TLS port 8883 and certificate verification remain fixed.

Credentials can instead be kept in netrc: leave both `HIVEMQ_USERNAME` and `HIVEMQ_PASSWORD` empty or omit both.
The node looks up the exact `HIVEMQ_HOST` in `HIVEMQ_NETRC_FILE`, falling back to the CMake-selected path, then
`$HOME/.netrc` when that path is empty. Both nonempty configuration credentials take precedence; a partially
specified pair is rejected. See the [netrc setup](../xWalkMqttInit/xWalkMqttInit.md) for the full contract.

For deployment, set `HIVEMQ_CONFIG_FILE` in the service environment and make the private file readable only by
the service account. Local `*.local.conf` files are ignored by Git. No configuration contents or credential
values are logged.

## 7. Testing

| CTest name | Labels | Requirement |
| --- | --- | --- |
| `xWalkMqttRxTest` | `host;mqtt;rx` | `XWALK_MQTT_BUILD_HOST_TESTS=ON` |

```bash
ctest --test-dir xWalkIoT/xWalkMqttClient/build-host --output-on-failure
```

Live broker behavior is covered only by the node's opt-in loopback TLS tests, which use synthetic credentials.

## 8. Dependencies

- `xWalkMqttInit` (public), which brings Eclipse Paho MQTT C with TLS, OpenSSL and `xWalkLibraryCommon`.
- `xWalkTrace` and POSIX threads (private).

## 9. Safety and constraints

- Keep callback contexts alive until the client destructor has joined its worker. Never destroy the client
  inside a callback. Disconnect does not wait for an already dispatched callback to finish.
- Do not enable Paho's separate protocol tracing with production credentials. The subscriber CLI intentionally
  writes received payload data to stdout and traces topics.
- Troubleshooting: for TLS errors, check the system clock, trusted CA file and exact broker hostname; never
  disable verification. For authentication errors, verify MQTT access credentials and topic permissions. For
  repeated disconnects, use different client IDs in different processes; both directions within one node share
  one ID. Ensure DNS works and outbound TCP port 8883 is permitted.

## 10. Related notes

- [xWalkIoT](../xWalkIoT.md)
- [xWalkMqttInit](../xWalkMqttInit/xWalkMqttInit.md)
- [xWalkMqttServer](../xWalkMqttServer/xWalkMqttServer.md)
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkDeploy/rpi5-csi/GPB_VERIFICATION.md) · [Chapter index](../../../index.md) · [Next page](../xWalkMqttCommon/xWalkMqttCommon.md)
