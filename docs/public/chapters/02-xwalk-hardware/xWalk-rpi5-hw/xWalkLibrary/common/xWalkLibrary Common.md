<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkLibrary Common

**2. xWalk hardware &middot; Module 113**

<!-- xwalk-page-header:end -->

# xWalkLibrary Common

`xWalkLibrary/common` provides the header-only `xWalkLibraryCommon` interface target: workspace-level C++17
declarations, shared type aliases, hardware constants, and centralized standard-library includes used by the
xWalk HAL, Driver, Controller, Agent, CLI, trace, and application modules.

## 1. Overview

The public headers are stored under `include/`, while the CMake interface definition remains in this directory.
`xWalkLibraryCommon` exports `include/` and the generated IW header directory `../auto-gen`, and requires C++17.
Consumers include headers by basename and link the stable `xWalkLibraryCommon` target; they must not add the
directory globally.

The target also carries the workspace-wide GCC/Clang warning, sanitizer, ThreadSanitizer, and coverage options as
interface options, so every consumer inherits them.

## 2. Source location

`xWalk-rpi5-hw/xWalkLibrary/common` (source directory)

## 3. Directory layout

```text
common/
    CMakeLists.txt                          Interface target, compile options and host tests
    include/
        xHal_Rpi5CarCommon.h                Shared facilities, I2C callback bridges, hardware constants
        xHal_Rpi5CarCommonFunctions.h       Reusable non-member functions (xwalk::hal::common)
        xHal_Rpi5CarFileFunctions.h         Filesystem wrappers (xwalk::hal)
        xHal_Rpi5CarFormatFunctions.h       Bounded XWALK_SNPRINTF / XWALK_VSNPRINTF formatting macros
        xHal_Rpi5CarLinuxHeaders.h          Linux headers required only by hardware backends
        xHal_Rpi5CarMath.h                  Uppercase math macros such as XHAL_POWER and XHAL_SINE
        xHal_Rpi5CarStandardHeaders.h       Centralized standard-library includes
        xHal_Rpi5CarTestFunctions.h         Always-active checks and process-isolation test helpers
        xHal_Rpi5CarTypes.h                 Shared scalar, container, and callback aliases
        xHal_Rpi5CarSignal.h                Common signal argument structure
        xHal_Rpi5CarSignalTypes.h           Borrowed signal arguments without a transport dependency
        xHal_Rpi5CarOperationCancelled.h    Non-error interruption signal for synchronous providers
        xHal_Rpi5CarProcessLease.h          Exclusive Linux process lease held until resource shutdown
        xHal_Rpi5CarCameraSnapshot.h        Bounded, fresh camera snapshots published by atomic rename
        xHal_Rpi5CarSharedVideoCapture.h    Shared camera snapshots adapted to OpenCV capture consumers
        xHal_Rpi5CarProximityIpc.h          Bounded front-proximity safety contract
        xControllerCommand.h                Controller command identifiers and protocol signals
        xControllerMacros.h                 Bounded Controller scheduling limits
        xWalkControllerConfigTypes.h        Shared Controller configuration and request data
        xWalk_Rpi5CarAgentConfigType.h      Shared PiCar-X Agent configuration types
        xWalk_Rpi5CarFailureObservability.h Bounded thread-safe failure event observability
    configuration/                          Architecture-independent configuration (placeholder)
    models/vosk/                            Vosk small US English model 0.15 and Apache 2.0 LICENSE
    test/
        src/xWalkLibraryFormatTest.cpp      Bounded formatting host test
        xWalkLibraryAgentConfigTypeTest.cmake  Agent context surface check
```

## 4. Public interface

Primary entry header:

```cpp
#include "xHal_Rpi5CarCommon.h"
```

### Types and namespaces

`xHal_Rpi5CarTypes.h` declares the
project namespaces and the shared type vocabulary. It includes aliases for standard-library data types used outside
the common boundary: containers, exceptions, streams, filesystem paths and metadata, file-open modes, permission
options, synchronization objects, and error codes. Modules use aliases such as `stringvector`, `logicerror`,
`filesystempath`, `outputfilestream`, `fileopenmode`, and `errorcode` instead of spelling the underlying standard
type directly. Standard-library qualification remains inside the common boundary.

Generic aliases are exported into three layer-specific namespaces:

| Layer | Full namespace | Concise namespace |
| --- | --- | --- |
| HAL | `xwalk::hal` | `hal` |
| Agent | `xwalk::agent` | `agent` |
| Controller | `xwalk::controller` | `ctrl` |

