<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Sensors and actuators

**8. xWalk guides &middot; Module 51**

<!-- xwalk-page-header:end -->

# Sensors and actuators

## 1. `XWalkUltrasonic`

Uses caller-created trigger and echo `XWalkGpio` objects. Successful results are
in centimetres; documented negative values distinguish timeout and invalid
pulse measurements. See `xWalkUltrasonic`.

## 2. `XWalkAdxl345`

Uses a caller-created `XWalkI2c` object to acquire raw and converted acceleration
data. See `xWalkAdxl345`.

## 3. `XWalkLed` and `XWalkRgbLed`

`XWalkLed` controls one GPIO LED. `XWalkRgbLed` coordinates three non-owning PWM
pointers. See `xWalkLed`.

## 4. `XWalkBuzzer`

Supports active GPIO and passive PWM operation without owning either dependency.
See `xWalkBuzzer`.

## 5. `XWalkGrayscaleModule` and `XWalkLineTracker`

The grayscale component calibrates three ADC channels. The line tracker derives
channel status and normalized line position. See
`xWalkLineTracker`.

## 6. `XWalkUserButton`

Interprets active-low button events and bounded press timing through a
caller-created GPIO dependency. See
`xWalkUserButton`.

---

[Previous page](FAQ.md) · [Chapter index](../../index.md) · [Next page](Index.md)
