# C++ API reference

The public C++ headers are authoritative. This index groups the xWalk HAL
modules by responsibility.

| Responsibility | Module documentation |
|---|---|
| Common types and free functions | [xWalk common library](../../../../xWalk-rpi5-hw/xWalkLibrary/common/README.md) |
| I2C | [xWalkI2c](../../../../xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/README.md) |
| GPIO | [xWalkGpio](../../../../xWalk-rpi5-hw/xWalkHal/interface/xWalkGpio/README.md) |
| ADC | [xWalkAdc](../../../../xWalk-rpi5-hw/xWalkHal/device/xWalkAdc/README.md) |
| PWM | [xWalkPwm](../../../../xWalk-rpi5-hw/xWalkHal/device/xWalkPwm/README.md) |
| Servo | [xWalkServo](../../../../xWalk-rpi5-hw/xWalkHal/device/xWalkServo/README.md) |
| Motors | [xWalkMotor](../../../../xWalk-rpi5-hw/xWalkHal/sensor/xWalkMotor/README.md) |
| Sensors | [Sensors and actuators](API%20Modules.md) |
| Robot coordination | [xWalkRobot](../../../../xWalk-rpi5-hw/xWalkHal/layer1/xWalkRobot/README.md) |
| Board services | [xWalkBoardControl](../../../../xWalk-rpi5-hw/xWalkHal/layer1/xWalkBoardControl/README.md) |
| Configuration | [xWalkConfig](../../../../xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/README.md) |
| Audio and speech | [Music](API%20Music.md) and [speech](API%20TTS.md) |
| Diagnostics and utilities | [Trace](API%20Basic%20Class.md) and [utilities](API%20Utils.md) |

Create platform backends and component objects in `main()`. Pass dependencies
by reference; consuming classes retain documented non-owning pointers.
