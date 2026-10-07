<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Controller execution architecture

**8. xWalk guides &middot; Module 27**

<!-- xwalk-page-header:end -->

# Controller execution architecture

The previous Controller command-line and handler architecture has been removed. The component currently retains
configuration only.

A replacement CBB-style execution architecture is intentionally not specified by the retired implementation. Its
design must define ownership, bounded dispatch, payload lifetime, error propagation, concurrency, and Raspberry Pi
shutdown safety before new Controller C++ code is introduced.

The retained component state is owned by `xWalk-rpi5-hw/xWalkController`.

---

[Previous page](Controller%20Command%20Flow.md) · [Chapter index](../../index.md) · [Next page](Dependency%20Installer%20Script%20Flags.md)
