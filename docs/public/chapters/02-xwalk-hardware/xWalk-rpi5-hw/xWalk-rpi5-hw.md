<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [2. xWalk hardware](../index.md) / xWalk-rpi5-hw

**2. xWalk hardware &middot; Module 01**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-hw

`xWalk-rpi5-hw` is the Raspberry Pi 5 hardware integration repository. It owns the hardware CMake aggregate,
the hardware integration CI entry points, and the root cross-module sequence tests, and it pins the
independently reviewed HAL, Driver, Controller, Library, and audio-resource components.

## 1. Overview

`xWalkPiCarAI` consumes this repository as its `xWalk-rpi5-hw` submodule. Existing source and build paths remain
unchanged. Shared interfaces (`xWalk-rpi5-iw`), tracing (`xWalk-rpi5-trace`), tooling, Node, and desktop sources
remain owned by the product integration; the aggregate adds `xWalk-rpi5-iw` and `xWalk-rpi5-trace` from the sibling
product workspace and does not vendor them.

The root `CMakeLists.txt` declares project `xWalk` version 1.0.0 and:

- includes the `xWalkLibrary` dependency selector before any component;
- adds `xWalkLibrary/common`, the IW and trace runtimes, every HAL interface, device, sensor, and layer-1 module,
  then `xWalkDriver` and `xWalkController`;
- adds HAL host simulations and test suites only for host test builds;
- defines the aggregate `xWalkHal` interface target (alias `xWalk::Hal`), which links every HAL module and, for
  Raspberry Pi builds, the Linux, ALSA, Ollama, Vosk, eSpeak, and Pico2Wave providers;
- registers deployment, tooling, and Library architecture host tests;
- provides `rpi-provision`, `cppcheck`, `cppcheck-full`, `host-dependency-check`, and `host-shellcheck`
  targets, and optional CPack Debian packaging.

## 2. Source location

`xWalk-rpi5-hw` (source directory)

## 3. Directory layout

```text
xWalk-rpi5-hw/
    CMakeLists.txt             Hardware aggregate, options, host tests, provisioning and packaging
    CMakePresets.json          Host, quality, Raspberry Pi, cross and Controller module presets
    eclipse-build.sh           Eclipse host build helper (configure, build, test, or clean)
    LICENSE                    GNU GPL version 3 licence text
    cmake/
        toolchains/
            aarch64-linux-gnu.cmake   ARM64 cross-compilation toolchain
    ci/
        context.json           Pinned submitted product and tool revisions for hardware CI
        run-host-ci.py         Isolated, exactly pinned hardware integration CI entry point
        run-module-tests.py    Complete hardware component host regression
        test-module-runner.py  Regression checks for the module-test inventory filter
        check-audio.py         Media-header validation of the packaged audio assets
        runner/
            runner.env.example                          Sanitized GitHub runner environment template
            xwalk-hardware-github-actions-runner.service  User systemd service template
    xWalkHal/                  Hardware abstraction layer component
    xWalkDriver/               Driver component
    xWalkController/           Controller component
    xWalkLibrary/              Project-managed dependency prefix and common headers
    xWalkAudioResources/       Packaged sound-effect and music assets
    xWalkTest/                 Root cross-module hardware sequence tests
```

## 4. Child modules

- [xWalkHal](xWalkHal/xWalkHal.md): hardware abstraction layer interfaces, devices, sensors, and layer-1 services.
- [xWalkDriver](xWalkDriver/xWalkDriver.md): driver layer between Controller and HAL.
- [xWalkController](xWalkController/xWalkController.md): Controller runtime, Boot graph, and standalone handlers.
- [xWalkLibrary](xWalkLibrary/xWalkLibrary.md): reviewed dependency prefix, Vosk runtime, and generated IW headers.
- [xWalkAudioResources](xWalkAudioResources/xWalkAudioResources.md): packaged sound effects and background music.
- [xWalkTest](xWalkTest/xWalkTest.md): root Controller, Driver, and HAL sequence tests for Robot HAT v4 and v5.

## 5. Public interface

