<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Configure I2S for the speaker

**8. xWalk guides &middot; Module 24**

<!-- xwalk-page-header:end -->

# Configure I2S for the speaker

I2S and ALSA configuration belongs to target deployment, not to xWalk HAL
production code. Configure the operating-system audio overlay and routing using
the deployment procedure approved for the target image.

## 1. Installation-screen image

TODO: Add a C++ target-deployment screenshot showing I2S configuration.

## 2. Verification-screen image

TODO: Add a C++ target-deployment screenshot showing audio-device verification.

## 3. Restart-screen image

TODO: Add a C++ target-deployment screenshot showing the approved restart step.

The application creates the audio backend, enables speaker power through
`XWalkBoardControl`, and injects playback or speech callbacks. HAL components do
not run privileged commands, change system files, or install packages.

---

[Previous page](Community%20Tutorials.md) · [Chapter index](../../index.md) · [Next page](Project%20Control%20Motor%20Servo.md)
