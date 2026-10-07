<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkUserButton

**2. xWalk hardware &middot; Module 65**

<!-- xwalk-page-header:end -->

# xWalkUserButton

C++17 active-low Robot HAT user-button monitoring for the xWalk Firmware HAL. The module monitors one active-low
pull-up GPIO input and dispatches press, release, click, state-change, long-press, and long-press-release
callbacks.

## 1. Overview

The application creates the GPIO as an input with pull-up bias and passes it by reference. `XWalkUserButton`
stores a non-owning pointer, so the GPIO must outlive the monitor and its worker.

```cpp
XWalkHal::XWalkGpio buttonGpio(&backend, callbacks, "USER",
    XWalkHal::XWalkGpioMode::Input, XWalkHal::XWalkGpioPull::Up);
XWalkHal::XWalkUserButton button(buttonGpio);
```

The button owns only its monitoring thread. `stop()` and destruction join the worker but do not close or release
the caller-owned GPIO.

Ported behavior:

- Active-low button state over a pull-up GPIO input.
- 50-millisecond polling interval.
- Initial GPIO sample used as the transition baseline without dispatching an event.
- Press, release, short-click, and combined state callbacks.
- Long-press and long-press-release callbacks.
- Shared long-press threshold clamped from 2.0 through 5.0 seconds, defaulting to 2.0 seconds.
- Long-press configuration captured when each press begins.
- Click suppressed after a recognized long press.
- Active and most recently completed press duration in seconds.
- Idempotent `start()` while monitoring is already active.
- Worker GPIO and callback operations must not throw; a violation terminates the process.
- Deterministic worker joining during destruction.

A button already held when `start()` samples the GPIO remains the initial baseline. It must be released and
pressed again before a press transition is dispatched.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton`

Source directory

## 3. Directory layout

```text
xWalkUserButton/
├── CMakeLists.txt                                       Library, host-test, and hardware-test targets
├── include/
│   ├── xHal_Rpi5CarUserButton.h                         Public API, synchronized state, and worker ownership
│   └── xHal_Rpi5CarUserButtonTypes.h                    Context-based callback function-pointer aliases
├── src/
│   ├── xHal_Rpi5CarUserButton.cpp                       Polling, transitions, timing, and callbacks
│   └── xHal_Rpi5CarUserButtonLifecycle.cpp              GPIO binding and deterministic worker cleanup
├── simulation/                                          Standalone host simulation of a short press
└── test/
    ├── hardware/src/xHal_Rpi5CarUserButtonHardwareTest.cpp  Robot HAT USER input monitor test
    ├── include/xHal_Rpi5CarUserButtonTestSupport.h      xwalk::hal::test::userbutton declarations
    └── src/
        ├── xHal_Rpi5CarUserButtonTest.cpp               Short press, long press, failure, and trace tests
        └── xHal_Rpi5CarUserButtonTestSupport.cpp        Named in-memory GPIO and event callbacks
```

## 4. Child modules

- [xWalkUserButton Simulation](simulation/xWalkUserButton%20Simulation.md) - standalone host simulation and
  trace selection.

## 5. Public interface

Headers: `include`

| Declaration | Behavior |
|---|---|
| `explicit XWalkUserButton(XWalkGpio& gpio)` | Binds the caller-owned GPIO |
| `start()`, `stop()`, `close()` | Start or join the worker; `close()` is the compatibility alias for `stop()` |
| `setOnClick`, `setOnPress`, `setOnRelease` | Register `userbuttoncallback` handlers |
| `setOnPressReleased` | Registers a `userbuttonstatecallback` receiving the pressed state |
| `setOnLongPress`, `setOnLongPressReleased` | Register long-press handlers with a 2.0 through 5.0 s threshold |
| `state()`, `isPressed()` | Report the current pressed state |
| `pressedForSeconds()`, `longPressDurationSeconds()` | Report press duration and threshold in seconds |
| `isRunning() const noexcept` | Reports whether the worker is active |

Callbacks execute on the monitoring worker. They must return promptly and must not call `stop()`, `close()`, or
destroy the button object because those actions would attempt to join the current thread. Callback contexts are
non-owning and must remain valid until the callback is cleared and the worker is joined.

Configuration and control methods may be called from one controlling execution context. State and callback
configuration are mutex-protected for observation while monitoring runs. The class is neither copyable nor
movable.

## 6. Build

The library target is `xWalkUserButton`, a static C++17 library linked publicly to `xWalkLibraryCommon` and
`xWalkGpio` and privately to `xWalkTrace`. The workspace root adds it with
`add_subdirectory(xWalkHal/device/xWalkUserButton)`.

| CMake option | Default | Effect |
|---|---|---|
| `XWALK_USER_BUTTON_BUILD_HOST_TESTS` | `OFF` | Builds `xWalkUserButtonTest`; also enables the GPIO host tests |
| `XWALK_USER_BUTTON_BUILD_HARDWARE_TESTS` | `OFF` | Builds `xWalkUserButtonHardwareTest` with `xWalkGpioLinux` |

## 7. Configuration

Host tests generate `generated/xWalkUserButtonTrace.xml` in the build tree with
`simulation/config/xHal_Rpi5CarUserButtonTraceConfig.py`, preserving previously stored trace states.

## 8. Testing

Run these commands from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton -B xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-host -DXWALK_USER_BUTTON_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-host --output-on-failure
```

The host configuration runs the UserButton and GPIO suites without accessing a physical GPIO device. The module
CTest is `xWalkUserButtonHostTest` with label `host`. Reusable callback state lives in
`xwalk::hal::test::userbutton`. The host suite also verifies persistent trace-selector behavior.

Hardware compilation and test discovery:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton -B xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-rpi -DXWALK_USER_BUTTON_BUILD_HARDWARE_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/device/xWalkUserButton/build-rpi -N -L hardware
```

These commands compile and list `xWalkUserButtonHardwareMonitorTest` without executing it. Running the
executable accesses `/dev/gpiochip0` and claims the Robot HAT USER input.

## 9. Dependencies

- `xWalkGpio` - callback-based GPIO abstraction; `xWalkGpioLinux` for hardware tests.
- `xWalkLibraryCommon` - fixed-width types, threading aliases, and user-button constants.
- `xWalkTrace` from `xWalk-rpi5-trace` - trace macros and catalogue metadata.

## 10. Safety and constraints

- The caller owns the GPIO, which must outlive the button and its worker.
- Callbacks must not throw, block, or stop the worker from its own thread.
- Run the hardware test only with explicit approval on a confirmed safe Raspberry Pi and Robot HAT setup.

## 11. Related notes

- [xWalkHal Device Layer](../xWalkHal%20Device%20Layer.md)
- [xWalkHal Device Tests](../test/xWalkHal%20Device%20Tests.md)
- [xWalkGpio](../../interface/xWalkGpio/xWalkGpio.md)

---

[Previous page](../xWalkUltrasonic/simulation/xWalkUltrasonic%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkUserButton%20Simulation.md)
