<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkMqttTypes

**5. xWalk node &middot; Module 11**

<!-- xwalk-page-header:end -->

# xWalkMqttTypes

`xWalkMqttTypes` is the header-only interface target that exposes the shared `xWalksSignal` send-argument type,
the MQTT queue limits and the process Controller send macros to node components.

## 1. Overview

The `xWalkMqttTypes` interface target exports its `include` directory and links `xWalkLibraryCommon`, which
owns the signal structure and the generated IW include path. Generated headers are produced by the IW
generator; the copy in `../auto-gen` remains generator-owned and is not edited by hand.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttTypes` —
source directory

## 3. Directory layout

```text
xWalkMqttTypes/
    CMakeLists.txt                               INTERFACE target xWalkMqttTypes (alias xWalk::MqttTypes)
    include/
        xHal_Rpi5CarSignal.h                     Node include for the shared xWalksSignal type
        xHal_Rpi5CarMqttMessageQueueMacros.h     Queue capacity, payload bound and family IDs
        xHal_Rpi5CarMqttControllerMacros.h       Process Controller lifecycle and send macros
```

## 4. Public interface

- `xHal_Rpi5CarSignal.h`
  (include)
  includes `xHal_Rpi5CarSignalTypes.h` from the common library. `xWalksSignal` contains `signal`, `topic`,
  `qos` and a `void* payload`; its topic defaults to the request topic and its QoS to 1.
- `xHal_Rpi5CarMqttMessageQueueMacros.h`
  (include)
  defines `XWALK_MQTT_QUEUE_CAPACITY` (64 messages), `XWALK_MQTT_QUEUE_PAYLOAD_MAX_BYTES` (65536 bytes), the
  family identifiers Request 0, CFM 1, Reject 2 and Backend 3, a 256-byte signal-topic bound and a decode depth
  of 16.
- `xHal_Rpi5CarMqttControllerMacros.h`
  (include)
  declares `initializeNodeController()`, `nodeController()` and `shutdownNodeController()` in `xwalk::node`,
  and the `XWALK_MQTT_SEND_REQUEST`, `XWALK_MQTT_SEND_CFM` and `XWALK_MQTT_SEND_REJECT` macros that route to the
  initialized process Controller. Each macro argument is evaluated once.

## 5. Build

The target is configured by the common `CMakeLists.txt`
(xWalkMqttCommon)
and requires C++17. It has no sources and no tests of its own.

## 6. Dependencies

- `xWalkLibraryCommon` from
  [xWalkLibrary Common](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md).
- The Controller macro header includes `xControllerMacros.h` from the Controller; only consumers that link the
  Controller may include it.

## 7. Safety and constraints

- `xWalksSignal::payload` must reference the generated plain message type matching `signal`. A `void*` cannot
  validate the object type.
- Controller lifecycle calls belong to the single startup and shutdown thread. `nodeController()` returns null
  outside the runtime lifetime.

## 8. Related notes

- [xWalkMqttCommon](../xWalkMqttCommon.md)
- [xWalkMqttQueue](../xWalkMqttQueue/xWalkMqttQueue.md)
- [xWalkController](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)

---

[Previous page](../xWalkMqttQueue/xWalkMqttQueue.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkMqttInit/xWalkMqttInit.md)
