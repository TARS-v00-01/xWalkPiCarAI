<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkPwm` and `XWalkPwmTimerState`

**8. xWalk guides &middot; Module 08**

<!-- xwalk-page-header:end -->

# `XWalkPwm` and `XWalkPwmTimerState`

`XWalkPwm` controls one MCU PWM channel. `XWalkPwmTimerState` coordinates the
frequency and period shared by channels assigned to one hardware timer.

## 1. Public interface

See `xWalkPwm`,
`xHal_Rpi5CarPwm.h`, and
timer-state header.

Create one timer-state object before all PWM channels that use it. A frequency
change that conflicts with an active sibling channel is rejected. Pulse values
must remain within the configured period.

---

[Previous page](API%20Music.md) · [Chapter index](../../index.md) · [Next page](API%20Robot.md)
