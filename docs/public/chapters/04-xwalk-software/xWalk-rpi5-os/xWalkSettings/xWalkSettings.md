<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkSettings

**4. xWalk software &middot; Module 16**

<!-- xwalk-page-header:end -->

# xWalkSettings

`xWalkSettings` is the touch dialog that selects, filters and edits configuration files, with numeric sliders
whose limits are shared with CLI configuration edits.

## 1. Overview

- Opens the Robot / Pi or Desktop configuration from the HUD Settings screen; **Open .cfg / .conf** browses any
  readable configuration file from the configured `config_directory`. File selection is modeless so the native
  touch keyboard remains usable for typed paths.
- Shows effective layered values loaded through `XWalkConfig`. Numeric scalar fields have synchronized sliders
  and number entry, booleans have checkboxes, and strings, arrays and provider-specific values keep text entry.
- Fields can be filtered by name. Secret-named fields (keys containing `password`, `token`, `api_key` or
  `secret`) are masked.
- Saving uses the atomic, backup-preserving `XWalkConfig::save` and emits `saved()`.
- `numericRange` and `acceptsValue` give the CLI the same type and numeric limits as the GUI editor. An existing
  value outside the preferred bounds is retained.

## 2. Source location

`xWalk-rpi5-os/xWalkSettings` - source directory

## 3. Directory layout

```text
xWalkSettings/
    CMakeLists.txt                          Static library xWalkOsSettings and its Google Test
    include/XWalkSettings.h                 Settings dialog and shared value limits
    src/XWalkSettings.cpp                   File selection, filtering, sliders and save
    test/src/xWalkSettingsGoogleTest.cpp    CLI value-limit and slider tests
```

## 4. Public interface

`xwalk::hal::XWalkSettings` (`QDialog`):

- `XWalkSettings(const QString& file, const QString& browseRoot, QWidget* parent = nullptr)`
- `static QPair<double, double> numericRange(const QString& key, double current)`
- `static bool acceptsValue(const QString& key, const QString& original, const QString& value)`
- signal `saved()`

## 5. Build

CMake target `xWalkOsSettings` (static, C++17) links `Qt5::Widgets`, `xWalkOsConfiguration`, `xWalkOsKeyboard`
and `xWalkOsBuild`, and compiles with `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through
the [desktop root](../xWalk-rpi5-os.md) to compose its dependencies.

## 6. Testing

```bash
ctest --test-dir build-standalone -L xWalkSettings --output-on-failure
```

`CliValuesRespectEditorTypesAndLimits` and `NumericSlider` run offscreen without hardware.

## 7. Safety and constraints

- Stop owned services before opening settings; configuration is not hot-applied.
- Slider ranges are editing aids; the owning runtime remains responsible for semantic validation and hardware
  limits. Confirm wiring and calibration before applying a new profile.

## 8. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkConfiguration](../xWalkConfiguration/xWalkConfiguration.md)
- [xWalkKeyboard](../xWalkKeyboard/xWalkKeyboard.md)

---

[Previous page](../xWalkRuntime/xWalkRuntime.md) · [Chapter index](../../index.md) · [Next page](../xWalkStub/xWalkStub.md)
