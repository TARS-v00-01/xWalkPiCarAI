<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [7. xWalk trace](../../index.md) / OS desktop traces

**7. xWalk trace &middot; Module 02**

<!-- xwalk-page-header:end -->

# OS desktop traces

The OS desktop owns `OS.001`–`OS.012`, independently of HAL, Node and Traffic IDs.
Host/Pi use the shared trace scanner, catalogue, selectors and file sink. Warnings and errors are
unfiltered; normal information is disabled until selected. GUI errors remain separate from trace logs.

```bash
./build-host/xwalk-pi5car --gui --trace OS.enable
./build-standalone/xwalk-pi5car --cli serve --trace OS.enable
```

Logs append to `<build>/log/xWalkTrace.log`; CLI JSON stdout remains unchanged.
The Qt adapter is owned by this trace repository and enabled only for desktop consumers.
Standalone needs no dependency repository; its testing stub lives in the OS `xWalkStub` module: its file-only Qt
backend supports `all`, `OS` and exact
`OS.001`–`OS.012` enable/disable selectors, persisting state in `<build>/log/os-trace-state.json`.
Host/Pi retain the shared XML and JSON-selector contract. Selectors apply to the current process;
restart an existing GUI/CLI owner to load a selection changed by another process.
Trace messages never contain Wi-Fi credentials, SSIDs, config values, video paths, images or protocol payloads.

| UID | Information event |
| --- | --- |
| OS.001 | Session startup requested |
| OS.002 | Desktop initialization completed |
| OS.003 | Headless session ready |
| OS.004 | Owned process launch requested |
| OS.005 | Owned process stop requested |
| OS.006 | Configuration loaded |
| OS.007 | Configuration saved with backup |
| OS.008 | Wi-Fi scan requested |
| OS.009 | Wi-Fi connection requested |
| OS.010 | Local CLI endpoint listening |
| OS.011 | Automatic telemetry polling started |
| OS.012 | Settings menu opened |

Errors report failed process startup/exits, forced shutdown, configuration I/O, local-socket startup,
missing telemetry launchers, external OS commands and screenshot output failures. Expected rejected commands,
concurrent configuration edits, network connection failures, malformed CLI input, lost camera frames and
telemetry failures are warnings. Telemetry warnings are emitted on failure transitions, not every poll.
No callback copies raw child output into the trace file. Error macros use the shared non-throwing
`XWALK_EXCEPTION` selector because Qt event handlers must retain the existing UI recovery behavior.

---

[Previous page](../xWalk-rpi5-trace.md) · [Chapter index](../../index.md) · [Next page](../../../08-xwalk-guides/index.md)
