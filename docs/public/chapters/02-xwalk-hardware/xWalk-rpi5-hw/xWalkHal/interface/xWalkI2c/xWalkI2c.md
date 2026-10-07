<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkI2c

**2. xWalk hardware &middot; Module 76**

<!-- xwalk-page-header:end -->

# xWalkI2c

`xWalkI2c` is the hardware-independent I2C interface of the xWalk HAL. It provides a concrete, non-virtual
`XWalkI2c` callback object and an optional Linux `i2c-dev` backend, `XWalkI2cLinux`, used by the Robot HAT
PWM, ADC and vehicle components.

## 1. Overview

`XWalkI2c` is intentionally independent of Raspberry Pi hardware. It stores C-style callback pointers, one
non-owning context pointer and a transaction mutex. It never opens a platform device; every bus operation is
forwarded to the bound backend.

- Composition is explicit at the application or test entry point: construct the backend first, construct a
  separate `XWalkI2c` with a non-owning pointer to that backend, then pass the I2C object by reference to
  consumers.
- The Linux backend does not contain or own an `XWalkI2c` object. It owns the Linux file descriptor, which
  stays outside `XWalkI2c`, and uses Linux `i2c-dev` access without virtual functions in the operation path.
- All system calls of the backend are isolated behind the injectable `XWalkI2cDevice` boundary. Production
  uses `XWalkI2cDeviceLinux`; host tests and the stub simulation inject `XWalkI2cHostStub`, which mirrors
  only device open, address selection, SMBus transfer and close. This executes core validation, Linux retry
  logic and Linux transaction encoding without physical hardware.
- `XWalkI2c` binds to the backend through the `XHAL_I2C_*_CALLBACK` macros from the common library, the same
  macros used on the Raspberry Pi.
- Every public `XWalkI2c` operation validates the seven-bit address (at most `0x7F`) and holds the
  transaction mutex for the complete callback sequence.

