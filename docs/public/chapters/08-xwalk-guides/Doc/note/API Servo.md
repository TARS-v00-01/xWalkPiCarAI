<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkServo`

**8. xWalk guides &middot; Module 10**

<!-- xwalk-page-header:end -->

# `XWalkServo`

`XWalkServo` translates angle and pulse-duration commands into a caller-created
`XWalkPwm` output.

## 1. Public interface

See `xWalkServo` and
`xHal_Rpi5CarServo.h`.

The default configuration uses 50 hertz, a 4095-count period, angles from -90
to 90 degrees, and pulse widths from 500 to 2500 microseconds. Confirm the
mechanical range before commanding an attached servo.

---

[Previous page](API%20Robot.md) · [Chapter index](../../index.md) · [Next page](API%20Basic%20Class.md)
