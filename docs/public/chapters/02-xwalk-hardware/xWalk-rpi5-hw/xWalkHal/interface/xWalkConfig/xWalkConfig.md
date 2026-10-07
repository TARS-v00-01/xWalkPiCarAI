<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkConfig

**2. xWalk hardware &middot; Module 70**

<!-- xwalk-page-header:end -->

# xWalkConfig

`xWalkConfig` is a C++17 embedded-oriented configuration module for section-aware and flat key-value files. It
has no physical-hardware backend.

## 1. Overview

The module retains two focused classes, both provided by the single `xWalkConfig` static library:

- `XWalkConfig` provides section-aware parsing, in-memory editing, explicit reload, and persistence while
  preserving unrelated file content.
- `XWalkConfigStore` provides lightweight string-key persistence used for calibration values and Robot servo
  offsets.

Create configuration objects in `main()` or the application composition root. Hardware drivers receive parsed
values or a required configuration-store reference and do not create configuration objects internally.

```cpp
XWalkConfig configuration("config/robot.ini", "Robot settings");
configuration.set("motor", "speed", "75");
configuration.write();

XWalkConfigStore offsets("config/servo-offsets.config");
offsets.set("legs", "0, 0, 0, 0");
```

Each object owns its configured filesystem path and serializes operations made through that object. Separate
instances addressing the same file, or external writers, require application-level synchronization.

### Section-aware configuration behavior

- Blank lines and lines beginning with `#` are not parsed as options.
- Section headers use `[section]`; assignments split at the first `=`.
- Names and values are trimmed when read.
- Missing options are inserted into memory using the supplied default.
- Comments, blank lines, unrelated options, and unrelated text are retained.
- New files may receive a multiline description rendered as `# ` comments.
- Updates use a same-directory replacement file and preserve permission bits.

### String-key configuration-store behavior

- A missing parent directory and configuration file are created.
- Missing keys return the supplied default.
- ASCII spaces are removed from unquoted retrieved values to preserve the established file contract.
- Surround a value with double quotes when internal ASCII spaces are significant; the quotes are not returned.
- The last duplicate key wins during retrieval.
- `include = relative/path.conf` recursively inserts a `.conf` file at that position; absolute paths, parent
  traversal, cycles, and depth above eight are rejected.
- Updates replace every matching duplicate entry or append an absent key.
- Updates affect only the primary file, allowing it to override read-only included defaults.
- Comments and malformed unrelated lines remain unchanged.

The module does not accept ownership and permission arguments or invoke shell commands. Apply deployment
ownership and permission policy through trusted platform provisioning.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig` -
source directory

## 3. Directory layout

```text
xWalkConfig/
    CMakeLists.txt                               Static library and host-test targets
    include/
        xHal_Rpi5CarConfig.h                     Section-aware configuration class
        xHal_Rpi5CarConfigStore.h                Flat string-key configuration store
        xHal_Rpi5CarConfigTypes.h                configsection and configsections aliases
    src/
        xHal_Rpi5CarConfig.cpp                   Parsing, merging, get and set
        xHal_Rpi5CarConfigLifecycle.cpp          Construction, validation, and file creation
        xHal_Rpi5CarConfigStore.cpp              Store retrieval, include expansion, and updates
        xHal_Rpi5CarConfigStoreLifecycle.cpp     Store construction and file creation
    simulation/                                  Standalone persistence simulation
    test/
        include/xHal_Rpi5CarConfigTestSupport.h  Reusable section-config test declarations
        src/xHal_Rpi5CarConfigTest.cpp           Section-aware configuration host test
        src/xHal_Rpi5CarConfigTestSupport.cpp    Test support implementation
        src/xHal_Rpi5CarConfigStoreTest.cpp      Configuration-store host test
```

## 4. Child modules

- [xWalkConfig Simulation](simulation/xWalkConfig%20Simulation.md) - standalone executable that persists and
  reconstructs one section-aware file and one flat store below its build directory.

## 5. Public interface

Headers live in `include`.

- `xHal_Rpi5CarConfig.h`:
  `XWalkConfig(filePath, description)`, `read`, `write`, `get`, `set`, `section`, `setSection`, and
  `filePath`.
- `xHal_Rpi5CarConfigStore.h`:
  `XWalkConfigStore(filePath)`, `get`, `set`, and `filePath`.
- `xHal_Rpi5CarConfigTypes.h`:
  `configsection` (ordered option map) and `configsections` (ordered section map).

The replacement-file suffix (`.tmp`), comment prefix, and assignment separator are defined in the common library
header `xHal_Rpi5CarCommon.h`.

## 6. Build

| Target | Kind | Condition |
| --- | --- | --- |
| `xWalkConfig` | Static library | Always |
| `xWalkConfigTest` | Host test executable | `XWALK_CONFIG_BUILD_HOST_TESTS` |
| `xWalkConfigStoreTest` | Host test executable | `XWALK_CONFIG_BUILD_HOST_TESTS` |

`XWALK_CONFIG_BUILD_HOST_TESTS` defaults to `OFF`. The repository-level `xWalk-rpi5-hw/CMakeLists.txt` also adds
this module to the aggregate build.

Target compilation from the repository root:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig -B xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/build-rpi -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/build-rpi --parallel
```

Target verification compiles the production filesystem library without executing filesystem operations.

## 7. Testing

| CTest name | Executable | Label | Data path below the build directory |
| --- | --- | --- | --- |
| `xWalkConfigHostTest` | `xWalkConfigTest` | `host` | `test-data/section-config/config.ini` |
| `xWalkConfigStoreHostTest` | `xWalkConfigStoreTest` | `host` | `test-data/config-store/config-store.config` |

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig -B xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/build-host -DXWALK_CONFIG_BUILD_HOST_TESTS=ON
```

```bash
cmake --build xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/build-host --parallel
```

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkHal/interface/xWalkConfig/build-host -L host --output-on-failure
```

Both tests write only beneath `build-host/test-data`. They do not access physical hardware or deployed
configuration paths. Test diagnostics and enabled operations use trace macros and appear in the terminal and
the target-specific log under `build-host/log`. Successful selector changes persist in the generated XML and
load automatically on later runs.

The module has no hardware test. The aggregate
[xWalkHal Interface Tests](../test/xWalkHal%20Interface%20Tests.md) and
[xGoogleTest](../../xWalkTest/xGoogleTest/xGoogleTest.md) suites reuse its test sources.

## 8. Dependencies

- `xWalkLibraryCommon` (public) for project types and configuration constants.
- `xWalkTrace` (private) for diagnostics.
- Python 3 for the host-test trace catalogue.

## 9. Safety and constraints

- Tests and the simulation never modify deployed configuration.
- Keep deployment configuration templates tracked in their owning submodule; installed files are not a
  reproducible source.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalkRobot](../../layer1/xWalkRobot/xWalkRobot.md)
- [xWalkPicarx](../../../xWalkDriver/xWalkVehicle/xWalkPicarx/xWalkPicarx.md)

---

[Previous page](../xWalkAudio/simulation/xWalkAudio%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](simulation/xWalkConfig%20Simulation.md)
