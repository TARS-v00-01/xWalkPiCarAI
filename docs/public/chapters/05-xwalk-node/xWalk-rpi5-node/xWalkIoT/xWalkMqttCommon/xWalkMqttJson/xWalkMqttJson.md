<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkMqttJson

**5. xWalk node &middot; Module 07**

<!-- xwalk-page-header:end -->

# xWalkMqttJson

`xWalkMqttJson` converts bounded JSON input into native IW Protobuf (GPB) messages, validates native GPB payloads
before transport and converts validated GPB back into JSON for terminal consumers.

## 1. Overview

The `xWalkMqttNodeJson` static library encodes JSON with the generated IW Protobuf schemas selected by a
generated signal number. It owns its JSON unit test and the staged Request, CFM and Reject sample tests. Sample
files remain in [`xWalkMqttInit/xWalkConfig`](../../xWalkMqttInit/xWalkConfig/xWalkConfig.md) and are staged
into `<build-directory>/config` by the initialization CMake.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttJson` —
source directory

## 3. Directory layout

```text
xWalkMqttJson/
    CMakeLists.txt                              Library, unit test and per-sample test registration
    include/xHal_Rpi5CarMqttNodeJson.h          Public JSON and GPB conversion API
    src/xHal_Rpi5CarMqttNodeJson.cpp            Implementation using native Protobuf JSON utilities
    test/src/xHal_Rpi5CarMqttNodeJsonTest.cpp   JSON encode and sample validation executable
```

## 4. Public interface

`xHal_Rpi5CarMqttNodeJson.h`
(include)
declares, in `xwalk::node`:

| Function | Contract |
| --- | --- |
| `encodeNodeJson(signal, json, length, output, capacity, written)` | Encodes JSON into a caller-owned buffer |
| `loadNodeJson(signal, path, output, capacity, written)` | Reads one bounded JSON file and encodes it |
| `validateNodePayload(signal, payload, length)` | Validates bounded native GPB before outgoing transport |
| `decodeNodeJson(signal, payload, length, output, pretty)` | Converts validated GPB into compact or pretty JSON |

Capacities are bounded by the common queue payload limit of 64 KiB. Encoding fails for unknown signals, invalid
JSON or schema fields, and insufficient output capacity; `written` is zero on failure. Response validation
requires routing identity (client address) presence.

## 5. Build

The target is configured by the common `CMakeLists.txt`
(xWalkMqttCommon)
through the node composition described in [xWalkIoT](../../xWalkIoT.md).

## 6. Testing

| CTest name | Labels | Input |
| --- | --- | --- |
| `xWalkMqttNodeJsonHostTest` | `host;mqtt;json;protobuf` | Source `xWalkMqttMove.json` |
| `xWalkMqttSample<Type>HostTest` | `host;mqtt;json;sample;protobuf` | One staged Request, CFM or Reject sample |

Both groups are registered when `XWALK_MQTT_BUILD_HOST_TESTS=ON`. At configure time CMake resolves each sample's
signal number from the generated `../auto-gen/xHal_Rpi5CarGpbSig{Req,Cfm,Rej}.h` headers instead of duplicating
numeric IDs; configuration fails when a sample has no generated signal.

```bash
ctest --test-dir build-host -L json --output-on-failure
```

## 7. Dependencies

- [xWalkMqttTypes](../xWalkMqttTypes/xWalkMqttTypes.md) (public).
- `xWalkIwProtobuf` from [xWalk-rpi5-iw](../../../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md) and `xWalkTrace` (private).

## 8. Safety and constraints

Sample data illustrates the IW schema; it is not a record of a completed hardware operation. Connection
credentials never belong in JSON message samples.

## 9. Related notes

- [xWalkMqttCommon](../xWalkMqttCommon.md)
- [xWalkConfig](../../xWalkMqttInit/xWalkConfig/xWalkConfig.md)
- [xWalkMqttNode](../xWalkMqttNode/xWalkMqttNode.md)

---

[Previous page](../xWalkMqttCommon.md) · [Chapter index](../../../../index.md) · [Next page](../xWalkMqttNode/xWalkMqttNode.md)
