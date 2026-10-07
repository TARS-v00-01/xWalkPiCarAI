<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkConfiguration

**4. xWalk software &middot; Module 05**

<!-- xwalk-page-header:end -->

# xWalkConfiguration

`xWalkConfiguration` provides layered configuration loading and atomic, backup-preserving saves for the desktop
and robot configuration files edited through the HUD and CLI.

## 1. Overview

- Files use the flat `key = value` format with relative `include` files. Included values are merged; later
  definitions win.
- Loading rejects include cycles, files over 1 MiB and include depth above 16.
- Saving appends only changed effective values to the selected root file, preserving original bytes, comments,
  includes and calibration. It never rewrites included files.
- Every changed save creates a timestamped `<file>.bak-<yyyyMMdd-HHmmss-zzz>` copy (UTC) and then atomically
  replaces the selected file, preserving permissions.
- Changes to the root or any included file since loading prevent saving until the file is reopened.
- The module has no direct ownership of Robot HAT devices.

## 2. Source location

`xWalk-rpi5-os/xWalkConfiguration` - source directory

## 3. Directory layout

```text
xWalkConfiguration/
    CMakeLists.txt                              Static library xWalkOsConfiguration and its Google Test
    include/XWalkConfig.h                       Layered reader and atomic override writer
    src/XWalkConfig.cpp                         Include resolution, size/depth/cycle checks, backup and save
    test/src/xWalkConfigurationGoogleTest.cpp   Layered-save and rejection tests
```

## 4. Public interface

`xwalk::hal::XWalkConfig`:

- `bool load(const QString& path, QString& error)` loads a `.cfg`/`.conf` file and its relative includes.
- `bool save(const QMap<QString, QString>& changes, QString& error)` backs up the root file and appends only the
  changed overrides.
- `values` holds the effective key/value map; `fileName` holds the loaded root file.

## 5. Build

CMake target `xWalkOsConfiguration` (static, C++17) links `Qt5::Core`, `xWalkOsBuild` and `xWalkOsTrace` and
compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through the
[desktop root](../xWalk-rpi5-os.md) to compose its dependencies.

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkConfiguration --output-on-failure
```

`LayeredSave` checks include precedence, preserved comments and a single `.bak-*` backup;
`RejectCyclesAndExternalEdits` checks cycle rejection and concurrent-edit detection.

## 7. Safety and constraints

- The module does not elevate privileges; choose an operator-writable runtime file.
- Field semantics and hardware limits remain the responsibility of the owning runtime.
- Do not commit live credentials, account stores or private deployment overrides.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkSettings](../xWalkSettings/xWalkSettings.md)
- [xWalkConfig](../xWalkConfig/xWalkConfig.md)

---

[Previous page](../xWalkConfig/xWalkConfig.md) · [Chapter index](../../index.md) · [Next page](../xWalkDeploy/xWalkDeploy.md)