| Target or entry point | Description |
| --- | --- |
| `xWalkHal` / `xWalk::Hal` | Interface target linking every HAL module, Common, IW, and Trace |
| `rpi-provision` | Raspberry Pi provisioning target, defined only when `XWALK_BUILD_RPI=ON` |
| `cppcheck`, `cppcheck-full` | Static analysis over `compile_commands.json` when cppcheck is found |
| `host-dependency-check` | Reports host-quality tool availability |
| `host-shellcheck` | Checks every repository-owned shell script |
| `xWalkHardwareFullTest` | Complete hardware component regression over an existing host build |
| `ci/run-host-ci.py` | Repository-owned hardware integration CI entry point |

## 6. Build

For development, initialize the full product recursively and follow [Building xWalk hardware](BUILDING.md). The
aggregate expects its shared dependencies beside `xWalk-rpi5-hw` in the product workspace.

Configure presets:

| Preset | Purpose |
| --- | --- |
| `host`, `host-debug`, `host-release` | Host build with `BUILD_TESTING=ON` and `XWALK_BUILD_RPI=OFF` |
| `sanity` | Host build with `XWALK_ENABLE_STRICT_WARNINGS=ON` |
| `clang-tidy`, `clang-analyzer` | Static analysis builds |
| `sanitizers`, `leak-sanitizer`, `thread-sanitizer` | AddressSanitizer/UBSan or ThreadSanitizer builds |
| `coverage`, `coverage-clang` | GCC gcov or Clang coverage builds |
| `valgrind` | Host build configured for `ctest -T memcheck` with Valgrind |
| `fuzz` | Clang libFuzzer harnesses (`xWalkFuzzers` build target) |
| `rpi`, `rpi-release` | Native Raspberry Pi build with `XWALK_BUILD_RPI=ON` |
| `rpi-cross`, `aarch64-rpi-release` | ARM64 cross build with packaging; requires `XWALK_AARCH64_SYSROOT` |
| `module` | Controller module verification with `XWALK_CONTROLLER_BUILD_MODULE=ON` |

The `rpi-provision` build preset builds the `rpi-provision` target. The `host-stress` test preset repeats the
`sanity` tests until failure, up to 20 times.

```bash
cmake --preset host
```

```bash
cmake --build --preset host
```

The Eclipse helper configures, builds, and tests `xWalkController/build-eclipse-host`, or removes it with `clean`:

```bash
./eclipse-build.sh
```

