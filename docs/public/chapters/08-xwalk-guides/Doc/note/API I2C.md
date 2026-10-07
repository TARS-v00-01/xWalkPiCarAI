<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkI2c`

**8. xWalk guides &middot; Module 05**

<!-- xwalk-page-header:end -->

# `XWalkI2c`

`XWalkI2c` is the hardware-independent callback-driven bus abstraction.
`XWalkI2cLinux` optionally owns a Linux I2C file descriptor.

## 1. Public interface

See `xWalkI2c` and the public headers under
its `core`
and `hardware` include directories.

Create the backend before `XWalkI2c`, pass its pointer and callback bridges to
the constructor, and keep it alive until all dependent ADC, PWM, firmware, and
sensor objects are destroyed. Serialize transactions that share a bus.

---

[Previous page](API%20Pin.md) · [Chapter index](../../index.md) · [Next page](API%20Motor.md)