Core, Linux, host-stub and simulation-factory operations use `xWalkTrace`. Filtered identifiers
`RPI.001` through `RPI.044`, plus `RPI.383` and `RPI.384` for the combined write-then-read command, describe
lifecycle and transaction progress. Warnings and errors bypass UID filtering, and numeric HAL assertion
signals identify failed validation, exhausted retries, hardware-test failures and host-test checks. The
diagnostic assertion macro records a signal; normal exception and C++ assertion behavior remains responsible
for control flow.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c` -
source directory

## 3. Directory layout

```text
xWalkI2c/
├── CMakeLists.txt                         Module build, options, xWalkI2c and xWalkI2cLinux targets
├── core/
│   ├── include/xHal_Rpi5CarI2c.h          Hardware-independent public I2C contract
│   └── src/
│       ├── xHal_Rpi5CarI2c.cpp            Validated, serialized callback forwarding
│       └── xHal_Rpi5CarI2cLifecycle.cpp   Callback validation and construction
├── hardware/
│   ├── include/
│   │   ├── xHal_Rpi5CarI2cDevice.h        Injectable Linux device-operation boundary
│   │   ├── xHal_Rpi5CarI2cDeviceLinux.h   Production system-call adapter
│   │   └── xHal_Rpi5CarI2cLinux.h         Linux backend ownership and retry contract
│   ├── src/
│   │   ├── xHal_Rpi5CarI2cDeviceLinux.cpp open, I2C_SLAVE and I2C_SMBUS ioctl calls
│   │   ├── xHal_Rpi5CarI2cLinux.cpp       SMBus encoding, retry loops and callback operations
│   │   └── xHal_Rpi5CarI2cLinuxLifecycle.cpp  Descriptor and retry-count lifecycle
│   └── test/src/xHal_Rpi5CarI2cLinuxHardwareTest.cpp  Opt-in physical address-probe test
├── simulation/                            Standalone stub or hardware runner
└── test/                                  GoogleTest host suite
```

## 4. Child modules

- [xWalkI2c Simulation](simulation/xWalkI2c%20Simulation.md) - standalone runner with stub or hardware
  device backend and persistent trace selection.
- [xWalkI2c Tests](test/xWalkI2c%20Tests.md) - device-free GoogleTest host suite.

## 5. Public interface

The public header
xHal_Rpi5CarI2c.h
declares `xwalk::hal::XWalkI2c`:

| Member | Behavior |
|---|---|
| Constructor | Requires probe, write-register and read callbacks; the other two are optional |
| `probe(address)` | Reports whether a device responds at the address |
| `read(address, length)` | Reads a requested number of bytes from the device |
| `readRegister(address, reg, length)` | Reads register bytes; throws if the callback is missing |
| `writeRegister(address, reg, data)` | Writes a register followed by the supplied data bytes |
| `writeRegisterThenRead(address, reg, data, length)` | Writes then reads under one held transaction mutex |
| `tryWriteRegister(address, reg, data)` | Non-throwing write used by actuator cleanup |

`tryWriteRegister()` returns a Boolean status for invalid input, a missing safe callback or backend write
failure; it does not intercept an exception. `writeRegisterThenRead()` issues the write callback and the
read callback as two bus operations while the object mutex excludes other `XWalkI2c` callers.

The objects are neither copyable nor movable. Callback types (`i2cprobecallback`, `i2cwriteregistercallback`,
`i2creadcallback`, `i2creadregistercallback`, `i2ctrywriteregistercallback`) are defined in the common
library `xHal_Rpi5CarTypes.h`, and the binding macros in `xHal_Rpi5CarCommon.h`.

| Callback | Linux backend responsibility |
|---|---|
| `i2cprobecallback` | Select an address and report whether the device responds |
| `i2cwriteregistercallback` | Write a register followed by the supplied data bytes |
| `i2creadcallback` | Read a requested number of bytes from the selected device |
| `i2creadregistercallback` | Atomically select a register and read consecutive bytes |
| `i2ctrywriteregistercallback` | Attempt a validated register write and return status without throwing |

### Linux backend

The header `hardware/include/xHal_Rpi5CarI2cLinux.h`
(hardware/include)
declares `XWalkI2cLinux`. It accepts a device path (default `/dev/i2c-1`) and a retry count (default `5`;
zero is rejected), optionally with an injected `XWalkI2cDevice`. The injected device must outlive the
backend. Each operation serializes on the backend mutex and retries up to the configured count.

| Item | Value |
|---|---|
| Default Linux I2C device | `/dev/i2c-1` (bus `1`) |
| Robot HAT addresses | `0x14`, `0x15`, `0x16` |
| Retry count | `5` |
| Probe | SMBus quick write |
| Sequential read | Address selection followed by SMBus byte reads, 1 through 32 bytes |
| Register read | One SMBus I2C-block read, 1 through 32 bytes |
| One-data-byte write | SMBus byte-data write |
| Two-data-byte write | SMBus word write; payload byte order is transmitted unchanged |
| Larger write | SMBus I2C block write, at most 32 bytes |

PWM callers such as `xWalkPwm` place the high byte before the low byte in the payload.

## 6. Build

The module builds directly without `xWalkPwm` and without Raspberry Pi hardware. Its CMake configuration
automatically adds the adjacent `xWalkLibraryCommon` and `xWalkTrace` dependencies when they are not already
targets. Run all commands from the repository root.

| CMake option | Default | Purpose |
|---|---:|---|
| `XWALK_I2C_BUILD_HOST_TESTS` | `OFF` | Build the Linux backend and the device-free host tests |
| `XWALK_I2C_BUILD_HARDWARE_TESTS` | `OFF` | Build the Linux backend and the RPi hardware probe test |
| `XWALK_I2C_BUILD_LINUX_BACKEND` | `OFF` | Build `xWalkI2cLinux` without tests (forced on by the simulation) |
| `XWALK_I2C_HARDWARE_DEVICE` | `/dev/i2c-1` | Device path passed to the hardware test |

Any option that builds the Linux backend or tests fails configuration on non-Linux systems.

| Target | Output |
|---|---|
| `xWalkI2c` | `libxWalkI2c.a`, the hardware-independent callback object |
| `xWalkI2cLinux` | `libxWalkI2cLinux.a`, the Linux `i2c-dev` backend |
| `xWalkTrace` | `xWalkTrace/libxWalkTrace.a`, shared filtered and unfiltered diagnostics |

`xWalkLibraryCommon` is a header-only interface target, so it propagates shared types, math operations and
exception helpers without producing a separate archive. `xWalkTrace` uses the generated XML inventory and is
linked privately through the module targets.

Library only:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-lib -DCMAKE_BUILD_TYPE=Release
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-lib --parallel
```

