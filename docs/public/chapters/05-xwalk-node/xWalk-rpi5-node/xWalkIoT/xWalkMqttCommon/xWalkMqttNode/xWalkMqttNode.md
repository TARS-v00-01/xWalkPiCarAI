<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkMqttNode

**5. xWalk node &middot; Module 08**

<!-- xwalk-page-header:end -->

# xWalkMqttNode

`xWalkMqttNode` is the xWalk node runtime: command-line parsing, generated signal lookup, signal-qualified topic
construction, foreground subscription, typed request publication with reply waits, the process-mode worker
supervision and the local telemetry socket. It also generates the MQTT signal registry from the IW definitions.

## 1. Overview

The IoT CMake composition adds this module after the Agent and Transmitter targets are available. The
`xWalkMqttNodeRuntime` target and its public header names are stable. In the Node-only `module` composition the
module generates the registry and adds only the [xWalkModule](xWalkModule/xWalkModule.md) terminal.

| Source | Responsibility |
| --- | --- |
| `xHal_Rpi5CarMqttNodeSignalRegistry.cpp` | Lookups into the build-generated registry |
| `xHal_Rpi5CarMqttNodeOptions.cpp` | Command-line parsing and validation, including signal arguments |
| `xHal_Rpi5CarMqttNodeTopic.cpp` | Signal-qualified MQTT topic construction |
| `xHal_Rpi5CarMqttNodeSend.cpp` | Typed sending, backend polling and reply waits |
| `xHal_Rpi5CarMqttNodeRuntime.cpp` | Foreground runtime and received-update draining |
| `xHal_Rpi5CarMqttControllerInit.cpp` | Process Controller lifecycle |
| `xHal_Rpi5CarMqttNodeController.cpp` | Controller request submission |
| `xHal_Rpi5CarMqttNodeServerAddress.cpp` | Server-address detection, override and wrong-server decisions |
| `xHal_Rpi5CarNodeProcesses.cpp` | Eight MQTT worker processes and their supervision |
| `xHal_Rpi5CarNodeProcessChild.cpp` | Worker-side request forwarding |
| `xHal_Rpi5CarNodeProcessRuntime.cpp` | Process-mode hardware owner runtime |
| `xHal_Rpi5CarNodeIpc.cpp` | Parent and worker IPC packets |
| `xHal_Rpi5CarNodeLocalServer.cpp` | Local Unix-socket telemetry server |
| `xHal_Rpi5CarNodeLocalClient.cpp` | Local Unix-socket telemetry client |
| `xHal_Rpi5CarNodeTraffic.cpp` | Launch of the independent Traffic Controller executable |
| `xHal_Rpi5CarMqttNodeSimple.cpp` | Raw GPB node |
| `xHal_Rpi5CarMqttNodeSupport.cpp` | Legacy CLI support |

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttNode` —
source directory

## 3. Directory layout

```text
xWalkMqttNode/
    CMakeLists.txt                     Registry generation, runtime library and host tests
    include/                           Runtime, options, IPC, process, local socket and address headers
    src/                               Runtime implementation sources listed above
    test/
        include/                       <Component>TestSupport.h fixtures
        src/                           Runtime, address, once, controller, IPC, local and activity tests
    xWalkConfig/
        xWalkMqttFunctions.json        Message stem to functionality mapping
    xWalkModule/                       Node-only terminal for the module composition
