<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkMotor` and `XWalkMotors`

**8. xWalk guides &middot; Module 06**

<!-- xwalk-page-header:end -->

# `XWalkMotor` and `XWalkMotors`

`XWalkMotor` controls one motor using the PWM and direction dependencies selected
for the board mode. `XWalkMotors` coordinates two non-owning motor pointers.

## 1. Public interface

See `xWalkMotor` and its two public class headers.

Speed commands use the documented range from -100 to 100 percent. Validate
coordinated commands before changing either motor. Apply zero output before
destroying dependencies or changing hardware configuration.

---

[Previous page](API%20I2C.md) · [Chapter index](../../index.md) · [Next page](API%20Music.md)
