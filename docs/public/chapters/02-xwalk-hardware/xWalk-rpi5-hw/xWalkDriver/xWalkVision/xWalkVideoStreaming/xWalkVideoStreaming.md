<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkVideoStreaming

**2. xWalk hardware &middot; Module 34**

<!-- xwalk-page-header:end -->

# xWalkVideoStreaming

`xWalkVideoStreaming` provides the deterministic bounded core and pump-driven non-blocking HTTP transport for
MJPEG streaming, plus an Agent that connects a HAL camera stream to that transport.

## 1. Overview

The module has three layers:

- **Stream core** (`xAgent_Rpi5CarMjpegStream.h`). It validates loopback-only defaults, frames JPEG data as HTTP
  multipart records, assigns monotonic sequence numbers starting at one, and maintains a bounded independent
  queue for each logical client. A slow client drops its oldest frame without blocking capture, inference, motor
  control, or another client. A mutex serializes every public stream operation.
- **HTTP transport** (`xAgent_Rpi5CarMjpegHttpServer.h`). `XWalkMjpegHttpServer` opens a non-blocking IPv4
  listener but starts no worker thread. The owner calls `pumpMjpegHttpServer()` from a non-safety event loop.
  The server exposes only `GET /stream`, `GET /health`, and `GET /status`; it has no actuator endpoint. Request
  bytes, clients, pending output, timeouts, and per-client frame queues are bounded. Queue saturation drops the
  oldest frame for that client. Header, idle, and slow-client deadlines use caller-provided monotonic time.
- **Agent** (`xAgent_Rpi5CarVideoStreaming.h`). `XWalkVideoStreaming` connects a caller-owned HAL
  `XWalkCameraStream`, or an equivalent callback table, to the transport. Each `step()` captures one JPEG,
  publishes it, and pumps the HTTP server once.

Raspberry Pi composition supplies the HAL `XWalkCameraStreamOpenCv` backend. The Controller video session
(`xControllerVideoSession.cpp`)
runs a background worker that calls `step()` with a 20-millisecond
pause until a stop is requested or a step fails, then stops the stream. The camera-only cancellation path does
not require a PiCar-X emergency-stop target.

The deployed CSI profile selects `libcamera` with source `csi`. The HAL builds a fixed `libcamerasrc` GStreamer
pipeline with NV12 source caps and validated dimensions, then passes it directly to OpenCV; configuration cannot
inject pipeline text. A USB camera can instead select `v4l2` with an exact `/dev/videoN` source.

Camera loss clears every pending frame, rejects later publication, and prevents stale imagery from being
replayed. Shutdown and repeated start/stop operations are deterministic and idempotent. Camera startup,
first-frame, and HTTP startup failures close every resource retained up to that point and emit trace errors.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/xWalkVideoStreaming` (source
directory,
CMakeLists.txt)

## 3. Directory layout

```text
xWalkVideoStreaming/
    CMakeLists.txt                                      Library, dependency wiring, and host test
    include/
        xAgent_Rpi5CarMjpegStream.h                     Bounded stream core and multipart framing
        xAgent_Rpi5CarMjpegHttpServer.h                 Non-blocking IPv4 HTTP transport
        xAgent_Rpi5CarVideoStreaming.h                  Camera-to-transport Agent
    src/
        xAgent_Rpi5CarMjpegStream.cpp                   Stream core implementation
        xAgent_Rpi5CarMjpegHttpServer.cpp               Request parsing, endpoints, timeouts, and sockets
        xAgent_Rpi5CarVideoStreaming.cpp                Agent lifecycle and capture-publish-pump step
    test/
        include/xAgent_Rpi5CarMjpegStreamTestSupport.h  Shared test fixtures and helpers
        src/xAgent_Rpi5CarMjpegStreamTestSupport.cpp    Test support implementation
        src/xAgent_Rpi5CarMjpegStreamTest.cpp           Stream core and Agent tests
        src/xAgent_Rpi5CarMjpegHttpServerTest.cpp       Loopback socket tests
