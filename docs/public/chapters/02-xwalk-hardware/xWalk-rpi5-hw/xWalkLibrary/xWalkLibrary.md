<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [2. xWalk hardware](../../index.md) / xWalkLibrary

**2. xWalk hardware &middot; Module 112**

<!-- xwalk-page-header:end -->

# xWalkLibrary

`xWalkLibrary` is the reviewed project-managed dependency prefix for portable third-party libraries, native
runtimes, models, generated IW headers, and the workspace-wide common C++ headers. Operating-system tools and
hardware integration remain outside this tree and are managed by the platform.

## 1. Overview

The component provides:

- `XWalkDependencies.cmake`, which selects the `x86_64` or `aarch64` native prefix for CMake package discovery;
- `VoskModel.cmake`, which resolves the bundled Vosk runtime library and speech model;
- architecture-specific native prefixes with the Vosk 0.3.45 runtime and C API header;
- tracked, generated plain C++17 IW headers under `auto-gen`;
- the header-only `xWalkLibraryCommon` interface target under `common`.

Place architecture-independent models and configuration under `common`. Install a reviewed native dependency
into the conventional `bin`, `include`, `lib`, and `share` directories of each supported architecture. Never
copy a native binary between architecture prefixes.

Suitable project-managed dependencies include Vosk, GoogleTest, TinyXML2, yaml-cpp, Protobuf, gRPC, libsndfile,
and other ordinary portable C or C++ libraries. A library is not considered bundled merely because its directory
exists: retain its upstream version, source URL, checksum, license, and target architecture.

The compiler, linker, CMake, Ninja, Linux kernel interfaces, ALSA integration, udev rules, camera tools, Device
Tree overlays, system services, and package-management utilities remain system-managed. Do not extract ordinary
Debian packages into this prefix as a substitute for a reviewed relocatable build; package scripts, absolute
paths, transitive dependencies, and metadata may assume system installation locations.

## 2. Source location

`xWalk-rpi5-hw/xWalkLibrary` (source directory)

## 3. Directory layout

```text
xWalkLibrary/
    XWalkDependencies.cmake    Architecture selection, project-first search order and build RPATH
    VoskModel.cmake            Vosk runtime library and model path resolution
    X_WALK_LICENSE.KEY         Encrypted deployment environment values (untracked; created by the licence tool)
    auto-gen/                  Generated IW struct, enum, and signal macro headers
    common/                    Header-only xWalkLibraryCommon target and architecture-independent assets
        include/               Workspace-wide public C++ headers
        configuration/         Architecture-independent configuration (placeholder)
        models/vosk/           Small US English Vosk model and its Apache 2.0 LICENSE
        test/                  Format and Agent configuration-type host tests
    test/
        xWalkLibraryArchitectureTest.cmake   Script-mode architecture selection test
    x86_64/                    Native prefix for Linux x86-64
        bin/ include/ lib/ share/
    aarch64/                   Native prefix for Linux ARM64/AArch64
        bin/ include/ lib/ share/
```

## 4. Child modules

- [xWalkLibrary Common](common/xWalkLibrary%20Common.md): header-only `xWalkLibraryCommon` target with the shared
  types, constants, file, format, math, and test helpers.

## 5. Public interface

| Item | Description |
| --- | --- |
| `XWalkDependencies.cmake` | Sets the Library root and the common and native prefix variables |
| `VoskModel.cmake` | Sets and validates `XWALK_VOSK_LIBRARY_PATH` and `XWALK_VOSK_MODEL_PATH` |
| `auto-gen/*.h` | Plain IW message structs, enums, and signal macros |
| `xWalkLibraryCommon` | Header-only interface target exporting `common/include` and `auto-gen` |

Sources: `XWalkDependencies.cmake` and
`VoskModel.cmake`.

## 6. Build

`XWalkDependencies.cmake` maps `CMAKE_SYSTEM_PROCESSOR` (`x86_64`/`amd64` or `aarch64`/`arm64`) to `x86_64` or
`aarch64`. It prepends the selected native prefix and `common` to `CMAKE_PREFIX_PATH`, so compatible
project-managed packages are preferred and ordinary system discovery remains the fallback. Unsupported processors
fail configuration instead of loading a mismatched native library.

Root and dependency-owning standalone module builds include this selector automatically. An external consumer can
select the prefix explicitly:

```sh
cmake -S . -B build -DCMAKE_PREFIX_PATH="$PWD/xWalkLibrary/x86_64"
```

For an AArch64 cross-build or Raspberry Pi target:

```sh
cmake -S . -B build-rpi -DCMAKE_PREFIX_PATH="$PWD/xWalkLibrary/aarch64"
```

## 7. Configuration

| Variable | Default | Effect |
| --- | --- | --- |
| `XWALK_LIBRARY_ARCHITECTURE` | Detected from `CMAKE_SYSTEM_PROCESSOR` | Native prefix: `aarch64` or `x86_64` |
| `XWALK_LIBRARY_PREFER_PROJECT_DEPENDENCIES` | `ON` | Search `xWalkLibrary` first; `OFF` uses system order |
| `XWALK_LIBRARY_USE_BUILD_RPATH` | `ON` | Embed the selected `lib` and `lib64` in build-tree binaries |
| `XWALK_VOSK_ARCHITECTURE` | `XWALK_LIBRARY_ARCHITECTURE` | Vosk native runtime architecture |
| `XWALK_VOSK_LIBRARY_PATH` | `<arch>/lib/libvosk.so` | Vosk shared library; must exist |
| `XWALK_VOSK_MODEL_PATH` | `common/models/vosk/vosk-model-small-en-us-0.15` | Vosk model directory; must exist |

