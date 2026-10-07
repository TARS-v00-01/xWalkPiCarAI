<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkGpio`

**8. xWalk guides &middot; Module 04**

<!-- xwalk-page-header:end -->

# `XWalkGpio`

`XWalkGpio` provides digital mode, pull, polarity, value, and edge operations.
`XWalkGpioLinux` is the optional Linux resource-owning backend.

## 1. Public interface

See `xWalkGpio`,
GPIO header, and the
Linux backend header when building for Raspberry Pi.

The application owns callback context lifetime. Keep interrupt callbacks short,
non-blocking, and free from filesystem, network, speech, or playback operations.

---

[Previous page](API%20Filedb.md) · [Chapter index](../../index.md) · [Next page](API%20I2C.md)
