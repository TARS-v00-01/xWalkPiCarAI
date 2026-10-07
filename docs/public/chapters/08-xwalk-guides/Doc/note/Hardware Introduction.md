<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Hardware introduction

**8. xWalk guides &middot; Module 33**

<!-- xwalk-page-header:end -->

# Hardware introduction

## 1. Robot HAT pinout

![Robot HAT pinout](../image/robot_hat_pinout.png)

## 2. Digital I/O

The board exposes four three-pin digital connectors. `XWalkGpio` provides the
hardware-independent C++ interface. `XWalkGpioLinux` optionally owns Linux GPIO
resources. Named board-pin mappings and polarity are defined by the C++ module.

## 3. Image: Digital connectors

![Digital connectors](../image/digitalio.png)

## 4. ADC

Four external channels provide 12-bit measurements in the range 0 to 4095.
Inputs use a 3.3-volt reference. A4 is reserved for divided battery voltage.
Use `XWalkAdc` for raw samples and voltage conversion.

## 5. Image: ADC connectors

![ADC connectors](../image/adcpin.png)

## 6. Image: Battery ADC divider

![Battery ADC divider](../image/btradc.png)

## 7. PWM

The onboard MCU supplies PWM outputs. Use `XWalkPwmTimerState` to coordinate
timer settings and create one `XWalkPwm` per output. Channels on the same timer
share frequency and period settings.

## 8. Image: PWM connectors

![PWM connectors](../image/pwmpin.png)

## 9. I2C

The board exposes P2.54 and SH1.0 I2C connectors connected to Raspberry Pi
GPIO2 for SDA and GPIO3 for SCL. Use `XWalkI2c` with an application-created
backend. The onboard MCU normally responds at 7-bit address `0x14`.

## 10. Image: I2C connectors

![I2C connectors](../image/i2cpin.png)

## 11. SPI and UART

SPI and UART are Raspberry Pi expansion interfaces. The xWalk HAL provides the
bounded `XWalkSpi` transaction interface and the Linux `XWalkSpiLinux` spidev
backend. UART does not currently have a dedicated HAL class, so applications
must own that backend.

## 12. Image: SPI connector

![SPI connector](../image/spipin.png)

## 13. Image: UART connector

![UART connector](../image/uartpin.png)

## 14. Buttons, LED, and speaker

Use `XWalkUserButton` for active-low press timing and `XWalkLed` for the user
LED. `XWalkBoardControl` controls speaker power; `XWalkSpeaker`, `XWalkMusic`,
and xWalkGPT components coordinate audio facilities. The RPi voice-prompt graph
retains board control and the speaker-enable GPIO until Espeak PCM playback has
completed.

## 15. Motor ports

The board provides two motor channels. `XWalkDevice` selects the supported
motor mode for the detected revision. `XWalkMotor` controls one channel and
`XWalkMotors` validates coordinated commands before changing either output.

---

[Previous page](Features.md) · [Chapter index](../../index.md) · [Next page](Hardware%20Provisioning%20Script%20Guide.md)
