<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkSpi

**2. xWalk hardware &middot; Module 81**

<!-- xwalk-page-header:end -->

# xWalkSpi

`xWalkSpi` provides bounded, hardware-independent full-duplex SPI transactions and an optional Linux `spidev`
owner. The core `XWalkSpi` object stores one non-owning callback context and never opens a platform device.

## 1. Overview

- One transfer accepts 1 through 256 bytes and must return exactly as many received bytes as were
  transmitted; the core rejects an empty payload, an oversized payload and a mismatched response length.
- `XWalkSpiLinux` owns the descriptor and observes one injected `XWalkSpiDevice`, which must outlive it.
  Production composition uses `XWalkSpiDeviceLinux`; host composition uses `XWalkSpiHostStub`. This lets host
  tests execute the real configuration and `SPI_IOC_MESSAGE` request-building path without opening
  `/dev/spidev*`.
- The Linux backend configures standard SPI mode 0 through 3, a positive clock frequency in Hertz and 1
  through 32 bits per word, and stores the values reported back by the device. Configuration failure closes
  the descriptor and throws.
- Each transfer is one `spi_ioc_transfer` with `cs_change` set to zero, serialized by the backend mutex.
  Linux owns chip-select assertion for the complete ioctl transaction; a failed or incomplete ioctl throws.
- `XWalkSpi` binds to the backend through `XHAL_SPI_TRANSFER_CALLBACK(BACKEND_TYPE)`.

Core, Linux, host-stub, test and simulation operations use filtered xWalk trace identifiers `RPI.045`
through `RPI.061`. Validation failures also emit unfiltered error and numeric assertion diagnostics before
the normal exception boundary.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi` -
source directory

## 3. Directory layout

```text
xWalkSpi/
├── CMakeLists.txt                         Module build, options, xWalkSpi and xWalkSpiLinux targets
├── core/
│   ├── include/
│   │   ├── xHal_Rpi5CarSpi.h              Public SPI contract and transfer-callback macro
│   │   └── xHal_Rpi5CarSpiTypes.h         XWalkSpiConfiguration and spitransfercallback
│   └── src/
│       ├── xHal_Rpi5CarSpi.cpp            Payload and response validation, callback forwarding
│       └── xHal_Rpi5CarSpiLifecycle.cpp   Callback validation and diagnostics
├── hardware/
│   ├── include/
│   │   ├── xHal_Rpi5CarSpiDevice.h        Injectable device-operation boundary
│   │   ├── xHal_Rpi5CarSpiDeviceLinux.h   Production spidev system-call adapter
│   │   └── xHal_Rpi5CarSpiLinux.h         Linux backend ownership contract
│   ├── src/
│   │   ├── xHal_Rpi5CarSpiDeviceLinux.cpp open, configuration ioctls, transfer and close
│   │   ├── xHal_Rpi5CarSpiLinux.cpp       SPI_IOC_MESSAGE request building and transfer
│   │   └── xHal_Rpi5CarSpiLinuxLifecycle.cpp  Validation, open and configuration
│   └── test/src/xHal_Rpi5CarSpiLinuxHardwareTest.cpp  Opt-in one-byte physical transfer smoke test
├── simulation/                            Standalone stub or hardware runner
└── test/                                  GoogleTest host suite
```

## 4. Child modules

- [xWalkSpi Simulation](simulation/xWalkSpi%20Simulation.md) - standalone runner with stub or hardware
  device backend and persistent trace selection.
- [xWalkSpi Tests](test/xWalkSpi%20Tests.md) - device-free GoogleTest host suite.

## 5. Public interface

- `XWalkSpi(context, transferOperation)` and `transfer(transmitData)` in `xHal_Rpi5CarSpi.h`.
- `XWalkSpiConfiguration` and `spitransfercallback` in `xHal_Rpi5CarSpiTypes.h`.
- `XWalkSpiLinux(devicePath, configuration)` and `XWalkSpiLinux(device, devicePath, configuration)` in
  `xHal_Rpi5CarSpiLinux.h`.

Core headers are in
core/include
and backend headers in
hardware/include.

| Constant (common library) | Value |
|---|---|
| `XHAL_RPI5CAR_SPI_DEFAULT_DEVICE` | `/dev/spidev0.0` |
| `XHAL_RPI5CAR_SPI_DEFAULT_SPEED_HZ` | `500000` Hertz |
| `XHAL_RPI5CAR_SPI_DEFAULT_MODE` | `0` (maximum `3`) |
| `XHAL_RPI5CAR_SPI_DEFAULT_BITS_PER_WORD` | `8` (maximum `32`) |
| `XHAL_RPI5CAR_SPI_MAXIMUM_TRANSFER_BYTES` | `256` |

The target alias `xWalk::Spi` refers to `xWalkSpi`.

## 6. Build

Run from the repository root. Any option that builds the Linux backend or tests fails configuration on
non-Linux systems.

| CMake option | Default | Purpose |
|---|---:|---|
| `XWALK_SPI_BUILD_HOST_TESTS` | `OFF` | Build the Linux backend and the device-free host tests |
| `XWALK_SPI_BUILD_HARDWARE_TESTS` | `OFF` | Build the Linux backend and the RPi hardware test |
| `XWALK_SPI_BUILD_LINUX_BACKEND` | `OFF` | Build `xWalkSpiLinux` without tests (forced on by the simulation) |
| `XWALK_SPI_HARDWARE_DEVICE` | `/dev/spidev0.0` | Device path passed to the hardware test |

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi -B xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host -DXWALK_SPI_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host --parallel
```

Raspberry Pi compilation without execution:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi -B xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-rpi -DXWALK_SPI_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-rpi --parallel
```

## 7. Configuration

`XWalkSpiConfiguration` carries `speedHz`, `mode` and `bitsPerWord`, defaulting to the common-library values
above. A null or empty device path, zero speed, a mode above `3` or a word width outside 1 through 32 is
rejected before the device is opened. Select the hardware-test device with `XWALK_SPI_HARDWARE_DEVICE`.

## 8. Testing

Host verification uses the production Linux backend with the device-free host mirror:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-host -L host --output-on-failure
```

The suite (`xWalkSpiHostTest`, label `host`) verifies configuration, transmit and receive bytes, payload
bounds, callback and response-length validation and trace-option parsing; see
[xWalkSpi Tests](test/xWalkSpi%20Tests.md).

The hardware test `xWalkSpiLinuxHardwareTransferTest` (label `hardware`) transmits one zero byte on the
configured device. List it without running it:

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/build-rpi -N -L hardware
```

## 9. Dependencies

- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md) - shared types and SPI
  constants.
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) - trace service and inventory.
- GoogleTest and Python 3 for host tests; Linux `spidev` headers for the backend.

## 10. Safety and constraints

Do not execute the hardware test or the hardware simulation until the selected `/dev/spidev*` node, chip
select, peripheral protocol, wiring, voltage and power state have been reviewed and approved, and the
correct Raspberry Pi and Robot HAT setup is confirmed connected and safe.

## 11. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkSpiTransfer](../../../xWalkDriver/xWalkConnectivity/xWalkSpiTransfer/xWalkSpiTransfer.md)

---

[Previous page](../xWalkLanguageModel/simulation/xWalkLanguageModel%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkSpi%20Simulation.md)
