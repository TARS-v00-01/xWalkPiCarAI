<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkConfiguration

**5. xWalk node &middot; Module 22**

<!-- xwalk-page-header:end -->

# xWalkConfiguration

`xWalkConfiguration` loads the traffic controller's JSON configuration, applies command-line precedence, resolves
paths and validates every setting before the session starts.

## 1. Overview

`loadSettings` composes the validated `Settings` structure in this order: built-in defaults, the default
`xWalkTrafCtrl.conf`, the host test profile `xWalkHostTest.conf` (host builds only), any `--config FILE` overlays,
then individual command-line overrides. A help argument returns immediately without loading files. Configured
relative paths resolve against their containing JSON file; command-line paths resolve against the working
directory. Unknown sections and fields, invalid types and out-of-range values are rejected with a `TRAFCTRL` error.

Validation rules include:

- `--host` or `--rpi5` must match the compiled build mode.
- Only one of `--video` (alias `--vedio`), `--image`, `--report` and `--protobuf-input` may be given; each
  replaces the configured host video, and all are rejected in Pi mode.
- Host mode requires a configured video or explicit input.
- `frame_stride` must be positive; `input_size` must be a multiple of 32 from 32 to 4096; `confidence` must be in
  (0, 1]; `announcement_interval` must be non-negative; `llm_timeout_ms` must be 1 to 600000.
- Host devices are `auto`, `cpu`, `cuda` or `opencl`. In Pi mode `auto` resolves to `cpu`, or to `hailo8` in a
  Hailo build, and only that device is accepted.
- Endpoint, model name, model root, Hailo group ID and local speech settings must be nonempty; the Hailo timeout
  must be positive.
- Numeric command-line values reject trailing garbage and non-finite numbers. Configuration text cannot
  contain NUL.
- `--evaluation-output` must not resolve to any input, weights or forest path.
- Empty `weights` and `rf_model` are derived from `model_root`.

JSON files are read only when they are regular files of at most 64 MiB containing a JSON object.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkConfiguration` -
source directory

## 3. Directory layout

```text
xWalkConfiguration/
    CMakeLists.txt                        Static library and GoogleTest registration
    include/xWalkConfiguration.h          Settings structure and JSON helpers
    src/xWalkConfiguration.cpp            Loading, merging and validation
    test/src/xWalkConfigurationTest.cpp   Host GoogleTests
```

## 4. Public interface

Declared in
`xWalkConfiguration.h`
in namespace `xwalk::traffic`:

| Symbol | Contract |
| --- | --- |
| `Json` | Owning json-c pointer; releasing the root releases all children |
| `Settings` | Validated, owned settings; paths are resolved before use |
| `readJson(path)` | Load a bounded JSON object; throws on failure |
| `member`, `number`, `text`, `count` | Require a member, finite number, string or bounded unsigned integer |
| `loadSettings(argc, argv)` | Compose default, deployment and CLI settings; throws on rejected input |

The configuration sections and their defaults are documented in [xWalkConfig](../xWalkConfig/xWalkConfig.md).

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). Links publicly to json-c through
`PkgConfig::TRAFFIC_JSON` and includes the generated `xWalkBuildConfig.h` from `<build>/auto-gen/include`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkConfiguration --output-on-failure
```

`xWalkConfigurationGoogleTest` (labels `host;gtest;xWalkConfiguration`) covers path resolution and CLI overrides,
rejection of unknown and invalid settings and trailing numeric garbage, source replacement, announcement routing,
build-specific device and Hailo settings, automatic module and host test profile loading, the `--vedio` alias,
mode-scoped Pi speech settings and the LLM deadline from configuration and CLI.

## 7. Dependencies

- json-c (pkg-config).
- `xWalkLibraryCommon` for project types and `xWalkTrace` (private) for errors.

## 8. Safety and constraints

- Configuration loading never opens a broker connection, camera or model.
- Rejection is explicit; no invalid value is clamped or silently replaced.

## 9. Related notes

- [xWalkConfig](../xWalkConfig/xWalkConfig.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkConfig/xWalkConfig.md) · [Chapter index](../../../index.md) · [Next page](../xWalkInput/xWalkInput.md)