Installed system packages retain the deployment RPATH policy of their own install target and do not depend on
`LD_LIBRARY_PATH`. No bundled Vosk runtime supports 32-bit Raspberry Pi OS.

### Licence key

`X_WALK_LICENSE.KEY` is the fixed versioned authenticated-encryption output for deployment environment values. It
is data, never a compiler or linker input, and it is not tracked in this repository; the
licence-key tool writes it here and the environment loader reads it.
Never commit it.

### Vosk inventory

| Asset | Version | Target | Runtime path |
| --- | --- | --- | --- |
| Vosk shared library | 0.3.45 | Linux ARM64/AArch64 | `aarch64/lib/libvosk.so` |
| Vosk shared library | 0.3.45 | Linux x86-64 | `x86_64/lib/libvosk.so` |
| Vosk C API header | 0.3.45 | ARM64/AArch64 declarations | `aarch64/include/vosk_api.h` |
| Vosk C API header | 0.3.45 | x86-64 declarations | `x86_64/include/vosk_api.h` |
| Small US English model | 0.15 | Architecture-independent | `common/models/vosk/vosk-model-small-en-us-0.15` |
| CMake selector | Project | Target architecture mapping | `VoskModel.cmake` |

The runtime archive comes from the official
`vosk-api` 0.3.45 release. The model comes from the
official [Vosk model catalog](https://alphacephei.com/vosk/models). Both are distributed under Apache License 2.0;
the retained license is
`common/models/vosk/LICENSE`.

Reviewed archive checksums:

```text
45e95d37755deb07568e79497d7feba8c03aee5a9e071df29961aa023fd94541  vosk-linux-aarch64-0.3.45.zip
bbdc8ed85c43979f6443142889770ea95cbfbc56cffb5c5dcd73afa875c5fbb2  vosk-linux-x86_64-0.3.45.zip
30f26242c4eb449f948e42cb302dd7a686cb29a3423a8367f99ff41780942498  vosk-model-small-en-us-0.15.zip
```

Retained native-library SHA-256 checksums:

```text
0e9df29f060a93cf3df3263a4d3635e1b75688a5fd84e86ade1599372e3c9597  aarch64/lib/libvosk.so
85c4654de3acdeb99abab86eeb2a6e603927d37089597c0fcc33d8638dc2ccaf  x86_64/lib/libvosk.so
```

### Generated IW headers

`auto-gen` contains tracked plain C++17 headers generated from every IW Protobuf schema and signal XML registry.
The `xWalkLibraryCommon` target exports this include directory. Messages become structs and enums retain their
wire values in `xwalk::iw::v1::plain`, separate from the Protobuf runtime classes; the borrowed `StringView` and
`BytesView` helpers live in `xwalk::iw::plain`. String, byte, and repeated fields reference caller-owned storage;
they do not allocate or release memory. Optional scalar and singular message fields have `has_<field>` presence
flags. These structures are not serialized Protobuf buffers.

`xHal_Rpi5CarIwGenerator` regenerates both this copy and `xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/auto-gen`; see
the [Developer Tool](../../../06-xwalk-tool/xWalk-rpi5-tool/py-agent/dev-tool/Developer%20Tool.md) note. Commit generated headers
together with the corresponding reviewed schema changes; do not edit or reformat them manually.

## 8. Testing

Host tests registered by the `xWalk-rpi5-hw` root run the architecture test script in CMake script mode:

| Test | Labels | Checks |
| --- | --- | --- |
| `xWalkLibraryX86ArchitectureHostTest` | `host;dependency` | `x86_64` selection, Vosk paths, headers |
| `xWalkLibraryAarch64ArchitectureHostTest` | `host;dependency` | `aarch64` selection, Vosk paths, headers |
| `xWalkLibraryUnsupportedArchitectureHostTest` | `host;dependency` | `armv7l` must fail (`WILL_FAIL`) |

```bash
ctest --test-dir ../build-host/cmake -L dependency --output-on-failure
```

The Common format and Agent configuration-type tests are described in the
[xWalkLibrary Common](common/xWalkLibrary%20Common.md) note. The Library has no hardware tests.

## 9. Dependencies

- CMake 3.16 or later.
- Vosk 0.3.45 native runtime and small US English model 0.15 (bundled).

## 10. Safety and constraints

### Trace ownership

Compiled sources below `xWalkLibrary` use `XWALK_LIB_TRACE_UIDn` with `LIB.<numeric-id>` identifiers. The
build-time trace scanner rejects HAL, Controller, or Agent trace families in this tree.

The header-only `common` target intentionally remains independent of `xWalkTrace`, because the trace runtime itself
depends on Common types. A compiled Library component may link `xWalkTrace` privately when it emits a Library
trace; Common headers must not include the trace header merely to emit diagnostics.

### Prefix rules

- Never copy a native binary between architecture prefixes.
- Do not format or edit vendored headers under `x86_64` or `aarch64`, or generated headers under `auto-gen`.
- Never commit `X_WALK_LICENSE.KEY` or other secret-bearing configuration.

## 11. Related notes

- [xWalk-rpi5-hw](../xWalk-rpi5-hw.md)
- [xWalkLibrary Common](common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-iw](../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md)
- [xWalk-rpi5-trace](../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)
- License Key Workflow

---

[Previous page](../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md) · [Chapter index](../../index.md) · [Next page](common/xWalkLibrary%20Common.md)
