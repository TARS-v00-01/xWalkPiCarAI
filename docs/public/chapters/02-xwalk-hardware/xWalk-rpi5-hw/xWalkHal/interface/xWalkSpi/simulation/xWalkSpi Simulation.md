<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkSpi
Simulation

**2. xWalk hardware &middot; Module 82**

<!-- xwalk-page-header:end -->

# xWalkSpi Simulation

The `xWalkSpiSimulation` executable runs the public `XWalkSpi` API and the production Linux backend through a
build-selected device. The default `stub` backend mirrors Linux device operations in memory and demonstrates
a bounded four-byte transfer without opening `/dev/spidev*`.

## 1. Overview

`main()` handles `--help`, parses an optional trace selector, boots the global trace service, constructs the
build-selected `XWalkSpiDevice` through `createSpiDevice()`, wraps it in `XWalkSpiLinux` with the default
configuration and dispatches `XWalkSpiHandler`. The handler transmits `0x9F 0x00 0x00 0x00` and returns
status `0` when the received length matches, otherwise `1`. The stub replies `0x00 0xEF 0x40 0x18`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/simulation` -
source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                  Backend selection, trace catalogue, executable
├── config/xHal_Rpi5CarSpiTraceConfig.py           Validates and merges the persistent trace catalogue
├── include/
│   ├── xHal_Rpi5CarSpiDeviceFactory.h              createSpiDevice() factory declaration
│   ├── xHal_Rpi5CarSpiHandler.h                    Transfer handler
│   ├── xHal_Rpi5CarSpiHostStub.h                   In-memory XWalkSpiDevice mirror
│   ├── xHal_Rpi5CarSpiSimulationArguments.h        --help and --trace parsing
│   └── xHal_Rpi5CarSpiSimulationConfig.h           Default trace, log and device path macros
└── src/
    ├── main.cpp                                    Trace boot, composition and dispatch
    ├── xHal_Rpi5CarSpiDeviceFactoryHardware.cpp    Creates XWalkSpiDeviceLinux
    ├── xHal_Rpi5CarSpiDeviceFactoryStub.cpp        Creates XWalkSpiHostStub
    ├── xHal_Rpi5CarSpiHandler.cpp                  Four-byte transfer sequence
    ├── xHal_Rpi5CarSpiHostStub.cpp                 Mirror implementation (also used by host tests)
    └── xHal_Rpi5CarSpiSimulationArguments.cpp      Argument parser implementation
```

## 4. Build

The project forces `XWALK_SPI_BUILD_LINUX_BACKEND=ON` and adds the parent module. The stub is the safe
default. Run from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/simulation -B xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/simulation/build-host -DXWALK_SPI_SIMULATION_BACKEND=stub -DCMAKE_BUILD_TYPE=Debug
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/simulation/build-host --target xWalkSpiSimulation --parallel
xWalk-rpi5-hw/xWalkHal/interface/xWalkSpi/simulation/build-host/xWalkSpiSimulation --trace RPI.enable
```

## 5. Configuration

| CMake cache value | Default | Purpose |
|---|---|---|
| `XWALK_SPI_SIMULATION_BACKEND` | `stub` | `stub` or `hardware`; any other value fails configuration |
| `XWALK_SPI_SIMULATION_DEVICE` | `/dev/spidev0.0` | Device path compiled into the runner |

The runner accepts no option, `--help` or `-h`, or exactly one `--trace <selector>`. Selectors are
`RPI.enable`/`RPI.disable`, `RPI.<number>.enable`/`RPI.<number>.disable`, `all.enable`/`all.disable` or a
`.json` trace argument file. Invalid syntax and scanner-unknown UIDs return status `2` before the device is
created.

The custom target `xWalkSpiSimulationTraceConfig` generates `generated/xWalkSpiTrace.xml` from the scanner
inventory. New traces start disabled; successful selector changes persist in that XML and load on later
runs. Enabled messages appear in the terminal and in `log/xWalkSpiSimulation.log` inside the build directory.

## 6. Dependencies

- Parent module `xWalkSpiLinux` and `xWalkSpi`, `xWalkTrace` and a Python 3 interpreter.
- Linux only; configuration fails on other systems.

## 7. Safety and constraints

`-DXWALK_SPI_SIMULATION_BACKEND=hardware` compiles the runner with `XWalkSpiDeviceLinux`, which transmits
four bytes on the selected device. Run that binary only after the device node, chip select, peripheral
protocol, wiring, voltage and power state have been reviewed and approved, and the correct Raspberry Pi and
Robot HAT setup is confirmed connected and safe.

## 8. Related notes

- [xWalkSpi](../xWalkSpi.md)
- [xWalkSpi Tests](../test/xWalkSpi%20Tests.md)

---

[Previous page](../xWalkSpi.md) · [Chapter index](../../../../../index.md) · [Next page](../test/xWalkSpi%20Tests.md)