Host tests:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host -DXWALK_I2C_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host --parallel
```

Hardware compilation without execution (also possible on a Linux host):

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c -B xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-rpi -DXWALK_I2C_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-rpi --parallel
```

This creates `libxWalkI2cLinux.a` and the `xWalkI2cLinuxHardwareTest` executable.

Cleaning removes only generated build directories; it does not remove `core`, `hardware`, `test`,
`CMakeLists.txt` or the common library source:

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host --target clean
cmake -E remove_directory xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host
cmake -E remove_directory xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-rpi
cmake -E remove_directory xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-lib
```

## 7. Configuration

Set `XWALK_I2C_HARDWARE_DEVICE` during CMake configuration when the prepared target uses another bus path.
The selected path is passed to the hardware test; the test does not scan or guess an I2C bus. The
simulation selects its device path with `XWALK_I2C_SIMULATION_DEVICE`. The trace configuration generator
`xHal_Rpi5CarI2cTraceConfig.py` in
simulation/config
is shared by the simulation and the host test.

## 8. Testing

Host tests run first and never open `/dev/i2c-*`:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-host -L host --output-on-failure
```

The suite registers CTest `xWalkI2cHostTest` (label `host`); see [xWalkI2c Tests](test/xWalkI2c%20Tests.md).

The hardware test `xWalkI2cLinuxHardwareProbeTest` (label `hardware`) opens the configured device and
succeeds only when one of `0x14`, `0x15` or `0x16` responds. List it without running it:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/build-rpi -N -L hardware
```

Do not run it on a machine without the configured device and a connected Robot HAT. Execution requires
explicit approval and a confirmed correct and safe Raspberry Pi and Robot HAT setup.

### Hardware status and preparation

The backend has been compiled on a Linux host but has not yet been validated against physical Robot HAT
hardware. No additional SunFounder repository is required for the C++ Linux backend; the hardware-specific
requirements are the Robot HAT register protocol, its firmware and Linux I2C device access.

Enable I2C using the configuration method of the installed Raspberry Pi OS, reboot if required, and inspect
bus 1 read-only before any write test:

```bash
ls -l /dev/i2c-1
```

```bash
i2cdetect -y 1
```

At least one of `14`, `15` or `16` should appear. If none appears, check power, cabling, I2C enablement,
permissions and Robot HAT firmware before running any PWM test.

Recommended approved hardware-test order, with the vehicle raised so its wheels cannot move unexpectedly:

| Order | Hardware test | Expected behavior |
|---:|---|---|
| 1 | Device-file test | `/dev/i2c-1` can be opened |
| 2 | Address-probe test | One expected Robot HAT address responds |
| 3 | Zero-output write | A selected PWM channel is written with value zero |
| 4 | Fixed PWM output | A known frequency and duty cycle are generated |
| 5 | Scope or logic-analyzer check | Frequency, duty cycle and byte order match the request |
| 6 | Channel mapping | Physical outputs P0 through P19 use the expected timer groups |
| 7 | Repeated-write test | No intermittent I2C errors occur during extended operation |

## 9. Dependencies

- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md) - shared types, callback
  aliases, binding macros, Robot HAT constants and address validation.
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) - trace service and inventory.
- GoogleTest and Python 3 for host tests; Linux `i2c-dev` headers for the backend.

## 10. Safety and constraints

- Linux only for the backend, tests and simulation.
- Addresses are seven-bit; transfer lengths are 1 through 32 bytes for backend reads and writes.
- The hardware simulation binary and the hardware test perform real bus operations and are opt-in.
- Do not execute hardware binaries without explicit approval and a confirmed safe setup.

## 11. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkPwm](../../device/xWalkPwm/xWalkPwm.md)
- [xWalkAdc](../../device/xWalkAdc/xWalkAdc.md)
- [xWalkPicarx](../../../xWalkDriver/xWalkVehicle/xWalkPicarx/xWalkPicarx.md)

---

[Previous page](../test/xWalkHal%20Interface%20Tests.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkI2c%20Simulation.md)
