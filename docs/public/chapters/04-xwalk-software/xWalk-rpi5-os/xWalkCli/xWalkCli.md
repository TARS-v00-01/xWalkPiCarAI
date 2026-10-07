<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkCli

**4. xWalk software &middot; Module 03**

<!-- xwalk-page-header:end -->

# xWalkCli

`xWalkCli` is the pure C++ local JSON transport for the existing desktop process owner. It lets terminal clients
and the reconnecting HUD reach the GUI or headless owner without starting a second Controller.

## 1. Overview

- Qt `QLocalServer` uses a user-only socket and a distinct endpoint for each compiled profile.
- Requests are limited to 64 KiB, one per connection. Incomplete requests expire after five seconds and command
  responses after forty seconds. A client-side `request` gives up after 45 seconds or a response above 1 MiB.
- The GUI and `--cli serve` expose the same backend operations. Clients never start a second Controller.
- The application's instance lock must be acquired before creating the server or removing its stale socket.
- The handler's backend must outlive the server; replies use a guarded socket pointer so disconnected clients
  cannot leave dangling callbacks. External OS commands are asynchronous and have a 35-second deadline.
- `XWalkRuntimeClient` polls the owner for the attached HUD. Reads reconnect automatically; a command whose reply
  is lost is reported as uncertain and is never replayed.

## 2. Source location

`xWalk-rpi5-os/xWalkCli` - source directory

## 3. Directory layout

```text
xWalkCli/
    CMakeLists.txt                     Static library xWalkOsCli and its Google Test
    include/XWalkCli.h                 Same-user socket server, endpoint and one-shot request
    include/XWalkRuntimeClient.h       Polling client used by the attached HUD
    src/XWalkCli.cpp                   Bounded request/response handling
    src/XWalkRuntimeClient.cpp         State polling and single-send command exchange
    test/src/xWalkCliGoogleTest.cpp    Malformed-request and reconnection tests
```

## 4. Public interface

Namespace `xwalk::hal`:

- `XWalkCli`: `endpoint()` derives the per-user,
  per-build-mode socket path; `listen(handler, error)` starts serving after the instance lock is held;
  `request(command)` exchanges one bounded request with an existing owner. `Handler` receives validated JSON and
  a `Reply` that delivers exactly one response.
- `XWalkRuntimeClient`: `start()`,
  `connected()`, `snapshot()` and `send(request, reply)`; emits `changed()`. Its destructor cancels callbacks
  before socket teardown.

See the [CLI guide](../CLI_GUIDE.md) for commands, profile differences and result semantics.

## 5. Build

CMake target `xWalkOsCli` (static, C++17) links `Qt5::Network`, `xWalkOsBuild` and `xWalkOsTrace`. Build through
the [desktop root](../xWalk-rpi5-os.md).

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkCli --output-on-failure
```

`xWalkCliGoogleTest` covers rejection of malformed requests with the handler preserved, and attachment
reconnection that reads state without replaying a lost command. No hardware is used.

## 7. Dependencies

Qt 5 Network, `xWalkOsBuild` (generated build mode) and `xWalkOsTrace`.

## 8. Safety and constraints

- The socket is same-user only; there is no network listener.
- One process owner per profile; the instance lock is acquired before the server starts.

## 9. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkMain](../xWalkMain/xWalkMain.md)
- [CLI guide](../CLI_GUIDE.md)

---

[Previous page](../ci/xWalk-rpi5-os%20CI.md) · [Chapter index](../../index.md) · [Next page](../xWalkConfig/xWalkConfig.md)