Each layer qualifies shared types through its own concise namespace. HAL-only classes, callbacks, and
sensor-specific structures remain exclusively under `xwalk::hal` and are not re-exported as Controller or Agent
types. The header also keeps the legacy `XWalkHal` namespace alias.

### Functions

- `xHal_Rpi5CarCommonFunctions.h` declares reusable non-member production functions in
  `namespace xwalk::hal::common`. Module source files call them with the `common::` qualifier instead of defining
  anonymous or module-local free helper functions. Class-specific behavior remains a class method in its owning
  module.
- `xHal_Rpi5CarFileFunctions.h` declares filesystem operations directly in `namespace xwalk::hal`, matching types
  such as `uint32`. Modules call `filesystemEntryExists()`, `filesystemStatus()`, `replaceFilesystemPermissions()`,
  and the other wrappers instead of calling `std::filesystem` operations directly. File-open modes, permission
  options, and line extraction are exposed through typed constants and `readFileLine()`. Complete binary reads use
  `readFileContents()`, and direct-child directory enumeration uses `listFilesystemEntryNames()`.
- `xHal_Rpi5CarTestFunctions.h` provides `xwalk::hal::test::expectFailure()`, which runs an operation in an
  isolated Linux child process and asserts that it does not complete successfully. Host tests use it to verify
  rejected operations without exception handlers.

### Bounded text formatting

Include `xHal_Rpi5CarFormatFunctions.h` and use `XWALK_SNPRINTF(buffer, capacity, format, ...)` or
`XWALK_VSNPRINTF(buffer, capacity, format, arguments)` for bounded in-memory formatting. These macros forward to
`std::snprintf` and `std::vsnprintf` without tracing or changing format strings, return values, truncation, NUL
termination, or zero-capacity length queries. Compiler format diagnostics remain available. As with the standard
functions, format argument types and buffer capacities must be correct; overlapping input/output buffers are
unsupported.

### Standard, Linux, and math headers

All standard-library headers used by the HAL modules are centralized in `xHal_Rpi5CarStandardHeaders.h`.
Submodules include their project header and do not include standard-library headers directly. Linux system headers
needed only by optional hardware backends are centralized in `xHal_Rpi5CarLinuxHeaders.h`; host-only HAL sources do
not include it.

Standard math operations are exposed as uppercase function-like macros in `xHal_Rpi5CarMath.h`. Submodules use
these macros and contain no direct `std::` references. Power and sine calculations use `XHAL_POWER` and
`XHAL_SINE`.

### I2C callback bridges

`xHal_Rpi5CarCommon.h` provides reusable context-to-backend I2C callback bridges, including
`XHAL_I2C_PROBE_CALLBACK`, `XHAL_I2C_WRITE_REGISTER_CALLBACK`, `XHAL_I2C_TRY_WRITE_REGISTER_CALLBACK`,
`XHAL_I2C_READ_CALLBACK`, and `XHAL_I2C_READ_REGISTER_CALLBACK`. Hardware backends bind these macros to their
public device-operation methods.

### Shared hardware constants

Shared hardware constants in `xHal_Rpi5CarCommon.h` use uppercase, project-prefixed macros with units in their
names where applicable:

| Prefix | Content |
| --- | --- |
| `XHAL_RPI5CAR_PWM_` | PWM register and clock definitions |
| `XHAL_RPI5CAR_SERVO_` | Servo angle, pulse, frame, frequency, and period |
| `XHAL_RPI5CAR_ULTRASONIC_` | Sound speed, timing, attempts, and status results |
| `XHAL_RPI5CAR_LINE_TRACKER_` | Channels, thresholds, adaptive reference, weighting, position, and rounding |
| `XHAL_RPI5CAR_ADXL345_` | Address, registers, axes, sample size, sign, and scaling |
| `XHAL_RPI5CAR_RGB_LED_` | Channel indices, connection selectors, packed-color masks, shifts, and scales |
| `XHAL_RPI5CAR_BUZZER_` | Duty-cycle and playback-duration conversion |
| `XHAL_RPI5CAR_LED_` | Blink count, transition timing, duration conversion, and worker polling |
| `XHAL_RPI5CAR_USER_BUTTON_` | Active level, polling interval, long-press limits, and timing conversion |
| `XHAL_RPI5CAR_MUSIC_` | PCM format, theory, MIDI range, volume, rounding, and compatibility |
| `XHAL_RPI5CAR_SPEAKER_` | Task count, chunk size, pause polling, and invalid slot |
| `XHAL_RPI5CAR_DEVICE_` | Device-tree root, node, property, UUID, board pin, motor mode, and hexadecimal limits |
| `XHAL_RPI5CAR_UTILS_` | Volume limits, lazy-reader timing, and millisecond conversion |

