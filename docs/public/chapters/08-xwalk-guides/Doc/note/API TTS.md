<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / C++ speech interfaces

**8. xWalk guides &middot; Module 19**

<!-- xwalk-page-header:end -->

# C++ speech interfaces

`XWalkTextToSpeech` coordinates text synthesis through an injected backend.
`XWalkSpeechToText` coordinates recognition through an injected backend. Both
classes belong to `xWalkGPT`.

The C++ core owns no model, microphone, audio device, network client, process,
credential, or generated media file. The application supplies and owns those
facilities and keeps callback contexts valid for the object lifetime.

The Linux hardware layer supplies two offline providers. `XWalkSpeechRecognizerVosk`
loads `libvosk.so` and one configured model at runtime, while
`XWalkTextToSpeechEspeak` executes Espeak without a shell and converts its WAV
output to signed sixteen-bit PCM. ALSA adapters perform microphone capture and
shared speaker playback. Historically, the deleted `xWalkBootRpi` composition
retained Robot HAT speaker power for the complete synthesis and playback
lifetime. No current runtime composition root replaces that ownership.

---

[Previous page](Project%20Security.md) · [Chapter index](../../index.md) · [Next page](API%20Utils.md)
