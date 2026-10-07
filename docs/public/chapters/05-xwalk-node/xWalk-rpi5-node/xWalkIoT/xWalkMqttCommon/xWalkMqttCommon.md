<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkMqttCommon

**5. xWalk node &middot; Module 06**

<!-- xwalk-page-header:end -->

# xWalkMqttCommon

`xWalkMqttCommon` groups the shared MQTT building blocks of the xWalk node: signal types, bounded message
queues, Protobuf JSON conversion and the node runtime. Each child is a CMake module within the node repository.

## 1. Overview

| Module | CMake target | Responsibility |
| --- | --- | --- |
| [xWalkMqttTypes](xWalkMqttTypes/xWalkMqttTypes.md) | `xWalkMqttTypes` | Signal type, queue limits, macros |
| [xWalkMqttQueue](xWalkMqttQueue/xWalkMqttQueue.md) | `xWalkMqttMessageQueue` | Message queues; C backend API |
| [xWalkMqttJson](xWalkMqttJson/xWalkMqttJson.md) | `xWalkMqttNodeJson` | JSON conversion and sample tests |
| [xWalkMqttNode](xWalkMqttNode/xWalkMqttNode.md) | `xWalkMqttNodeRuntime` | Registry, CLI, topics, runtime |

Each implementation module owns its `include`, `src`, `test` and `CMakeLists.txt` files. The header-only types
module needs only `include` and `CMakeLists.txt`. Consumers use CMake target include requirements.

The common `CMakeLists.txt` adds
`xWalkLibraryCommon`, `xWalkTrace` and `xWalkIwProtobuf` when absent, then Types, Queue and JSON. The IoT
composition adds Node after its Agent and Transmitter dependencies exist, avoiding circular configuration
dependencies.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon` —
source directory

## 3. Directory layout

```text
xWalkMqttCommon/
    CMakeLists.txt     Adds dependencies, then Types, Queue and JSON
    auto-gen/          Generated IW signal and plain-message headers (generator-owned)
    xWalkMqttTypes/    Header-only shared types and macros
    xWalkMqttQueue/    Bounded received and outgoing message queues
    xWalkMqttJson/     Protobuf JSON encode, decode and validation
    xWalkMqttNode/     Node runtime, CLI, registry generation and process workers
```

The `auto-gen` headers are produced by the IW generator and must not be edited by hand. The JSON module reads
their `XWALK_*` signal numbers to register one sample test per JSON sample. Compile-time includes of the same
generated headers come through `xWalkLibraryCommon`.

## 4. Child modules

- [xWalkMqttJson](xWalkMqttJson/xWalkMqttJson.md) — JSON to native GPB conversion and sample tests.
- [xWalkMqttNode](xWalkMqttNode/xWalkMqttNode.md) — node runtime, CLI and generated signal registry.
- [xWalkMqttQueue](xWalkMqttQueue/xWalkMqttQueue.md) — bounded thread-safe message FIFOs.
- [xWalkMqttTypes](xWalkMqttTypes/xWalkMqttTypes.md) — shared signal type, queue limits and macros.

## 5. Build

The modules are built through the node composition described in [xWalkIoT](../xWalkIoT.md). The Agent and
Transmitter standalone projects add this directory when `xWalkMqttMessageQueue` is not yet defined.

## 6. Dependencies

- [xWalkLibrary Common](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md) for the shared signal
  type and generated IW headers.
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) for tracing.
- [xWalk-rpi5-iw](../../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md) for the `xWalkIwProtobuf` schema library.

## 7. Related notes

- [xWalkIoT](../xWalkIoT.md)
- [xWalkReceiver](../xWalkAgent/xWalkReceiver/xWalkReceiver.md)
- [xWalkTransmitter](../xWalkAgent/xWalkTransmitter/xWalkTransmitter.md)

---

[Previous page](../xWalkMqttClient/xWalkMqttClient.md) · [Chapter index](../../../index.md) · [Next page](xWalkMqttJson/xWalkMqttJson.md)
