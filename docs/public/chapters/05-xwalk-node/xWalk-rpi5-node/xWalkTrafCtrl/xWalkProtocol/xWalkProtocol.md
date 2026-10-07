<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkProtocol

**5. xWalk node &middot; Module 26**

<!-- xwalk-page-header:end -->

# xWalkProtocol

`xWalkProtocol` validates IW `TrafficObservation` messages, reads bounded Protobuf observations and legacy JSON
prediction reports, and produces JSONL evaluation records. It also owns the CMake step that generates the traffic
controller's IW C++ bindings.

## 1. Overview

The schema belongs to `xWalk-rpi5-iw/proto/xHal_Rpi5CarXIwTraffic.proto`; its
`xwalk.traffic.protocol.TrafficObservation` package, field numbers and wire format are preserved. CMake includes
IW's `cmake/XWalkTrafficProtocol.cmake` and calls `xwalk_generate_traffic_protocol` to generate the traffic,
request, common and signal bindings (including the existing IW sound announcement request) into the
controller-owned `../auto-gen/include` and `../auto-gen/src` directories as the `xWalkTrafficWire` target.
Generated bindings must not be edited by hand. This module contains only native validation and report adapters.

An observation is valid only when:

- `schema_version` is 1 and every required optional field (`risk_label`, `num_persons`, `num_vehicles`,
  `person_in_crosswalk`, `vehicle_in_crosswalk`) is present;
- `risk_label` is 0 (SAFE), 1 (WARNING) or 2 (DANGEROUS) and counts are at most 100000;
- crosswalk occupancy flags are consistent with nonzero counts, and an elevated risk has at least one person and
  one vehicle;
- the normalized geometry values are finite and within 0 to 1. Older messages without geometry remain compatible,
  because absent fields read as zero.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkProtocol` -
source directory

## 3. Directory layout

```text
xWalkProtocol/
    CMakeLists.txt                  Binding generation, static library and GoogleTest registration
    include/xWalkProtocol.h         Validation, report, Protobuf input and evaluation JSON functions
    src/xWalkProtocol.cpp           Implementation
    test/src/xWalkProtocolTest.cpp  Host GoogleTests
```

## 4. Public interface

Declared in `xWalkProtocol.h`
in namespace `xwalk::traffic`:

| Function | Contract |
| --- | --- |
| `validObservation(value)` | Presence, range and consistency check |
| `readReport(path)` | Parse the original app's JSON report; `risk_name` must match `risk_label` |
| `readObservation(path)` | Read one Protobuf observation of at most 4096 bytes and validate it |
| `evaluationJson(value, index, seconds)` | Build one record with risk, frame index, timestamp and features |

Invalid input raises a `TRAFCTRL` error. The original app's JSON reports remain readable.

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). Requires Protobuf 3.15 or newer with `protoc`. Links
publicly to `xWalkTrafficWire` and `xWalkConfiguration`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkProtocol --output-on-failure
```

`xWalkProtocolGoogleTest` (labels `host;gtest;xWalkProtocol`) covers explicit SAFE field round trips, rejection of
corrupt, incomplete and unsupported messages, and acceptance of the original JSON report.

## 7. Dependencies

- [xWalk-rpi5-iw](../../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md) schema and generation recipe.
- [xWalkConfiguration](../xWalkConfiguration/xWalkConfiguration.md) for the JSON helpers.
- Protobuf 3.15 or newer.

## 8. Safety and constraints

- Input size is bounded before parsing; oversized, truncated or inconsistent messages are rejected.
- Schema changes belong in IW and must keep the existing field numbers and wire format.

## 9. Related notes

- [xWalkPublisher](../xWalkPublisher/xWalkPublisher.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkPathVision/xWalkPathVision.md) · [Chapter index](../../../index.md) · [Next page](../xWalkProximity/xWalkProximity.md)