## 7. Configuration

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_CONTROLLER_BUILD_MODULE` | `OFF` | Build only the Controller terminal and standalone handler stubs |
| `XWALK_BUILD_RPI` | `OFF` | Build Raspberry Pi backends and deployment configuration |
| `XWALK_BUILD_ALL_BACKENDS` | `OFF` | Compile every Linux provider without selecting hardware execution |
| `XWALK_ENABLE_STRICT_WARNINGS` | `OFF` | Add the host sanity warning extensions |
| `XWALK_ENABLE_SANITIZERS` | `OFF` | Enable AddressSanitizer and UndefinedBehaviorSanitizer |
| `XWALK_ENABLE_THREAD_SANITIZER` | `OFF` | Enable ThreadSanitizer for host concurrency tests |
| `XWALK_ENABLE_COVERAGE` | `OFF` | Enable coverage instrumentation |
| `XWALK_COVERAGE_BACKEND` | `gcc` | Coverage backend: `gcc` or `clang` (Clang requires a Clang compiler) |
| `XWALK_ENABLE_PACKAGING` | `OFF` | Enable CPack Debian package generation |
| `XWALK_BUILD_FUZZERS` | `OFF` | Build Clang libFuzzer harnesses |
| `XWALK_AARCH64_DEPENDENCY_AUDIT` | `ON` | Audit required target dependencies before an AArch64 RPI configure |
| `XWALK_RPI_WITH_VOSK` | `ON` | Install repository-controlled Vosk assets while provisioning |
| `XWALK_RPI_WITH_OLLAMA` | `ON` | Install and configure the user-local Ollama runtime while provisioning |

A host test build (`BUILD_TESTING=ON`, `XWALK_BUILD_RPI=OFF`) forces `XWALK_HAL_BUILD_HOST`,
`XWALK_AGENT_BUILD_HOST`, and `XWALK_CLI_INSTALL_RUNTIME` on; `XWALK_HAL_BUILD_RPI` and `XWALK_AGENT_BUILD_RPI`
follow `XWALK_BUILD_RPI`. Raspberry Pi defaults are read from
`rpi-defaults.conf`, which must define each
default exactly once. A native ARM64 build with the CSI camera requires the libcamera GStreamer plugin,
`gst-inspect-1.0`, and `ldd`.

Debian packaging requires `XWALK_BUILD_RPI=ON` and an ARM64 target; the x86 RPI profile is compile-check only.
The package is `xwalk-picarx` for `arm64`, installed under `/usr`.

## 8. Testing

Host tests run without hardware:

```bash
ctest --preset host
```

The complete hardware component regression builds the host aggregate, selects every enabled, non-hardware test
owned by HAL, Driver, Controller, Library, and the root `xWalkTest`, runs them, and then validates the audio
assets. It fails if any required component group is missing or if the cache is not a HOST testing build:

```bash
python3 ci/run-module-tests.py --jobs 4
```

Root-registered host tests and their labels:

| Test | Labels |
| --- | --- |
| `xWalkProvisioningHostTest` | `host;deployment` |
| `xWalkRpiProvisionCMakeHostTest` | `host;deployment;cmake` |
| `xWalkLanguageModelConfigHostTest`, `xWalkEnvironmentLoaderHostTest` | `host;deployment` |
| `xWalkLicenseToolHostTest` | `host;deployment;security` |
| `xWalkCodeHealthHostTest`, `xWalkStylerHostTest` | `host;tooling;network-free;quality` |
| `xWalkConditionCheckHostTest`, `xWalkConditionCheckUnitHostTest` | `host;tooling;network-free;quality` |
| `xWalkJiraImportHostTest`, `xWalkGerritHostTest` | `host;tooling;network-free` (conditional) |
| `xWalkGerritUiHostTest` | `host;tooling;network-free` (conditional) |
| `xHal_Rpi5CarDependencyInstallerHostTest` | `host;deployment` |
| `xWalkAarch64DependencyAuditHostTest` | `host;deployment;dependency` |
| `xWalkLibrary*ArchitectureHostTest` | `host;dependency` |

Hardware tests are opt-in. List them only:

```bash
ctest -N -L hardware
```

Do not run hardware tests without explicit approval and a confirmed, safe Raspberry Pi and Robot HAT setup.

## 9. Dependencies

- Sibling product modules: `xWalk-rpi5-iw`, `xWalk-rpi5-trace`, and `xWalk-rpi5-tool`.
- `xWalkLibrary` project-managed prefixes, with system packages as fallback.
- GoogleTest and Python 3 for host tests; cppcheck, clang-tidy, Valgrind, and Clang libFuzzer for optional
  quality targets.
- Debian package runtime dependencies: `espeak-ng`, `i2c-tools`, `gpiod`, `python3`, `python3-nacl`; recommended
  `rpicam-apps | ffmpeg`.

## 10. Safety and constraints

- Host builds and CI use deterministic HOST providers and never operate the robot.
- `XWALK_HAL_BUILD_RPI` requires a Linux build host.
- Hardware-labelled tests stay excluded from CI and the full regression.
- Never push component changes directly to GitHub; upload to Gerrit only.

## 11. Related notes

- [xWalkPiCarAI](../../01-xwalk-workspace/xWalkPiCarAI.md)
- [Building xWalk hardware](BUILDING.md)
- [xWalk-rpi5-iw](../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md)
- [xWalk-rpi5-trace](../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- [xWalk-rpi5-os](../../04-xwalk-software/xWalk-rpi5-os/xWalk-rpi5-os.md)

---

[Previous page](../index.md) · [Chapter index](../index.md) · [Next page](xWalkAudioResources/xWalkAudioResources.md)
