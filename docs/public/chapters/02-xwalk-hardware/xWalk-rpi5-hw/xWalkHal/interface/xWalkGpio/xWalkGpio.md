<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkGpio

**2. xWalk hardware &middot; Module 72**

<!-- xwalk-page-header:end -->

# xWalkGpio

`xWalkGpio` is the C++17 Robot HAT GPIO abstraction of the xWalk Firmware HAL. `XWalkGpio` represents one
Robot HAT GPIO line and forwards every operation through a non-owning backend context and callback set. The
optional `xWalkGpioLinux` backend implements those callbacks with the Linux GPIO character-device ABI.

## 1. Overview

The application creates the backend first, then passes its pointer and callbacks to the GPIO object:

```cpp
xwalk::hal::XWalkGpioLinux backend;
const xwalk::hal::XWalkGpioCallbacks callbacks = XHAL_GPIO_CALLBACKS(xwalk::hal::XWalkGpioLinux);
xwalk::hal::XWalkGpio directionPin(&backend, callbacks, "D4");
static_cast<void>(directionPin.high());
```

One Linux backend instance is dedicated to one `XWalkGpio` instance because it owns that pin's line or event
descriptor. This keeps pin ownership explicit. Consumers such as `xWalkMotor`, `xWalkLed`, `xWalkBuzzer`, and
`xWalkUserButton` receive existing GPIO objects by reference and store non-owning pointers.
`xWalkUltrasonic` receives separate trigger and echo `XWalkGpio` objects by reference; it reconfigures those
caller-owned objects but does not own or destroy them.

### Ported behavior

| GPIO contract | C++ behavior |
|---|---|
| Numeric pins from the Robot HAT dictionary | Preserved with validation |
| Names `D0` through `D16` and hardware aliases | Preserved |
| Default output mode and low value | Preserved |
| Reading an output automatically changes it to input | Preserved |
| Writing an input automatically changes it to output | Preserved |
| Pull-up, pull-down, and no-pull configuration | Preserved |
| `on`, `off`, `high`, and `low` aliases | Preserved |
| Rising, falling, and both-edge handlers | Preserved |
| Default 200-millisecond interrupt debounce | Preserved (`XHAL_RPI5CAR_GPIO_DEFAULT_DEBOUNCE_MS`) |
| `close` and `deinit` interrupt cancellation | Preserved |
| Logical active state | Implemented as explicit logical polarity (`activeHigh`) |

The supported aliases include `SW`, `USER`, `LED`, `BOARD_TYPE`, `RST`, `BLEINT`, `BLERST`, `MCURST`, and
`CE`. Duplicate aliases intentionally resolve to the same Linux GPIO line; for example, `D14` and `LED` both
map to GPIO26, and `D6`, `SW`, and `USER` share one line.

### Linux backend

The backend uses the version-one Linux GPIO character-device ABI exposed by `<linux/gpio.h>`. All system
calls are isolated behind `XWalkGpioDevice`. Production injects `XWalkGpioDeviceLinux`; host execution injects
`XWalkGpioHostStub` and exercises the same chip validation, line requests, direction changes, and digital I/O
without opening a device.

The Linux owner accepts a deployment-selected device path (default `XHAL_RPI5CAR_GPIO_DEFAULT_DEVICE`,
`/dev/gpiochip0`) plus optional exact kernel chip name and label checks and a minimum required line count.
An identity or size mismatch closes the descriptor and fails construction before a GPIO line is claimed.
Device selection remains an application boot responsibility; this backend does not scan `/dev/gpiochip*`.

The event worker uses kernel monotonic timestamps for debounce decisions. Application interrupt handlers run
on the backend worker thread and must not throw, block indefinitely, or outlive their context.

### Timestamped pulse acquisition

The optional paired `beginPulse` and `readPulse` callbacks measure physical high pulses from backend edge
timestamps. Pi boot supplies Linux kernel edge capture for ultrasonic echo timing; other backends keep the
polling fallback, and `supportsPulseTiming` reports which applies. Arm before triggering, serialize
acquisition, and bound each read by its timeout in microseconds. Closing or reconfiguring the GPIO releases
its pulse registration. Linux acquisition rejects malformed events and incompatible clock timestamps and
drains old events before each measurement.

