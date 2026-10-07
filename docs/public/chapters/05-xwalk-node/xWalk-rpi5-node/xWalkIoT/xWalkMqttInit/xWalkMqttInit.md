<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkMqttInit

**5. xWalk node &middot; Module 12**

<!-- xwalk-page-header:end -->

# xWalkMqttInit

`xWalkMqttInit` owns the MQTT connection foundation of the xWalk node: runtime configuration loading, netrc
credential lookup, verified TLS settings, the Eclipse Paho handle, synchronization, reconnect state and the
receive-worker lifetime. It also stages the runtime configuration directory and message samples at configure time.

## 1. Overview

`HiveMQInit` owns configuration strings, TLS settings, the Paho handle, synchronization, retry state and
receive-worker lifetime. [`HiveMQClient`](../xWalkMqttClient/xWalkMqttClient.md) contains one instance and
delegates `connect()`, `disconnect()` and `isConnected()` to it.
[`HiveMQServer`](../xWalkMqttServer/xWalkMqttServer.md) borrows that same instance, so receive (RX) and
transmit (TX) share one transport and one set of mutexes.

This library does not depend on the RX or TX implementations: it receives a plain POSIX worker function pointer
and context from the RX owner. Receive and subscription operations stay in RX; GPB publishing stays in TX.
No exceptions, STL containers or inheritance are used.

| File group | Responsibility |
| --- | --- |
| `xHal_Rpi5CarMqttInitLifecycle.cpp` | Initialize C fields and mutex; join the worker and release resources. |
| `xHal_Rpi5CarMqttInitConfiguration.cpp` | Load configuration, prepare verified TLS and start the worker. |
| `xHal_Rpi5CarMqttInitConfigurationSupport.cpp` | Parse bounded lines, keys, whitespace and defaults. |
| `xHal_Rpi5CarMqttInitConnection.cpp` | Connect, disconnect, connection status and handle cleanup. |
| `xHal_Rpi5CarMqttInitValidation.cpp` | Shared MQTT topic/identifier and QoS validation. |
| `xHal_Rpi5CarMqttNetrc.cpp` | Bounded netrc parser used for broker credentials. |

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttInit` —
source directory

## 3. Directory layout

```text
xWalkMqttInit/
    CMakeLists.txt          Library target, cache options, configuration staging and host tests
    include/
        xHal_Rpi5CarMqttInit.h         HiveMQInit, HiveMQMessage, HiveMQSubscription and callback type
        xHal_Rpi5CarMqttInitMacros.h   Configuration keys, topics, TLS, limits and timing constants
        xHal_Rpi5CarMqttNetrc.h        HiveMQNetrc credential loader
    src/                    Lifecycle, configuration, connection, validation and netrc sources
    test/
        src/xHal_Rpi5CarMqttNetrcTest.cpp   Netrc parser executable driven by the Python test
        xHal_Rpi5CarMqttNetrcTest.py        Netrc permission, syntax and precedence checks
        xHal_Rpi5CarMqttSampleTest.py       Staged sound, lifecycle and movement sample checks
    xWalkConfig/            Connection template, help text and JSON message samples
