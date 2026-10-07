<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkUltrasonic

**2. xWalk hardware &middot; Module 63**

<!-- xwalk-page-header:end -->

# xWalkUltrasonic

C++17 two-pin ultrasonic ranging for the xWalk Firmware HAL. `XWalkUltrasonic` emits a bounded trigger pulse,
measures the echo with a monotonic clock, and returns distance in centimeters.

## 1. Overview

`XWalkUltrasonic` stores non-owning pointers to two caller-created `XWalkGpio` objects. The application creates
the GPIO backends and objects before the sensor, then passes both pins by reference:

```cpp
XWalkGpio trigger(&triggerBackend, triggerCallbacks, "D2");
XWalkGpio echo(&echoBackend, echoCallbacks, "D3");
XWalkUltrasonic ultrasonic(trigger, echo);
const float64 distanceCentimeters = ultrasonic.read();
```

The trigger and echo GPIO objects must outlive the sensor. Construction configures the trigger as an output and
the echo as an input with its internal pull-down enabled. The sensor does not allocate or own either pin.

Ported behavior:

- One-millisecond inactive settling interval.
- Ten-microsecond active trigger pulse.
- Configurable echo timeout, defaulting to 20 milliseconds.
- Distance conversion using a sound speed of 343.3 meters per second.
- Distance rounded to two decimal places in centimeters.
- Up to ten timeout-only retries by default.
- `-1.0` result when every attempt times out.
- `-2.0` result when echo transitions do not form a measurable pulse.
- `0.0` invalid result, without a new trigger, if an earlier echo stays high through the idle-wait timeout.

Before arming or triggering, acquisition waits for the echo input to return low for at most the configured echo
timeout. A late pulse can therefore finish after the 60 ms interval without contaminating the next measurement.
A stuck-high input remains invalid; a subsequent call can recover after it returns low.

Reads are serialized internally. All callers and timeout retries share a minimum 60 ms trigger interval.
Ordinary reads wait for the interval; `tryRead` returns `false` without changing its output when the lock is busy
or the sensor is cooling down. This prevents safety and GUI polling from triggering back-to-back pulses.
`observe` exposes the latest completed acquisition from either reader with its original monotonic timestamp,
even while an ordinary reader is retrying. Observing it never renews its age. GPIO acquisition exceptions publish
an invalid zero result before propagation. Safety consumers must check sample age. No-echo and incomplete-pulse
results remain invalid; they are never converted to clear distance.

When the echo `XWalkGpio` backend supports pulse timing, the sensor arms timestamped pulse acquisition before
the trigger. In the Pi Boot deployment, both echo edges are captured by the kernel before userspace consumes
them, preventing delayed scheduling from shortening a measured echo. The sample's freshness timestamp is its
original trigger time, so delayed processing cannot renew old data. Short pulses still report short distances
immediately; no obstacle filtering or threshold changes are applied.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic`

Source directory

## 3. Directory layout

```text
xWalkUltrasonic/
├── CMakeLists.txt                                   Library and host-test targets
├── include/xHal_Rpi5CarUltrasonic.h                 Public sensor API, constants, and ownership contract
├── src/
│   ├── xHal_Rpi5CarUltrasonic.cpp                   Trigger pulse, echo timing, conversion, and retry behavior
│   └── xHal_Rpi5CarUltrasonicLifecycle.cpp          GPIO binding and initial configuration
├── simulation/                                      Standalone host simulation with an in-memory GPIO backend
└── test/
    ├── include/xHal_Rpi5CarUltrasonicTestSupport.h  xwalk::hal::test::ultrasonic callback declarations
    └── src/
        ├── xHal_Rpi5CarUltrasonicTest.cpp           Echo, timeout, validation, and trace-selector coverage
        └── xHal_Rpi5CarUltrasonicTestSupport.cpp    Reusable named in-memory GPIO test callbacks
```

## 4. Child modules

- [xWalkUltrasonic Simulation](simulation/xWalkUltrasonic%20Simulation.md) - standalone host simulation and
  trace selection.

## 5. Public interface

Header: `xHal_Rpi5CarUltrasonic.h` in
the module `include` directory.

| Declaration | Behavior |
|---|---|
| `XWalkUltrasonic(XWalkGpio& trigger, XWalkGpio& echo, uint32 timeoutMicroseconds = 20000)` | Configures pins |
| `float64 read(uint32 attempts = 10)` | Blocking measurement in centimeters or a negative status |
| `boolean tryRead(float64& centimeters)` | Non-blocking; `false` when busy or cooling down |
| `boolean observe(float64& centimeters, uint64& sampledAtMicroseconds)` | Latest sample and its timestamp |
| `void close()` | Cancels interrupt registrations on both GPIO dependencies |
| `uint32 timeoutMicroseconds() const noexcept` | Returns the configured echo timeout |

The class is neither copyable nor movable.

## 6. Build

The library target is `xWalkUltrasonic`, a static C++17 library linked publicly to `xWalkLibraryCommon` and
`xWalkGpio` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/device/xWalkUltrasonic)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_ULTRASONIC_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkUltrasonicTest`; also enables the GPIO host tests |
| `XWALK_ULTRASONIC_BUILD_HARDWARE_TESTS` | `OFF` | Compiles the Linux GPIO backend and its hardware test |

## 7. Configuration

Host tests generate `generated/xWalkUltrasonicTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarUltrasonicTraceConfig.py`, preserving previously stored trace states.

## 8. Testing

The host test uses callback-driven GPIO simulation. It does not access a Linux GPIO device.

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic -B xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-host -DXWALK_ULTRASONIC_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-host --output-on-failure
```

`xWalkUltrasonicHostTest` (label `host`) covers distance measurement, immediate echo, retry and status results,
timeouts, shared trigger spacing, visible acquisition failures, concurrent safety sampling, late-echo recovery
with and without timestamps, and trace selection. Reusable callback state lives in
`xwalk::hal::test::ultrasonic` rather than the scenario source.

Hardware compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic -B xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-rpi -DXWALK_ULTRASONIC_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkUltrasonic/build-rpi -N -L hardware
```

This configuration compiles `xWalkUltrasonic`, the Linux GPIO backend, and its hardware test. It does not
register an automatic ultrasonic measurement test because trigger and echo wiring is application-specific.

## 9. Dependencies

- `xWalkGpio` - callback-based GPIO abstraction with optional timestamped pulse acquisition.
- `xWalkLibraryCommon` - fixed-width types and ultrasonic constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- Both `XWalkGpio` objects are caller-owned and must outlive the sensor.
- Negative and zero results are invalid and must never be treated as a clear path.
- Safety consumers must check the sample timestamp returned by `observe`.
- Listed GPIO hardware tests drive physical lines; run them only with explicit approval on a confirmed safe
  Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)
- [xWalkBoot](../../../xWalkController/xWalkBoot/xWalkBoot.md)

---

[Previous page](../xWalkServo/simulation/xWalkServo%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkUltrasonic%20Simulation.md)
