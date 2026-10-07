<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / C++ API reference

**8. xWalk guides &middot; Module 14**

<!-- xwalk-page-header:end -->

# C++ API reference

The public C++ headers are authoritative. This index groups the xWalk HAL
modules by responsibility.

| Responsibility | Module |
|---|---|
| Common types and free functions | `xWalk common library` |
| I2C | `xWalkI2c` |
| GPIO | `xWalkGpio` |
| ADC | `xWalkAdc` |
| PWM | `xWalkPwm` |
| Servo | `xWalkServo` |
| Motors | `xWalkMotor` |
| Sensors | [Sensors and actuators](API%20Modules.md) |
| Robot coordination | `xWalkRobot` |
| Board services | `xWalkBoardControl` |
| Configuration | `xWalkConfig` |
| Audio and speech | [Music](API%20Music.md) and [speech](API%20TTS.md) |
| Diagnostics and utilities | [Trace](API%20Basic%20Class.md) and [utilities](API%20Utils.md) |

Create platform backends and component objects in `main()`. Pass dependencies
by reference; consuming classes retain documented non-owning pointers.

---

[Previous page](Installation.md) · [Chapter index](../../index.md) · [Next page](Project%20DIY%20Car.md)