```

## 4. Child modules

- [xWalkConfig](xWalkConfig/xWalkConfig.md) — connection template, node help text and the 114 staged
  Request, CFM and Reject JSON samples.

## 5. Public interface

- `xHal_Rpi5CarMqttInit.h`
  declares `HiveMQInit` (`connect()`, `disconnect()`, `isConnected()`), the borrowed `HiveMQMessage` view, the
  `HiveMQSubscription` record and the `mqttmessagecallback` function-pointer type in `xwalk::hal`.
- `xHal_Rpi5CarMqttInitMacros.h` (include)
  holds shared constants; the RX macro header forwards to it.
- `xHal_Rpi5CarMqttNetrc.h` (include)
  declares `HiveMQNetrc::load()`.

Selected constants from `xHal_Rpi5CarMqttInitMacros.h`:

| Constant | Value |
| --- | --- |
| `XWALK_MQTT_TLS_PORT` | 8883, fixed; server certificate verification is always enabled |
| `XWALK_MQTT_DEFAULT_CLIENT_ID` | `xwalk-pi5-controller` |
| `XWALK_MQTT_DEFAULT_RESPONSE_TOPIC` | `xwalk/xwalk-pi5-controller/response` |
| `XWALK_MQTT_DEFAULT_STATUS_TOPIC` | `xwalk/xwalk-pi5-controller/status` |
| `XWALK_MQTT_DEFAULT_REQUEST_TOPIC`, `XWALK_MQTT_DEFAULT_QOS` | Shared signal defaults from the common library |
| `XWALK_MQTT_TOPIC_MAX_BYTES` | 65535 bytes |
| `XWALK_MQTT_CONFIG_MAX_BYTES` | 1 MiB configuration file limit |
| `XWALK_MQTT_MAX_SUBSCRIPTIONS` | 128 stored subscriptions |
| `XWALK_MQTT_KEEP_ALIVE_SECONDS` | 20 s |
| `XWALK_MQTT_CONNECT_TIMEOUT_SECONDS` | 10 s |
| `XWALK_MQTT_RECONNECT_MIN_MS` / `_MAX_MS` | 1000 ms doubling to 30000 ms |
| `XWALK_MQTT_WORKER_SLEEP_MS` | 10 ms idle receive sleep |

CMake exports the static library as `xWalkMqttInit` with the alias `xWalk::MqttInit`.

## 6. Build

The library is normally built through the node composition. From `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT -B build-host -DXWALK_MQTT_BUILD_HOST_TESTS=ON -DXWALK_MQTT_BUILD_TLS_TESTS=ON
```

```bash
cmake --build build-host --parallel
```

```bash
ctest --test-dir build-host --output-on-failure
```

```bash
./build-host/xwalk --help
```

| CMake option | Default | Meaning |
| --- | --- | --- |
| `XWALK_MQTT_UNIQUE_CLIENT_IDS` | `ON` | Append a random instance suffix to the configured client ID |
| `XWALK_MQTT_BUILD_HOST_TESTS` | `OFF` | Build MQTT host tests |
| `XWALK_MQTT_BUILD_TLS_TESTS` | `OFF` | Run a local TLS broker on loopback port 8883 |
| `XWALK_MQTT_CONFIG_FILE` | empty | Compiled default configuration path; empty selects the build copy |
| `HIVEMQ_NETRC_FILE` | empty | Compiled default netrc path; empty selects `$HOME/.netrc` |
| `XWALK_WORKSPACE_ROOT` | `../../..` | Workspace root used to locate trace and audio resources |

Both path options must be single-line values; CMake rejects embedded line breaks. CMake supplies the paths as
compiler definitions; no build-configuration header template is needed. Only the path is embedded; the file is
opened at runtime.

## 7. Configuration

At configure time CMake prepares `<build-directory>/config`:

- `xWalkMqttClient.conf` is copied from the template only if absent, so reconfiguration preserves locally
  entered settings.
- `xWalkMqttNodeHelp.json` is regenerated from its source template with the compiled default path.
- `xWalkMqttMove.json` and every Request, CFM and Reject sample are copied with their directory hierarchy.
- `stage-sound-sample.py` writes a PCM16 derivative of the horn sound and its staged `SoundReq` sample.

With no custom path, the executable uses the absolute path of the build copy of `xWalkMqttClient.conf`.
`HIVEMQ_CONFIG_FILE` overrides the compiled default at runtime. Relative paths resolve against the process
working directory. The `--help` output shows the compiled default path. Reconfigure and rebuild to change it.
Use `-DXWALK_MQTT_CONFIG_FILE=` to reset an existing custom CMake path to the build-directory default:

```bash
cmake -S xWalkIoT -B build-host -DXWALK_MQTT_CONFIG_FILE=/absolute/path/to/xWalkMqttClient.local.conf
```

The connection file format and keys are documented in the [RX client note](../xWalkMqttClient/xWalkMqttClient.md).

### Netrc setup

The connection file names the broker host, client ID and optional CA file. Leave `HIVEMQ_USERNAME` and
`HIVEMQ_PASSWORD` empty or omit both, then add an entry to a private netrc file whose `machine` value equals the
exact configured broker host, with `login` and `password` holding MQTT access credentials. Keep unrelated
existing entries. Use placeholders such as `YOUR_CLUSTER`, `YOUR_MQTT_USERNAME` and `YOUR_MQTT_PASSWORD` only in
documentation; never commit real values.

```bash
chmod 600 ~/.netrc
```

```bash
HIVEMQ_NETRC_FILE=/absolute/path/to/private.netrc ./build-host/xwalk
```

Credential contract:

- The netrc file must be a regular file owned by the running user with no group or other permissions.
- The runtime `HIVEMQ_NETRC_FILE` environment variable overrides the CMake-selected path. If both are empty,
  the node uses `$HOME/.netrc`. The `host-debug` preset selects `$HOME/.netrc`; the `rpi5-native` preset leaves
  the setting empty, using the Pi user's home directory.
- Both nonempty configuration credentials override netrc; a partial configuration pair is rejected. This
  prevents combining credentials from different sources.
- Client ID and CA settings remain in the configuration file.
- Supported syntax: `machine`, `login`, `password`, optional ignored `account`, whitespace, full-line comments,
  double-quoted values and backslash escapes. Only an exact machine entry is used; `default` entries are not
  used for authentication. Duplicate matches or credentials, incomplete entries, NUL bytes, unsupported
  directives (including `macdef`) and malformed quoting are rejected.
- The file limit is 1 MiB and tokens are limited to 65535 bytes. Contents are never logged, and temporary
  credential buffers are wiped before release.
- CMake never copies credentials into the build, and the build creates no credentials in the home directory.

Set a different compiled netrc default from the node root:

```bash
cmake -S xWalkIoT --preset host-debug -DHIVEMQ_NETRC_FILE="$HOME/.netrc"
```

### Concurrent processes

`XWALK_MQTT_UNIQUE_CLIENT_IDS` is enabled by default. The configured client ID is a prefix; each instance appends
a random 128-bit suffix once at initialization and reuses it on reconnect. This permits multiple terminals to
share one configuration and credential file. Topic names stay fixed. Disable this option only for deployments
that require an exact client ID, with a different ID per instance.

## 8. Testing

| CTest name | Labels | Coverage |
| --- | --- | --- |
| `xWalkMqttStagedSampleHostTest` | `host;mqtt;sample` | Staged PCM16 sound, ACTIVE lifecycle and 15% move |
| `xWalkMqttNetrcTest` | `host;mqtt;configuration` | Netrc parsing, file permissions and rejection paths |

Both are registered when `XWALK_MQTT_BUILD_HOST_TESTS=ON`. The node-level TLS integration tests use a temporary
local broker with synthetic credentials. They cover binary messages, reconnect, subscription restoration,
configuration rejection and certificate verification. No test plays audio or connects to a production broker.

## 9. Dependencies

- Eclipse Paho MQTT C 1.3 or newer with the TLS-enabled `paho-mqtt3cs` library (configure fails otherwise).
- OpenSSL (`OpenSSL::Crypto`), POSIX threads and Python 3 for sample staging.
- `xWalkLibraryCommon` (public) and `xWalkTrace` (private); the trace project is added when not already present.
- `xWalk-rpi5-hw/xWalkAudioResources/sounds/car-double-horn.wav` as the sound-sample source.

## 10. Safety and constraints

- The client destructor stops and joins reception before its member is destroyed. Stop concurrent callers
  before destroying the client; never destroy it inside a receive callback.
- The initializer releases the transport, subscriptions and configuration, wiping the password.
- Never put real credentials in the tracked template, notes or samples; keep them in a private file outside
  the repository.

## 11. Related notes

- [xWalkIoT](../xWalkIoT.md)
- [xWalkMqttClient](../xWalkMqttClient/xWalkMqttClient.md)
- [xWalkMqttServer](../xWalkMqttServer/xWalkMqttServer.md)
- [xWalkConfig](xWalkConfig/xWalkConfig.md)
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkMqttCommon/xWalkMqttTypes/xWalkMqttTypes.md) · [Chapter index](../../../index.md) · [Next page](xWalkConfig/xWalkConfig.md)