Further prefixes in the same header cover ADC, I2C, SPI, GPIO, motor, board, audio, speech, text-to-speech,
language model, firmware, configuration, and trace definitions.

### Agent and Controller shared types

- `xWalk_Rpi5CarAgentConfigType.h` declares `xAgentContext`, which groups the non-owning configuration, motor,
  steering, pan and tilt servo, grayscale, and ultrasonic dependencies used by PiCar-X construction. Every pointer
  must remain non-null and valid for the coordinator lifetime and is never released by the structure.
- `xControllerCommand.h` declares the typed top-level Controller command request macros.
  `xWalkControllerConfigTypes.h` includes it for the command request DTO, while parsing and routing code may
  include it directly when no request structure is required.

### Error reporting

Standard exception types are exposed through the documented aliases in `xHal_Rpi5CarTypes.h`. Traced call sites use
the stable signals declared by `xHal_Rpi5CarErrorSignals.h` (owned by `xWalk-rpi5-trace`) and pass the signal with
a message to their component `ERROR` macro, which records the diagnostic and throws the selected signal's exception
type. The header-only common library throws aliases directly without a trace because xWalkTrace itself depends on
this foundational target. xWalkTrace also throws aliases directly for its own failures to avoid recursive tracing.

## 5. Build

The target is normally built as part of the `xWalk-rpi5-hw` aggregate. Run the following commands from the
repository root to build it separately:

```bash
cmake -S xWalk-rpi5-hw/xWalkLibrary/common -B xWalk-rpi5-hw/xWalkLibrary/common/build
```

```bash
cmake --build xWalk-rpi5-hw/xWalkLibrary/common/build --parallel
```

Remove only the compiled outputs while keeping the configuration:

```bash
cmake --build xWalk-rpi5-hw/xWalkLibrary/common/build --target clean
```

For a completely clean configure, remove the entire generated build directory; the headers and `CMakeLists.txt`
are not removed:

```bash
cmake -E remove_directory xWalk-rpi5-hw/xWalkLibrary/common/build
```

## 6. Configuration

The interface compile options react to aggregate settings:

| Setting | Effect on consumers (GCC/Clang) |
| --- | --- |
| Always | `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion` |
| `XWALK_HAL_BUILD_HOST` | `-UNDEBUG`, because host tests use assertions as checks and operation boundaries |
| `XWALK_ENABLE_STRICT_WARNINGS` | Shadow, format, null-dereference, cast, and old-style-cast warnings |
| `XWALK_ENABLE_SANITIZERS` | AddressSanitizer and UndefinedBehaviorSanitizer without recovery |
| `XWALK_ENABLE_THREAD_SANITIZER` | ThreadSanitizer with PIE |
| `XWALK_ENABLE_COVERAGE` | Clang source coverage, or GCC `--coverage` with atomic profile updates |

## 7. Testing

| Test | Labels | Checks |
| --- | --- | --- |
| `xWalkLibraryFormatHostTest` | `host;library` | Bounded formatting behavior |
| `xWalkLibraryAgentConfigTypeHostTest` | `host;library` | `xAgentContext` field surface |

`xWalkLibraryFormatHostTest` checks length queries, truncation, zero/one-byte capacities, argument evaluation, and
variadic formatting. `xWalkLibraryAgentConfigTypeHostTest` verifies that `xAgentContext` retains only its PiCar-X
dependency fields and does not restore retired Boot service or callback declarations.

Both are registered when `BUILD_TESTING` is enabled:

```bash
ctest --test-dir ../build-host/cmake -L library --output-on-failure
```

The Common target has no hardware tests.

## 8. Dependencies

- C++17 standard library; Linux system headers only for hardware backends.
- Generated IW headers in `xWalkLibrary/auto-gen`.
- No dependency on `xWalkTrace`; the trace runtime depends on this target.

## 9. Safety and constraints

- Keep the target header-only and trace-free; Common headers must not include the trace header.
- Pointers in shared configuration structures are non-owning; the owners control lifetime.
- MQTT configuration support belongs to `xWalk-rpi5-node/xWalkIoT/xWalkMqttInit`, and MQTT trace selection and
  priorities belong to `xWalk-rpi5-trace`; the hardware common library contains no MQTT implementation sources.

## 10. Related notes

- [xWalkLibrary](../xWalkLibrary.md)
- [xWalk-rpi5-hw](../../xWalk-rpi5-hw.md)
- [xWalk-rpi5-trace](../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkLibrary.md) · [Chapter index](../../../index.md) · [Next page](../../xWalkTest/xWalkTest.md)
