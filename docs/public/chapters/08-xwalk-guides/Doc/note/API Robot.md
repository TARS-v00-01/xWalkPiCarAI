<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkRobot`

**8. xWalk guides &middot; Module 09**

<!-- xwalk-page-header:end -->

# `XWalkRobot`

`XWalkRobot` coordinates caller-created servo objects, named positions, and
multi-servo action frames. Persistent configuration remains in `XWalkConfig`.

## 1. Public interface

See `xWalkRobot` and
`xHal_Rpi5CarRobot.h`.

Create servo objects in `main()` and pass validated non-owning pointers through
the robot configuration. Keep every servo and its PWM dependency alive longer
than the robot object.

---

[Previous page](API%20PWM.md) · [Chapter index](../../index.md) · [Next page](API%20Servo.md)