The Linux backend requires monotonic event timestamps (Linux 5.7 or newer).
[Kernel event documentation](https://docs.kernel.org/userspace-api/gpio/gpio-lineevent-data-read.html)
describes the edge timestamp and bounded queue contract.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio` -
source directory

## 3. Directory layout

```text
xWalkGpio/
    CMakeLists.txt                              Core library, Linux backend, and hardware-test targets
    core/
        include/xHal_Rpi5CarGpio.h              Public API, enums, callback contracts, XHAL_GPIO_CALLBACKS
        src/xHal_Rpi5CarGpioLifecycle.cpp       Callback validation, named-pin mapping, construction
        src/xHal_Rpi5CarGpio.cpp                Mode changes, polarity, digital I/O, interrupt and pulse forwarding
    hardware/
        include/xHal_Rpi5CarGpioLinux.h         Linux backend ownership and concurrency contract
        include/xHal_Rpi5CarGpioDevice.h        Injectable Linux GPIO operation boundary
        include/xHal_Rpi5CarGpioDeviceLinux.h   Production system-call adapter declaration
        src/xHal_Rpi5CarGpioLinuxLifecycle.cpp  GPIO chip and line descriptor lifecycle
        src/xHal_Rpi5CarGpioLinux.cpp           Line claims, digital I/O, event polling, debounce, pulses
        src/xHal_Rpi5CarGpioDeviceLinux.cpp     Production system-call adapter
        test/src/xHal_Rpi5CarGpioHardwareTest.cpp  Opt-in LED-line output test
    simulation/                                 Standalone simulation executable and host stub
    test/                                       GoogleTest host suite and shared test support
```

## 4. Child modules

- [xWalkGpio Simulation](simulation/xWalkGpio%20Simulation.md) - standalone executable with a device-free
  stub or an explicit hardware backend.
- [xWalkGpio Tests](test/xWalkGpio%20Tests.md) - GoogleTest host suite built on the host stub.

## 5. Public interface

The public header `xHal_Rpi5CarGpio.h` is in
`core/include`.

| Element | Contract |
|---|---|
| `XWalkGpioMode` | `Output` or `Input` |
| `XWalkGpioPull` | `None`, `Up`, or `Down` bias |
| `XWalkGpioEdge` | `Falling`, `Rising`, or `Both` |
| `XWalkGpioCallbacks` | Configure, read, write, interrupt, cancel, and optional pulse callbacks |
| `XHAL_GPIO_CALLBACKS(BACKEND_TYPE)` | Builds a callback table bridging to a backend type |
| `XWalkGpio(context, callbacks, pin or pinName, mode, pull, activeHigh)` | Numeric or named construction |
| `setup`, `read`, `write`, `on`, `off`, `high`, `low` | Mode control and logical digital I/O |
| `irq(handlerContext, handler, edge, debounceMs, pull)` | Registers a debounced edge handler |
| `close`, `deinit` | Cancel the interrupt and release backend registrations |
| `supportsPulseTiming`, `beginPulse`, `readPulse(timeoutUs)` | Timestamped high-pulse measurement |
| `pin`, `mode`, `pull`, `name` | State accessors |

`XWalkGpio` is neither copyable nor movable. The backend context is non-owning and must outlive the GPIO
object. The Linux backend is declared in `xHal_Rpi5CarGpioLinux.h` under
`hardware/include`.

## 6. Build

| Option | Default | Effect |
|---|---|---|
| `XWALK_GPIO_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkGpioLinux` and the host suite in `test` |
| `XWALK_GPIO_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkGpioLinux` and `xWalkGpioHardwareTest` |
| `XWALK_GPIO_BUILD_LINUX_BACKEND` | `OFF` | Builds `xWalkGpioLinux` without tests |
| `XWALK_GPIO_HARDWARE_DEVICE` | `/dev/gpiochip0` | Device path passed to the hardware test |
| `XWALK_GPIO_HARDWARE_CHIP_NAME` | empty | Optional exact chip name checked by the hardware test |
| `XWALK_GPIO_HARDWARE_CHIP_LABEL` | empty | Optional exact chip label checked by the hardware test |

Targets: `xWalkGpio` (static core library) and, when any option above is enabled, `xWalkGpioLinux` (static
backend linked with `Threads::Threads`). Enabling any of the three build options on a non-Linux host fails
configuration. In the workspace build of `xWalk-rpi5-hw`, the root forces `XWALK_GPIO_BUILD_HOST_TESTS` from
the host profile and `XWALK_GPIO_BUILD_HARDWARE_TESTS` from `XWALK_BUILD_RPI`.

Standalone host build:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio -B build-host/xWalkGpio -DXWALK_GPIO_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/xWalkGpio --parallel
```

Hardware compilation without execution (the chip name and label should match the controller used by boot):

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio -B build-rpi/xWalkGpio -DXWALK_GPIO_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-rpi/xWalkGpio --parallel
```

## 7. Testing

The host suite `xWalkGpioHostTest` (label `host`) injects the host mirror into the production Linux backend
and never opens `/dev/gpiochip0`. See [xWalkGpio Tests](test/xWalkGpio%20Tests.md).

```bash
ctest --test-dir build-host/xWalkGpio -L host --output-on-failure
```

The hardware test `xWalkGpioHardwareOutputTest` (label `hardware`) may only be listed:

```bash
ctest --test-dir build-rpi/xWalkGpio -N -L hardware
```

## 8. Dependencies

- `xWalkLibraryCommon` (public) for project types and GPIO defaults.
- `xWalkTrace` (private) for trace and error signals.
- Linux GPIO UAPI headers and `Threads::Threads` for `xWalkGpioLinux`.
- GoogleTest and Python 3 for the host suite and trace-configuration generation.

## 9. Safety and constraints

- Do not run the hardware test without explicit approval and a confirmed, safe Raspberry Pi and Robot HAT
  setup. The test opens the configured GPIO chip, claims GPIO26 (`LED`), and drives it low.
- Interrupt handlers execute on the backend worker thread; they must not throw, block indefinitely, or
  outlive their context.
- Pulse acquisition must be armed before triggering, serialized, and bounded by its timeout.
- One `XWalkGpioLinux` instance serves exactly one `XWalkGpio` line.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkHal Interface Tests](../test/xWalkHal%20Interface%20Tests.md)
- [xWalkUltrasonic](../../device/xWalkUltrasonic/xWalkUltrasonic.md)
- [xWalkMotor](../../sensor/xWalkMotor/xWalkMotor.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)

---

[Previous page](../xWalkConfig/simulation/xWalkConfig%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkGpio%20Simulation.md)
