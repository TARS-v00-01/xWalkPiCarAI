<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [5. xWalk node](../../../../../index.md) / xWalkModule

**5. xWalk node &middot; Module 09**

<!-- xwalk-page-header:end -->

# xWalkModule

`xWalkModule` builds the Node-only `xwalk` terminal of the `module` composition. It validates one JSON message
through the production codecs and owned queues, prints compact JSON and exits, without MQTT, the Controller, Boot
or any HAL, Driver or device target.

## 1. Overview

The terminal accepts a generated signal name or decimal number, then a JSON file path or `-` for standard input.
It encodes the JSON with the IW schema selected by the signal, processes the message through the real Node
queues and decoders, and prints the result as compact JSON. It does not publish MQTT messages or execute
hardware operations.

```text
Usage: xwalk --list
       xwalk SIGNAL JSON_FILE
       xwalk SIGNAL -
```

`--list` prints one JSON record per supported signal with `signal`, `name`, `family` and `sample`. `-h` or
`--help` prints the help text from `xWalkNodeModuleHelp.json`. Any other argument count prints the usage line
and exits with status 2.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttNode/xWalkModule` —
source directory

## 3. Directory layout

```text
xWalkModule/
    CMakeLists.txt                         xwalk terminal executable, help staging and terminal test
    src/xHal_Rpi5CarNodeModule.cpp         Terminal main(): list, help and single-message processing
    test/xHal_Rpi5CarNodeModuleTest.py     Round-trip test over every generated signal
    xWalkConfig/xWalkNodeModuleHelp.json   Terminal help text
```

## 4. Public interface

The module produces the `xwalk` executable in the build root. It compiles
`xHal_Rpi5CarNodeModule.cpp`
(src)
together with the parent's `xHal_Rpi5CarMqttNodeSignalRegistry.cpp` and the generated registry headers. It has
no library interface.

## 5. Build

The parent [xWalkMqttNode](../xWalkMqttNode.md) adds this directory only when `XWALK_MQTT_TARGET=module`. From
`xWalk-rpi5-node`:

```bash
cmake --preset module -S xWalkIoT
```

```bash
cmake --build build-module/cmake --parallel 4
```

```bash
./build-module/cmake/xwalk --list
```

```bash
./build-module/cmake/xwalk XWALK_VERSION_REQ build-module/cmake/config/request/service/xWalkMqttVersionReq.json
```

## 6. Configuration

CMake copies `xWalkConfig/xWalkNodeModuleHelp.json` to `<build-directory>/config` and installs it to
`share/xwalk/help`. The JSON samples come from [xWalkConfig](../../../xWalkMqttInit/xWalkConfig/xWalkConfig.md).

## 7. Testing

| CTest name | Labels | Requirement |
| --- | --- | --- |
| `xWalkNodeModuleTerminalTest` | `host;node;module;json` | `XWALK_MQTT_BUILD_HOST_TESTS=ON` (set by the preset) |

```bash
ctest --test-dir build-module/cmake --output-on-failure
```

The test lists all 114 Node messages, processes every sample, re-encodes each decoded document through standard
input to check nested fields, bytes and presence, and checks that malformed, unknown-field, incomplete,
unknown-signal and oversized inputs fail. It also checks `compile_commands.json` to confirm that no Controller,
HAL or Driver source belongs to this build.

## 8. Dependencies

- `xWalkNodeAgent`, `xWalkNodeTransmitter`, `xWalkMqttNodeJson` and `xWalkTrace`.
- The `xWalkMqttRegistry` generation target of the parent module.

## 9. Safety and constraints

The terminal neither connects to a broker nor constructs a Controller, so it cannot move the robot. Its output
validates schema handling only and is not evidence of hardware behavior.

## 10. Related notes

- [xWalkMqttNode](../xWalkMqttNode.md)
- [xWalkMqttJson](../../xWalkMqttJson/xWalkMqttJson.md)
- [xWalkMqttQueue](../../xWalkMqttQueue/xWalkMqttQueue.md)
- [xWalkIoT](../../../xWalkIoT.md)

---

[Previous page](../xWalkMqttNode.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkMqttQueue/xWalkMqttQueue.md)
