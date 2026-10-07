<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkAdc`

**8. xWalk guides &middot; Module 02**

<!-- xwalk-page-header:end -->

# `XWalkAdc`

`XWalkAdc` acquires raw samples from one MCU ADC channel and converts samples to
volts. The caller creates and retains the referenced `XWalkI2c` object.

## 1. Public interface

The authoritative declaration is
`xHal_Rpi5CarAdc.h`.

- Construct with an I2C reference, channel, and optional device address.
- `read()` returns one raw sample assembled from exactly two bytes.
- `readVoltage()` converts the sample using the 3.3-volt reference and 4095
  maximum count.

Valid channels are 0 through 7. Backend failures and malformed response lengths
are reported through the documented exception contracts.

---

[Previous page](../../index.md) · [Chapter index](../../index.md) · [Next page](API%20Filedb.md)
