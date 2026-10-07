<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkMusic`

**8. xWalk guides &middot; Module 07**

<!-- xwalk-page-header:end -->

# `XWalkMusic`

`XWalkMusic` provides music-theory conversion, PCM tone generation, and injected
audio operations. It does not own an ALSA device or launch a platform process.

## 1. Public interface

See `xWalkMusic` and
`xHal_Rpi5CarMusic.h`.

The application supplies audio callbacks and keeps callback contexts valid for
the complete object lifetime. Validate note names, tempo, duration, volume, and
sample properties using the ranges documented in the header.

---

[Previous page](API%20Motor.md) · [Chapter index](../../index.md) · [Next page](API%20PWM.md)
