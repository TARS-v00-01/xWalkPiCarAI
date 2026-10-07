<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / Developer Tool

**6. xWalk tool &middot; Module 08**

<!-- xwalk-page-header:end -->

# Developer Tool

`dev-tool` contains the executable Python utilities used for xWalk development: dependency preparation,
interface generation, licence configuration, code-health and condition checks, Zuul validation, runtime
configuration lookup, and the repository C++ styler.

## 1. Overview

The interface generator, licence tool, CodeScene configuration validator, condition checker, Zuul validator,
and all repository tests are host-safe. The dependency installer's Raspberry Pi apply modes can modify the host
and must be used only on an explicitly approved device. Code-health analysis requires an administrator-installed
and licensed CodeScene CLI; it never downloads one. Most tools are also reachable through the `xWalkPyAgent`
facade described in the Python Agent note.

## 2. Source location

`xWalk-rpi5-tool/py-agent/dev-tool` - source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/py-agent/dev-tool/
    xHal_Rpi5CarDependencyInstaller          Catalog-driven host and Raspberry Pi dependency installer
    xHal_Rpi5CarIwGenerator                  IW schema validator and C++, header, Python, Android generator
    xHal_Rpi5CarIwPlainHeaders.py            Plain struct, enum, and XML signal macro header renderer
    xHal_Rpi5CarMqttRegistryGenerator.py     MQTT registry generator used by the IoT CMake build
    xHal_Rpi5CarControllerJsonGenerator.py   Controller Protobuf-to-plain copy and dispatch generator
    xWalkCodeHealth                          Policy-controlled CodeScene CLI delta analysis
    xWalkConditionCheck                      Rejects calls inside C++ decision conditions
    xWalkLicenseTool                         Model-setting encryption and decryption
    xWalkRuntimeConfiguration.py             Reads one layered flat runtime configuration value
    xWalkZuulValidator                       Validates repository-owned Zuul job structure
    styler-tool/                             Repository-wide C++ formatter, fallback config, and tests
    test/                                    Host-only developer-tool tests
```

## 4. Child modules

- [Styler Tool](styler-tool/Styler%20Tool.md) - repository-wide C++ formatter and format checker.

## 5. Public interface

For dependency installation, prefer the root `setup.sh` and the two Bash scripts at the tools root documented
in xWalk-rpi5-tool. Run the commands below from the integrated
repository root:

```sh
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --help
xWalk-rpi5-tool/py-agent/dev-tool/xWalkLicenseTool --help
xWalk-rpi5-tool/py-agent/dev-tool/xWalkCodeHealth validate-config
xWalk-rpi5-tool/py-agent/dev-tool/xWalkCodeHealth analyze
xWalk-rpi5-tool/py-agent/dev-tool/styler-tool/xWalkStyler check
python3 xWalk-rpi5-tool/py-agent/dev-tool/xWalkZuulValidator .zuul.yaml
python3 xWalk-rpi5-tool/py-agent/dev-tool/test/test_xWalkLicenseTool.py
```

### Dependency installer

`xHal_Rpi5CarDependencyInstaller` reads the shared package catalog. It accepts `--os`, `--device` (alias
`--target`) with `auto`, `host`, or `rpi`, a physically verified `--profile robot_hat_v4|robot_hat_v5` that is
required for Raspberry Pi boot changes, `--camera auto|none|csi|usb`, repeated `--include SCOPE`, and
`--required-only`. The mutually exclusive actions are `--check`, `--dry-run`, and `--install`; install is the
default when no action is given.

```sh
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarDependencyInstaller --check
```

### Decision-condition checks

`xWalkConditionCheck` rejects function and macro calls inside C++ `if` and `while` conditions.
Build, generated, and third-party directories are excluded relative to the supplied source root.
A checkout beneath an external `build-host` or `generated` directory is still audited, including Gerrit CI
workspaces; only matching directories inside that checkout are excluded.

```bash
python3 xWalk-rpi5-tool/py-agent/dev-tool/xWalkConditionCheck xWalk-rpi5-hw
```

### Code health and Zuul validation

`xWalkCodeHealth validate-config` validates `.codescene/project.json`, `architectural-components.json`, and
`analysis-exclusions.txt` at the repository root. `xWalkCodeHealth analyze` runs the CodeScene CLI delta
analysis and writes reports to `XWALK_CODESCENE_REPORT_DIRECTORY` (default `build-host/codescene`).
`xWalkZuulValidator` validates the retained optional Zuul definitions and playbook references; its argument
defaults to `.zuul.yaml`.

### Runtime configuration lookup

`xWalkRuntimeConfiguration.py CONFIGURATION KEY` reads one layered flat runtime value without modifying files or
loading devices.

### Plain IW header generation

The IW generator uses `protoc` descriptors to generate one `.h` per source `.proto` and one `.h` per signal XML
registry, plus `xHal_Rpi5CarXIwPlainTypes.h` for borrowed string and byte views. Both consumer directories receive
identical, deterministic headers:

- `xWalk-rpi5-hw/xWalkLibrary/auto-gen`
- `xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/auto-gen`

Run from the workspace root:

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-headers
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-headers
```

