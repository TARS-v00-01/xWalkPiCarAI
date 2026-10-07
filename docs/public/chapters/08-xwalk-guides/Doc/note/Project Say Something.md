<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Produce speech

**8. xWalk guides &middot; Module 43**

<!-- xwalk-page-header:end -->

# Produce speech

Create the platform synthesis backend, `XWalkBoardControl`, and
`XWalkTextToSpeech` in `main()`. Enable speaker power only after target audio
configuration is valid, then pass bounded text to the injected synthesis
callback.

The application owns model selection, process or network access, credentials,
audio files, and cleanup. The HAL does not invoke external tools implicitly.

---

[Previous page](PiCar-X%20Controller%20Command%20Reference.md) · [Chapter index](../../index.md) · [Next page](Deployment%20Guide.md)
