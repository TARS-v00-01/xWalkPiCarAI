<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / C++ plant monitor

**8. xWalk guides &middot; Module 16**

<!-- xwalk-page-header:end -->

# C++ plant monitor

Use separate `XWalkAdc` objects for light and moisture, `XWalkUserButton` for
the user action, and `XWalkGpio` or a suitable motor driver for pump control.

## 1. Image: Plant-monitor arrangement

![Plant-monitor project](../image/plant_monitor.jpg)

The application must define valid sensor ranges, maximum pump-on time, minimum
pump-off time, display behavior, and a shutdown path that always disables the
pump. Do not perform blocking application work in a button interrupt callback.

---

[Previous page](Project%20DIY%20Car.md) · [Chapter index](../../index.md) · [Next page](Projects.md)
