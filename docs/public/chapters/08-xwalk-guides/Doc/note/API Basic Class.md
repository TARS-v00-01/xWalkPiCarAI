<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkTrace`

**8. xWalk guides &middot; Module 11**

<!-- xwalk-page-header:end -->

# `XWalkTrace`

`XWalkTrace` provides filtered diagnostic output through an append-only log file
and an injected callback. It replaces implicit console logging with explicit,
testable sinks.

## 1. Public interface

The authoritative declarations are in the public headers under `xWalk-rpi5-trace/include`.

The application configures the active severity and supplies the callback
context. The trace object appends accepted records to
`<build-directory>/log/xWalkTrace.log`, independent of the process working
directory, and does not own the additional callback destination.

---

[Previous page](API%20Servo.md) · [Chapter index](../../index.md) · [Next page](Battery.md)
