<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkRuntime

**4. xWalk software &middot; Module 15**

<!-- xwalk-page-header:end -->

# xWalkRuntime

`xWalkRuntime` owns the Controller and Traffic processes and their shutdown, polls read-only telemetry, evaluates
boot readiness and estimates battery charging from the voltage trend.

## 1. Overview

### Process ownership

- `XWalkProcesses` owns one multi-group Controller and one independent Traffic process. Controller functions
  share a single hardware owner; selections use Node's comma-separated `subscribe --function` option.
- Changing the selection stops the current Controller before starting the replacement, so current operations are
  interrupted. Traffic has an independent lifecycle. All selects service, vehicle, vision and voice; Traffic must
  be selected explicitly.
- The Controller environment exports `XWALK_PICARX_CONFIG_FILE` and `XWALK_TRAFFIC_BINARY`; the Traffic child
  receives `XWALK_TRAFFIC_PREVIEW_FILE` when a camera frame is configured.
- `XWalkChild` places each owned service and its workers in a separately stoppable process group. Stopping sends
  SIGTERM to the group and SIGKILL after five seconds if needed. External system services are not managed.
- `failure` carries structured lifecycle failures only, never child stdout/stderr traces.

### Telemetry

- `XWalkTelemetry` issues sequential, bounded, read-only Node requests (health, battery, distance, grayscale) and
  never sends lifecycle or movement commands. Each request has a 1.5 second reply timeout and a 2.5 second process
  deadline. Validated samples are removed after 15 seconds.
- On the car (`rpi5` build), telemetry requests use `run-xwalk publish --transport local`: they reach the
  hardware owner through its local socket, so health, battery and sensor values appear without Wi-Fi or the MQTT
  broker. Host builds keep publishing through MQTT. Starting services and every other operation still use MQTT.
- Startup polls health before sensors. An initial five-second handshake window tolerates the asynchronous
  Controller launch; continued failure after that window is reported. Once health has replied, subsequent failures
  are reported immediately without another grace period.
- Local telemetry follows the owned Controller lifecycle. Before an intentional Controller stop or
  function-selection restart (`controllerStopping`), the HUD drains its read-only publisher while the old socket is
  still available. It resumes polling after the replacement process starts (`controllerStarted`), using the
  existing bounded health handshake before sensor requests. Independent Traffic changes do not suspend Controller
  telemetry. Unexpected process exits and persistent telemetry failures retain their existing diagnostics.
- Automatic telemetry treats explicit sensor busy and proximity-pause rejections as deferred reads. They do not
  create generic transport-failure warnings or fabricated measurements. Unexpected rejections, process failures
  and timeouts still report failure. Cancelling the telemetry owner's own query during shutdown does not report a
  runtime fault.
- A sensor read queued behind movement can receive the explicit abort "Movement ended before sensor sampling" when
  that movement finishes. Only that exact sensor rejection is treated as a deferred sample: the sensor value stays
  unavailable until the next scheduled read, without delaying STOP or inventing a value. Other cancellation,
  sensor and transport failures continue to warn.

### Battery and charging estimate

Battery voltage and percentage are the controller's rolling one-minute average. The controller samples every five
seconds from its start, so the first value exists within moments, and the HUD reads it every 10 s (every 5 s
until the first value). A reading becomes stale after 30 s.

`XWalkBatteryTrend` estimates charging from one reading per minute, and only after two consecutive rises of at
least 5 mV each, totalling at least 15 mV across three such readings. The first indication therefore needs roughly
three minutes after monitoring starts. A flat or falling reading, a sample interval outside 45–90 seconds, a
monitoring restart, or 90 seconds without fresh evidence clears it. The CLI exposes `battery_charging_estimated`
and `battery_charging_source: voltage_trend`. False means unknown, not confirmed discharging. Changing motor or CPU
load can produce a false positive; slow charging, a full battery or high load can produce no indication while the
charger remains connected. No charger connection, charge current or full-charge detection is available from the
current HAT interface.

### Readiness

`XWalkReadiness` evaluates all five required checks (runtime, hardware, battery, distance, grayscale) without
enabling any actuator or changing safety policy. Malformed limits fail closed; evidence is discarded on owner or
session change and a failed reply never preserves a previous green state. Validation rules and defaults are
listed in the [desktop note](../xWalk-rpi5-os.md#telemetry-driven-boot-readiness).

## 2. Source location

`xWalk-rpi5-os/xWalkRuntime` - source directory

## 3. Directory layout

```text
xWalkRuntime/
    CMakeLists.txt                         Static library xWalkOsRuntime and its Google Test
    include/XWalkProcesses.h               Controller and Traffic ownership
    include/XWalkChild.h                   Process-group child process
    include/XWalkTelemetry.h               Read-only telemetry polling and reply decoding
    include/XWalkReadiness.h               Five-check readiness evaluator
    include/XWalkBatteryTrend.h            Voltage-trend charging estimate
    src/                                   Implementations of the above
    test/src/xWalkRuntimeGoogleTest.cpp    Ownership, telemetry, readiness and trend tests
```

## 4. Public interface

Namespace `xwalk::hal`:

- `XWalkProcesses`: `start`, `stop`,
  `stopAll`, `busy`, `owner`, `trafficActive`, `active`; signals `controllerStopping`, `controllerStarted`,
  `event`, `failure`, `changed`.
- `XWalkTelemetry`: `start(settings)`,
  `stop()`, `snapshot()`, `decode(kind, bytes)`, `deferredSensor(kind, bytes)`; signal `changed`.
- `XWalkReadiness`: `configure`, `reset`,
  `begin`, `accept`, `snapshot`.
- `XWalkBatteryTrend`:
  `sample(voltage, nowMs)` with voltage strictly between 0 and 9.9 V, and `estimatedCharging(nowMs)`.

## 5. Build

CMake target `xWalkOsRuntime` (static, C++17) links `Qt5::Core`, `xWalkOsBuild` and `xWalkOsTrace`, and compiles
with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through the
[desktop root](../xWalk-rpi5-os.md) to compose its dependencies.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkRuntime --output-on-failure
./build-host/xWalkRuntimeGoogleTest --gtest_filter="*BackendSelection"
```

Tests cover process ownership, backend selection, host video arguments, telemetry decoding and deferrals, the
initial health handshake, readiness expiry and session changes, the charging estimate, and shutdown of an
unresponsive worker. They use `xwalk-os-stub` or the `xWalkProcessFixture`; some cases run in host mode only and
skip in standalone.

## 7. Safety and constraints

- Telemetry is read-only; monitoring never selects Vehicle.
- STOP shuts down every owned controller process and does not silently restart it.
- The charging indication is an estimate, not a hardware charging signal.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkDesktop](../xWalkDesktop/xWalkDesktop.md)
- [xWalkStub](../xWalkStub/xWalkStub.md)
- [xWalk-rpi5-node](../../../05-xwalk-node/xWalk-rpi5-node/xWalk-rpi5-node.md)

---

[Previous page](../xWalkResources/xWalkResources.md) · [Chapter index](../../index.md) · [Next page](../xWalkSettings/xWalkSettings.md)
