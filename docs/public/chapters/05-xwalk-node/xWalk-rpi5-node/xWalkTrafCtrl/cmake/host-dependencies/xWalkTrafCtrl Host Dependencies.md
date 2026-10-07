<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkTrafCtrl Host
Dependencies

**5. xWalk node &middot; Module 31**

<!-- xwalk-page-header:end -->

# xWalkTrafCtrl Host Dependencies

This standalone CMake project builds the pinned native OpenCV 4.12.0 dependency used by `xWalkTrafCtrl` into an
isolated prefix inside the module, without replacing the system OpenCV installation.

## 1. Overview

The exported trained YOLO graph fails to import in OpenCV 4.6 even when synthetic tensor tests pass. Non-Hailo
`xWalkTrafCtrl` builds therefore require OpenCV 4.10 or newer, and the deployment model is verified with 4.12.0.
Python's `opencv-python` package does not provide the C++ dependency used by the executable. This project
(`xWalkTrafficHostDependencies`) fetches and builds that dependency with `ExternalProject_Add`. The same recipe
also applies to Raspberry Pi CPU builds.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/cmake/host-dependencies` -
source directory

## 3. Directory layout

```text
cmake/host-dependencies/
    CMakeLists.txt    ExternalProject recipe for the pinned OpenCV 4.12.0 source archive
```

## 4. Build

Run from `xWalk-rpi5-node/xWalkTrafCtrl`:

```bash
cmake -S cmake/host-dependencies -B build-dependencies/bootstrap
```

```bash
cmake --build build-dependencies/bootstrap --parallel 8
```

Then reconfigure the controller so that it discovers the new prefix:

```bash
cmake --preset host -UOpenCV_DIR
```

```bash
cmake --build --preset host
```

```bash
ctest --preset host
```

The main build discovers `build-dependencies/opencv/lib/cmake/opencv4` when `OpenCV_DIR` is not already
defined. `-UOpenCV_DIR` clears an older cached system selection. An explicit
`-DOpenCV_DIR=/path/to/lib/cmake/opencv4` takes precedence over the isolated prefix.

## 5. Configuration

| Setting | Value |
| --- | --- |
| `XWALK_TRAFCTRL_OPENCV_PREFIX` | Cache path, default `<xWalkTrafCtrl>/build-dependencies/opencv` |
| Source archive | OpenCV tag `4.12.0` from the OpenCV GitHub archive, verified by a pinned SHA-256 |
| Build type | Release |
| Modules | `core`, `imgproc`, `imgcodecs`, `videoio`, `dnn` |
| Disabled | Tests, performance tests, examples, apps, Java, Python 3 bindings, IPP, ITT |
| Enabled | `WITH_OPENCL`, `OPENCV_DNN_OPENCL` |

The isolated build enables OpenCL. CUDA DNN acceleration requires a separately provisioned CUDA/cuDNN-enabled
OpenCV selected through `OpenCV_DIR`. `device=auto` keeps the controller's GPU/CPU selection policy and reports
the selected backend through `TRAFCTRL.004`.

## 6. Dependencies

- CMake with `ExternalProject`; policy `CMP0135` is set to NEW when available.
- C and C++ compilers and network access to download the pinned archive during the bootstrap build.

## 7. Safety and constraints

- The prefix and the bootstrap build directory live under the ignored `build-dependencies` directory. Do not
  remove the prefix while a deployed binary or the `run-xwalk-traffic` launcher still loads its libraries.
- The pinned hash must change together with the archive tag; never disable hash verification.

## 8. Related notes

- [xWalkTrafCtrl](../../xWalkTrafCtrl.md)
- [xWalkModel](../../xWalkModel/xWalkModel.md)

---

[Previous page](../../xWalkTest/xWalkTest.md) · [Chapter index](../../../../index.md) · [Next page](../../../../../06-xwalk-tool/index.md)