```

## 4. Public interface

Public headers are in the module
`include` directory.

| Function or member | Purpose |
| --- | --- |
| `validateMjpegStreamConfiguration`, `startMjpegStream`, `stopMjpegStream` | Stream core lifecycle |
| `addMjpegStreamClient`, `removeMjpegStreamClient` | Logical client registration |
| `publishMjpegFrame`, `popMjpegMultipartFrame` | Frame publication and per-client retrieval |
| `reportMjpegCameraLoss`, `mjpegHttpResponseHeader` | Camera-loss handling and stream response header |
| `validateMjpegHttpConfiguration`, `parseMjpegHttpRequest` | HTTP configuration and request validation |
| `startMjpegHttpServer`, `pumpMjpegHttpServer`, `stopMjpegHttpServer` | Transport lifecycle and event pump |
| `mjpegHttpServerPort` | Bound listener port |
| `XWalkVideoStreaming::start`, `step`, `stop`, `port`, `started` | Agent lifecycle |

Free functions are `noexcept` and report outcomes through `XWalkMjpegStreamStatus`, `XWalkMjpegHttpStatus`, or
`XWalkMjpegHttpParseStatus`. The stream state and HTTP server structures are caller-owned; the HTTP server keeps
a non-owning pointer to the stream state, which must outlive it. `XWalkVideoStreaming` owns its stream state and
server, but not the camera stream or callback context.

## 5. Build

The CMake project defines the static library `xWalkVideoStreaming` with alias `xWalk::VideoStreaming` (C++17).
It links `xWalkLibraryCommon` and `xWalkCamera` publicly and `xWalkTrace` privately, adding them as
subdirectories when built standalone. GNU and Clang builds use
`-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`.

| CMake option | Default | Purpose |
| --- | --- | --- |
| `XWALK_VIDEO_STREAMING_BUILD_HOST_TESTS` | `OFF` | Build the deterministic in-process and loopback tests |

In the workspace build, `xWalkDriver` sets this option from `XWALK_AGENT_BUILD_HOST`.

## 6. Configuration

`XWalkMjpegStreamConfiguration`:

| Field | Default | Valid range |
| --- | --- | --- |
| `bindAddress` | `127.0.0.1` | valid address; non-loopback requires `allowExternalBind` |
| `port` | 8080 | 1 to 65535 |
| `maximumClients` | 4 | 1 to 32 |
| `queueCapacity` | 2 | 1 to 16 frames per client |
| `maximumJpegBytes` | 2 MiB | 4 bytes to 10 MiB |
| `allowExternalBind` | `false` | explicit opt-in for non-loopback binding |

`XWalkMjpegHttpConfiguration` adds:

| Field | Default | Valid range |
| --- | --- | --- |
| `maximumRequestBytes` | 8 KiB | 64 bytes to 64 KiB |
| `maximumPendingBytes` | 4 MiB | 1 KiB to 16 MiB per client |
| `headerTimeoutMilliseconds` | 2000 | 1 to 300000 milliseconds |
| `idleTimeoutMilliseconds` | 15000 | 1 to 300000 milliseconds |
| `slowClientTimeoutMilliseconds` | 5000 | 1 to 300000 milliseconds |
| `authenticationReference`, `authenticate` | empty, null | both required for a non-loopback bind |
| `observability` | null | optional non-owning network-path event sink |

The default bind is `127.0.0.1`. A non-loopback bind requires explicit `allowExternalBind`, a non-empty
secret-store reference, and a caller-provided bearer-token authentication callback. The reference is not a
credential and the token is neither retained nor included in `/status`. No default credential exists. IPv6
transport is not implemented; `::1` remains accepted by the transport-independent queue configuration but is
rejected by the IPv4 HTTP transport configuration.

## 7. Testing

`xWalkVideoStreamingHostTest` has labels `host`, `vision`, `streaming`, `backpressure`, and `fault-injection`.
Host tests publish concurrently from two threads and verify that sequence order and the configured queue bound
hold. Socket tests bind only to loopback and cover endpoint responses, multipart boundaries, request limits,
timeouts, client limits, port collision, camera loss, connected-client shutdown, and repeated stop. Raspberry Pi
networking and external-interface security remain unverified.

Build and run the host test from the repository root:

```bash
cmake -S xWalk-rpi5-hw --preset host-debug
```

```bash
cmake --build build-host/cmake --target xWalkVideoStreamingTest
```

```bash
ctest --test-dir build-host/cmake -R xWalkVideoStreamingHostTest --output-on-failure
```

The vision group test `xWalkDriverVisionGroupHostTest` depends on this test target. The module defines no
hardware test; list workspace hardware tests with `ctest -N -L hardware` and run them only with explicit
approval and a confirmed safe Raspberry Pi and Robot HAT setup.

Loopback smoke examples after embedding and starting the server are:

```bash
curl --fail http://127.0.0.1:8080/health
```

```bash
ffplay http://127.0.0.1:8080/stream
```

Open `http://127.0.0.1:8080/stream` on the Pi desktop. Forward the same loopback-only stream to an SSH client
with:

```bash
ssh -L 8080:127.0.0.1:8080 <pi-user>@<pi-address>
```

## 8. Dependencies

- `xWalkCamera` for `hal::XWalkCameraStream` and the OpenCV camera backend;
- `xWalkLibraryCommon` for shared types and failure observability;
- `xWalkTrace` for trace and error reporting;
- GoogleTest for the host test.

## 9. Safety and constraints

- The transport has no actuator endpoint and must be pumped only from a non-safety event loop.
- Keep the default loopback bind; external binding requires explicit opt-in and authentication and is not
  verified on Raspberry Pi.
- Camera imagery may be private; prefer SSH forwarding over external binding.

## 10. Related notes

- [xWalkVision](../xWalkVision.md)
- [xWalkCamera](../../../xWalkHal/device/xWalkCamera/xWalkCamera.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkVideoRecording/xWalkVideoRecording.md) · [Chapter index](../../../../index.md) · [Next page](../test/assets/xWalkVision%20Test%20Assets.md)