`--generate-cpp` regenerates the C++ Protobuf bindings in `xWalk-rpi5-node/xWalkIoT/auto-gen` and
`xWalk-rpi5-hw/xWalkController/auto-gen`, these consumer headers, desktop Python interfaces, and Android Java
interfaces together. Repeat `--generated-directory PATH` to override the Protobuf binding destinations.
`--check-cpp` fails on a missing, stale, or obsolete binding in either copy without modifying files:

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-cpp
```

`--check` validates the schemas and XML without requiring consumer outputs. `--check-headers` additionally
fails on missing or changed output without modifying files. Repeat `--plain-output-directory PATH` to override
the consumer destinations for isolated tests.

Messages become standard-layout, trivially copyable C++17 structs in the schema package's `plain` namespace
(`xwalk::iw::v1::plain` for xWalk). Enums preserve their numeric values. Struct fields retain source names, and
comments retain field numbers. Singular message and proto3 optional fields have a `has_<field>` Boolean.
Scalars default to their Protobuf zero values; enums default to their first value. Application adapters remain
responsible for applying any documented application defaults when an optional field is absent.

Strings use a borrowed `StringView` (`data`, `size`); bytes use `BytesView`. A repeated field uses a const pointer
and `<field>_count`. A nonzero size or count requires valid caller-owned storage for the entire use of the view.
No allocation, ownership transfer, serialization, or deserialization is generated. Real oneofs, maps, nested
schema types, recursive by-value messages, and member-name collisions are rejected explicitly.

Signal headers retain XML names and numbers as unconditional `#define` macros. Both output copies share
file-level include guards so they can be included together. The generator
preserves unrelated files and refuses to overwrite a file without its generated-file marker. Generated headers
are versioned source artifacts: regenerate and commit them whenever the input schemas or registries change.

### Python IW interface generation

The same validated IW schemas produce five standard Protobuf `_pb2.py` modules in
`xWalk-pcx86-app/auto-gen`: signal enums, common messages, requests, confirmations, and rejections.
These are wire-compatible Protobuf classes, including serialization, parsing, and optional-field presence.
Imported Google descriptors come from the Python `protobuf` runtime; they are not copied into the app.

Run from the workspace root:

```bash
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-python
xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-python
```

`--generate-python` leaves C++ outputs unchanged. `--check-python` compares freshly compiled output without
creating or modifying destination files. Use `--python-output-directory PATH` to override the destination,
including when running `--generate-cpp` in an isolated checkout. Use the same `protoc` version for generation
and freshness checks. Unchanged outputs retain their timestamps; unrelated files are preserved, and existing
files without the Protobuf generated-file marker are not overwritten. Regenerate these files after IW changes;
do not edit generated classes manually. Add the output directory to Python's import path before importing modules.

### Android Java interfaces

The Python IW generator also emits native Android Java GPB bindings from the same validated IW
schemas into `xWalk-arm64-app/auto-gen/java/xwalk/iw/v1`. No shell wrapper or Gradle invocation is used.

```bash
python3 xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --generate-android
python3 xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarIwGenerator --check-android
```

`--generate-android` changes only Android outputs. `--check-android` is read-only and rejects missing,
stale or obsolete output. `--android-output-directory PATH` overrides the Java source root.
Use the same `--protoc` version for generation and checks; `--protobuf-include` locates Google imports.
Unchanged files keep their timestamps. Handwritten files are preserved; only obsolete Java files
marked as generated from the supplied schemas are removed. `--generate-cpp` also refreshes Android
bindings, alongside C++ consumers and desktop Python interfaces. Native Android Gradle builds retain
their own compiler-managed output and do not compile this export twice.

### Controller JSON generator

`xHal_Rpi5CarControllerJsonGenerator.py` generates Controller terminal Protobuf-to-plain copies and
signal dispatch. It shares the lazy Python facade with the IW and MQTT generators. Controller CMake
invokes it automatically and tracks both the generator and facade sources for regeneration.

From the integrated repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=xWalk-rpi5-tool/py-agent/py-src python3 -m xWalkPyAgent controller-json --help
```

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=xWalk-rpi5-tool/py-agent/py-src python3 -m xWalkPyAgent controller-json --controller xWalk-rpi5-hw/xWalkController --plain xWalk-rpi5-hw/xWalkLibrary/auto-gen --output xWalk-rpi5-hw/xWalkController/build-host/xWalkStandAlone/generated/json
```

The command forwards paths unchanged, including spaces, and returns the generator exit status.

### MQTT registry generator

`xHal_Rpi5CarMqttRegistryGenerator.py` requires `--iw`, `--functions`, `--samples`, and `--output`. The IoT CMake
target `xWalkMqttRegistry` invokes it automatically through `python3 -m xWalkPyAgent mqtt-registry`.

## 6. Testing

The `test` directory contains host-only developer-tool tests:

```sh
python3 -m unittest discover -s xWalk-rpi5-tool/py-agent/dev-tool/test -p 'test_*.py'
```

```sh
python3 xWalk-rpi5-tool/py-agent/dev-tool/test/xHal_Rpi5CarMqttRegistryGeneratorTest.py
```

The suites cover the IW generator, code-health configuration, condition checker, licence tool, runtime
configuration lookup, and MQTT registry generator.

## 7. Dependencies

- Python 3. Install `protobuf-compiler`, `libprotobuf-dev`, and `python3-protobuf` on Ubuntu for IW generation;
  `grpc_cpp_plugin` is required for gRPC sources.
- PyNaCl for `xWalkLicenseTool`.
- A licensed, administrator-installed CodeScene CLI for `xWalkCodeHealth analyze`.

## 8. Safety and constraints

- `xHal_Rpi5CarDependencyInstaller` installs packages by default; use `--check` or `--dry-run` to inspect.
  Raspberry Pi boot changes require a physically verified Robot HAT profile on an approved device.
- Generated files are versioned source artifacts: regenerate and commit them after schema changes; never edit
  them manually.

## 9. Related notes

- Python Agent
- [Dependency Installer Guide](../../../../08-xwalk-guides/Doc/note/Dependency%20Installer%20Guide.md)
- xWalk Licence Tool Guide
- xWalk-rpi5-tool

---

[Previous page](../../cpp-tool/fuzz/Fuzz%20Testing%20Tool.md) · [Chapter index](../../../index.md) · [Next page](styler-tool/Styler%20Tool.md)
