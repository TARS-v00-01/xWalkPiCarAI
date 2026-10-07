<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / Fuzz Testing Tool

**6. xWalk tool &middot; Module 04**

<!-- xwalk-page-header:end -->

# Fuzz Testing Tool

The fuzz testing tool builds nine Clang/libFuzzer targets that exercise production JSON-C, generated
Protobuf, bounded HTTP, camera-source, and OpenCV decode entry points of the xWalk host build.

## 1. Overview

All targets compile the single harness
`xWalk_Rpi5CarFuzzHarness.cpp`.
CMake gives each target a distinct `XWALK_FUZZ_KIND` compile definition that selects one entry point inside
`LLVMFuzzerTestOneInput`. Every harness rejects oversized input before parsing:

| Target | Entry point | Input bound |
| --- | --- | --- |
| `xWalkFuzz_configuration` | Strict JSON-C parse | 64 KiB, depth 32 |
| `xWalkFuzz_protobuf` | `xwalk::iw::v1::I2cReq` Protobuf parse | 64 KiB |
| `xWalkFuzz_protobuf_requests` | `xwalk::iw::v1::MoveReq` Protobuf parse | 64 KiB |
| `xWalkFuzz_http_requests` | `xwalk::agent::parseMjpegHttpRequest` | 8 KiB header limit |
| `xWalkFuzz_camera_sources` | `xwalk::hal::validCameraSourceString` | 1 MiB global limit |
| `xWalkFuzz_model_metadata` | Strict JSON-C parse with a `classes` array | 64 KiB, depth 32 |
| `xWalkFuzz_scenarios` | Strict JSON-C parse with an `events` array | 64 KiB, depth 32 |
| `xWalkFuzz_i2c_payloads` | `xwalk::iw::v1::I2cReq` Protobuf parse | 4 KiB |
| `xWalkFuzz_image_decode` | OpenCV `cv::imdecode` | 256 KiB encoded, 1920 by 1080 decoded |

The image target sets `OPENCV_IO_MAX_IMAGE_PIXELS` to 2073600 (1920 by 1080) when it is not already set.

## 2. Source location

`xWalk-rpi5-tool/cpp-tool/fuzz` - source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/cpp-tool/fuzz/
    CMakeLists.txt                     Defines the nine xWalkFuzz_* targets and the xWalkFuzzers target
    src/
        xWalk_Rpi5CarFuzzHarness.cpp   Shared libFuzzer harness selected by XWALK_FUZZ_KIND
    corpus/
        configuration/                 valid.json seed
        protobuf/                      minimal.bin seed
        protobuf_requests/             minimal.bin seed
        http_requests/                 health.http seed
        camera_sources/                usb.txt seed
        model_metadata/                valid.json seed
        scenarios/                     minimal.json seed
        i2c_payloads/                  minimal.bin seed
        image_decode/                  malformed.jpg seed
```

## 4. Build

The directory is added by `xWalk-rpi5-hw/CMakeLists.txt` only when `XWALK_BUILD_FUZZERS` is `ON` (default
`OFF`). `CMakeLists.txt` fails configuration
unless the compiler is Clang. Each target is compiled and linked with
`-fsanitize=fuzzer,address,undefined -fno-omit-frame-pointer`.

Configure and build with:

```bash
CC=clang CXX=clang++ cmake -S xWalk-rpi5-hw -B build-host/fuzz -G Ninja -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=OFF -DXWALK_BUILD_FUZZERS=ON
```

```bash
cmake --build build-host/fuzz --target xWalkFuzzers --parallel
```

The `xWalk-rpi5-hw` `fuzz` configure and build presets select the same settings and the `xWalkFuzzers` target.

## 5. Testing

Run a short smoke pass for one target with:

```bash
build-host/fuzz/xWalk-rpi5-tool/cpp-tool/fuzz/xWalkFuzz_http_requests -runs=1000 xWalk-rpi5-tool/cpp-tool/fuzz/corpus/http_requests
```

For a longer local run, replace `-runs=1000` with `-max_total_time=3600`. CI runs every target for 1000 runs
against its corpus through `run-host-ci-job.sh fuzz-smoke`, with `-artifact_prefix=/tmp/xwalk-fuzz-` and a
10 minute timeout in the host-quality workflow.

A fuzzer crash, timeout, sanitizer finding, or out-of-memory result is a failure. A target that was only
compiled must not be reported as passed.

## 6. Dependencies

- Clang with libFuzzer, AddressSanitizer, and UndefinedBehaviorSanitizer.
- OpenCV 4 (`core`, `imgcodecs`) and JSON-C through pkg-config.
- `xWalkLibraryCommon`, `xWalk::IW`, `xWalkCamera`, and `xWalkVideoStreaming` from the aggregate build.

## 7. Safety and constraints

- Fuzz targets are host-only and never access physical hardware.
- Corpus inputs are data only and must never be executed.
- Keep crash artifacts out of the repository.

## 8. Related notes

- [C++ Quality Tool](../quality/C++%20Quality%20Tool.md)
- Gerrit Shell Tool
- xWalk-rpi5-tool

---

[Previous page](../quality/C%2B%2B%20Quality%20Tool.md) · [Chapter index](../../../index.md) · [Next page](../../py-agent/dev-tool/Developer%20Tool.md)
