<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkSpiTransfer

**2. xWalk hardware &middot; Module 14**

<!-- xwalk-page-header:end -->

# xWalkSpiTransfer

`xWalkSpiTransfer` is a small hardware-independent Agent coordinator for one caller-owned `XWalkSpi`. It
forwards bounded full-duplex requests and owns no device node, chip select, configuration, or Linux
descriptor.

## 1. Overview

Each transfer is delegated to the HAL `XWalkSpi::transfer()` contract, which requires a non-empty payload of
at most 256 bytes and returns exactly as many received bytes. Validation errors from the HAL propagate to the
caller unchanged.

The application creates the Linux backend first, then `XWalkSpi`, and finally the Agent. Destruction occurs
in reverse order.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkSpiTransfer`
(source directory)

## 3. Directory layout

```text
xWalkSpiTransfer/
    CMakeLists.txt                              Library, alias, and host test registration
    include/xAgent_Rpi5CarSpiTransfer.h         Public coordinator contract
    src/xAgent_Rpi5CarSpiTransfer.cpp           Transfer forwarding and trace
    test/
        include/                                Test-local types
        src/xAgent_Rpi5CarSpiTransferTest.cpp   Device-free host test
```

## 4. Public interface

`xwalk::agent::XWalkSpiTransfer` (non-copyable, non-movable) stores a non-owning pointer to the
`hal::XWalkSpi&` passed to its `noexcept` constructor.

| Member | Behavior |
| --- | --- |
| `transfer(transmitData)` | Executes one full-duplex transaction and returns the received bytes |

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_SPI_TRANSFER_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |

The module builds `xWalkSpiTransfer` (alias `xWalk::SpiTransfer`) and adds the `xWalkSpi` HAL interface when the
target is not already defined.

## 6. Testing

`xWalkSpiTransferHostTest` (label `host`) verifies forwarding without a device. Standalone host verification
from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkSpiTransfer -B xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkSpiTransfer/build-host -DXWALK_SPI_TRANSFER_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkSpiTransfer/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/xWalkConnectivity/xWalkSpiTransfer/build-host --output-on-failure
```

Physical SPI tests belong to the `xWalkSpi` HAL and are opt-in; discover them with `ctest -N -L hardware`.

## 7. Dependencies

- [xWalkSpi](../../../xWalkHal/interface/xWalkSpi/xWalkSpi.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

The caller must keep the `XWalkSpi` object alive for the lifetime of the Agent. The module emits
`RPIAGENT.017` with transmitted and received byte counts only, never payload contents; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkConnectivity](../xWalkConnectivity.md)

---

[Previous page](../xWalkAppControl/xWalkAppControl.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkMedia/xWalkMedia.md)