```

## 4. Child modules

- [xWalkModule](xWalkModule/xWalkModule.md) — Node-only `xwalk` terminal that validates JSON through real
  codecs and queues without MQTT, Controller or hardware.

## 5. Public interface

- `xHal_Rpi5CarMqttNodeRuntime.h`
  (include)
  declares `XWalkNodeRuntime`, `XWalkNodeRuntimeOptions`, `XWalkNodeSignal`, `XWalkNodeReply` and the functions
  `parseNodeRuntimeOptions()`, `findNodeSignal()`, `nodeSignalAt()`, `nodeSignalTopic()`, `sendNodeMessage()`,
  `submitControllerRequest()`, `pollNodeBackend()`, `runNodeRuntime()`, `printNodeReply()` and
  `runSimpleNode()`.
- `xHal_Rpi5CarMqttNodeServerAddress.h` selects this node's IPv4 server address from `XWALK_SERVER_IP` or the
  live interfaces; `0.0.0.0` is the broadcast address accepted by every node for announcements and voice-chat
  starts.
- `xHal_Rpi5CarNodeProcesses.h`, `xHal_Rpi5CarNodeIpc.h`, `xHal_Rpi5CarNodeLocalServer.h` and
  `xHal_Rpi5CarNodeLocalClient.h` define worker supervision, IPC and the local socket.

`submitControllerRequest()` uses the Controller attached to `XWalkNodeRuntime`. The production global lifecycle
and macros from [xWalkMqttTypes](../xWalkMqttTypes/xWalkMqttTypes.md) remain available for process owners.

### Typed publication

Typed `publish` requests wait for their matching CFM or REJ and print the decoded reply as JSON. No response or
reject file is created. The default timeout is 60000 ms; override it with `--timeout-ms N` (1–600000).
CFM exits 0, REJ or I/O failure exits 1, invalid arguments exit 2, timeout exits 124 and an interrupted wait
exits 130. Run a subscriber against the same broker first. The `json` command retains send-only behavior.

Publisher response capture requires the corresponding CFM or REJ signal and the complete client-address struct
from the transmitted request: `clientAddress`, `mail_box_id`, `xwalk_local_index` and `module_type`. Mismatched
or duplicate replies do not complete the wait. Terminal replies use four-space JSON indentation and their actual
message name as the outer key, for example `HealthCfm` or `HealthRej`.

### Offline start and process workers

The process subscriber starts the Controller and the local telemetry socket first and does not need the broker
to run. The eight MQTT workers start in the background (`XWalkNodeProcesses::startInBackground`). While the
broker is unreachable, for example without Wi-Fi or before network time, they are retried after 5 s, doubling
to at most 60 s, and the log shows `Remote control offline`. Remote clients connect as soon as the workers are
online, without a restart. After that, a failed worker still stops the hardware runtime.

The connector thread remains alive after connection and through Controller response draining, because Linux
worker parent-death signaling follows the thread that spawned the child. `stopBackground` stops retries and waits
for stable endpoints; `stop` reaps children before joining the thread. Startup shares one 30-second readiness
deadline across all eight workers and checks cancellation at most every 100 ms. Cancelling an unfinished attempt
signals all partial children together, gives them one shared second to exit, then kills and reaps the remaining
owned children, so a DNS or TLS stall in a child does not hold the parent until the connection timeout. Each
worker forwards requests with at most eight outstanding IPC credits.

### Local telemetry socket

The hardware owner serves read-only requests on a private Unix socket (`XWalkNodeLocalServer`), so a
touchscreen HUD on the same node reads health and sensors without any network:

```bash
./build-host/cmake/xwalk publish --function vehicle --signal XWALK_CNTRL_SENSOR_REQ --transport local
```

- The socket is `XWALK_NODE_LOCAL_SOCKET`, else `$XDG_RUNTIME_DIR/xwalk-node.sock`, with mode 0600. The server
  also checks through peer credentials that each client runs as the same user.
- Only `XWALK_HEALTH_REQ` and `XWALK_CNTRL_SENSOR_REQ` are served. Every request that could move the robot or
  change its lifecycle is refused; remote control keeps using MQTT.
- Local requests take the same per-core dispatch as MQTT requests, so local and remote requests never
  interleave. The reply returns on the socket and is matched by its client address, so a remote client polling
  the same signal still receives its own reply through MQTT.
- Output and exit codes match an MQTT `publish`. `--server` cannot be combined with `--transport local`.

## 6. Build

Normal builds invoke the registry generator automatically through CMake. From `xWalk-rpi5-node`:

```bash
cmake -S xWalkIoT --preset host
```

```bash
cmake --build build-host/cmake --parallel 4
```

To build only the generated registry headers:

```bash
cmake --build build-host/cmake --target xWalkMqttRegistry
```

The `module` preset builds Node codecs, queues and the terminal without Controller, Boot, HAL or Driver
implementations; the `host` and `rpi5` presets build the full production Node and Controller interfaces with
their respective providers. The executable is named `xwalk` in each separate output directory. See the
[node note](../../xWalkIoT.md) for full HOST and RPI5 commands.

| Cache variable | Default | Meaning |
| --- | --- | --- |
| `XWALK_MQTT_TOOL_ROOT` | `xWalk-rpi5-tool` beside the IW checkout | Tools checkout for registry generation |
| `XWALK_NODE_TRAFFIC_BINARY` | `xWalkTrafCtrl/build-<target>/xWalkTrafCtrl` | Default Traffic Controller path |

## 7. Configuration

### Signal registry generation

The registry header `xHal_Rpi5CarMqttNodeRegistry.h` and `xHal_Rpi5CarMqttNodeSampleMacros.h` are generated before
compilation by `xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarMqttRegistryGenerator.py` through the common
`python3 -m xWalkPyAgent mqtt-registry` CLI. They live under this module's build directory in
`generated/include` and are not committed.

The IW `xWalk-rpi5-iw/config/xHal_Rpi5CarGpbSigReq.xml`, `...Cfm.xml` and `...Rej.xml` files define signal names,
numbers and Protobuf message names.
`xWalkConfig/xWalkMqttFunctions.json`
(xWalkConfig)
assigns each message stem (for example `Move`) to one functionality — `service`, `vehicle`, `vision` or
`voice` — shared by Request, CFM and Reject.

For a new command, update IW, regenerate the IW headers, add its functionality mapping and provide all three JSON
samples. The generator rejects missing samples, unmapped commands and duplicate signals. Generated compile-time
assertions detect stale IW numeric macros, and CMake reruns generation when inputs change. The handwritten
Protobuf encode and decode handlers still need updating when adding a new command.

### Runtime environment

| Variable | Effect |
| --- | --- |
| `XWALK_SERVER_IP` | Overrides this node's detected server IPv4 address |
| `XWALK_NODE_LOCAL_SOCKET` | Overrides the local telemetry socket path |
| `XWALK_TRAFFIC_BINARY` | Overrides the compiled Traffic Controller executable path |
| `XWALK_PICARX_CONFIG_FILE` | Overrides the compiled Controller configuration path |

Node creates Boot using the shared configuration-selection contract documented in the
[Controller note](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md). The native `rpi5-native` product
compiles the absolute `xWalk-rpi5-node/runtime/picar-x.conf` path by default. `XWALK_PICARX_CONFIG_FILE` in the
process environment overrides it; the CMake variable of the same name changes its compiled default. Keep local
deployment and calibration values after the generated include in the primary file. Configure and build refresh
generated defaults without starting Node or replacing deployment overrides.

## 8. Testing

| CTest name | Labels | Notes |
| --- | --- | --- |
| `xWalkMqttNodeRuntimeHostTest` | `host;mqtt;queue;node;protobuf` | Runtime, options and queues |
| `xWalkMqttNodeServerAddressHostTest` | `host;mqtt;node;protobuf` | Address selection and wrong-server decisions |
| `xWalkMqttNodeOnceHostTest` | `host;mqtt;node;json` | One-shot send with linker-wrapped MQTT calls |
| `xWalkMqttRegistryGeneratorHostTest` | `host;mqtt;generator` | Tools-owned generator test |
| `xWalkNodeControllerInterfaceHostTest` | `host;node;controller` | All 38 request mappings |
| `xWalkNodeIpcHostTest` | `host;node;ipc` | IPC packets |
| `xWalkNodeLocalHostTest` | `host;node;ipc` | Host target only; local socket round trips |
| `xWalkNodeVehicleActivityHostTest` | `host;node;ipc` | Host target only; process-mode status |

All tests require `XWALK_MQTT_BUILD_HOST_TESTS=ON`. The controller interface test checks all 38 request mappings
without initializing a process singleton. `xWalkNodeLocalHostTest` covers the request filter, socket path,
offline reply handling and a health and sensor round trip through the real Controller without a broker; it uses
the hardware-disabled host profile. Exec-created fake workers also verify parent-thread lifetime, response
delivery after request draining and complete child reaping without MQTT. Host regressions cover all workers
stalled, partial readiness, ignored SIGTERM, repeated stop and retained response delivery; each cancelled-start
fixture must shut down within three seconds without orphaned children. The two host-only tests share the
`xwalk-proximity-owner` resource lock.

```bash
ctest --test-dir build-host/cmake -L node --output-on-failure
```

## 9. Dependencies

- `xWalkControllerBoot`, `xWalkControllerResponse`, `xWalkNodeAgent`, `xWalkNodeTransmitter` and
  `xWalkMqttNodeJson` (public).
- `xWalkTrace` and `xWalkIwProtobuf` (private).
- Python 3 and the `xWalk-rpi5-tool` Python agent for registry generation.

## 10. Safety and constraints

- A successful publisher exit confirms sending only. Movement still requires the Controller's ACTIVE lifecycle
  and its commissioning limits and safety checks.
- The local socket never serves requests that could move the robot or change its lifecycle.
- Normal shutdown retains connected response workers through Controller cleanup. The desktop five-second
  escalation and systemd stop timeout remain unchanged.

## 11. Related notes

- [xWalkMqttCommon](../xWalkMqttCommon.md)
- [xWalkModule](xWalkModule/xWalkModule.md)
- [xWalkReceiver](../../xWalkAgent/xWalkReceiver/xWalkReceiver.md)
- [xWalkTransmitter](../../xWalkAgent/xWalkTransmitter/xWalkTransmitter.md)
- [xWalkConfig](../../xWalkMqttInit/xWalkConfig/xWalkConfig.md)
- [xWalkTrafCtrl](../../../xWalkTrafCtrl/xWalkTrafCtrl.md)
- [Developer Tool](../../../../../06-xwalk-tool/xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md)

---

[Previous page](../xWalkMqttJson/xWalkMqttJson.md) · [Chapter index](../../../../index.md) · [Next page](xWalkModule/xWalkModule.md)
