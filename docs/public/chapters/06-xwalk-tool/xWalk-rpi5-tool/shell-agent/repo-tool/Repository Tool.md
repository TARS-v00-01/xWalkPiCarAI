<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / Repository Tool

**6. xWalk tool &middot; Module 22**

<!-- xwalk-page-header:end -->

# Repository Tool

`repo-tool` contains guarded maintenance commands for the complete xWalk workspace. Its `clean-build.sh` script
finds generated CMake and Python output and removes it only after a reviewed preview and explicit confirmation.

## 1. Overview

`clean-build.sh` discovers generated CMake build trees, in-source CMake output, Python caches, test caches,
coverage files, package metadata, and Python distribution output. It verifies the xWalk workspace root before
acting (the root must contain `AGENTS.md`, `xWalk-rpi5-hw/CMakeLists.txt`, and the HAL I2C interface
`CMakeLists.txt`), requires `cmake`, and uses `cmake -E remove_directory` and `cmake -E remove` for deletion.

Discovered targets include every directory named `build` or `build-*`, directories containing a
`CMakeCache.txt`, `__pycache__` and other Python tool caches, `*.egg-info`, `.coverage` and `.coverage.*` files,
and `dist` directories that belong to a Python package.

## 2. Source location

`xWalk-rpi5-tool/shell-agent/repo-tool` - source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/shell-agent/repo-tool/
    clean-build.sh    Generated CMake and Python output finder and remover
```

## 4. Public interface

Run commands from the integrated repository root and preview every destructive operation before applying it.

List every target without removing anything:

```bash
xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh --dry-run
```

Interactive cleanup prints the same target list and requires confirmation:

```bash
xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh
```

Non-interactive automation must opt in explicitly:

```bash
xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh --yes
```

| Option | Effect |
| --- | --- |
| `--dry-run` | Lists detected CMake and Python output and exits without deleting it |
| `--yes` | Deletes the listed output without an interactive prompt |
| `--help`, `-h` | Prints usage and exits |

An unknown argument prints usage and exits with status 2.

## 5. Build

After an approved cleanup, reconfigure from the product source:

```bash
cmake --fresh -S xWalk-rpi5-hw -B build-host/xwalk-rpi5 -G Ninja -DCMAKE_BUILD_TYPE=Debug -DXWALK_ENABLE_STRICT_WARNINGS=ON
```

```bash
cmake --build build-host/xwalk-rpi5 --parallel
```

```bash
ctest --test-dir build-host/xwalk-rpi5 --output-on-failure --no-tests=error
```

## 6. Testing

Inspect the supported interface, then check syntax and ShellCheck findings without running cleanup:

```bash
xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh --help
bash -n xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh
shellcheck xWalk-rpi5-tool/shell-agent/repo-tool/clean-build.sh
```

## 7. Dependencies

Bash, GNU `find` and `sort`, and CMake.

## 8. Safety and constraints

- Do not use `--yes` until the dry-run output has been reviewed. Cleanup results cannot be recovered directly.
- The script is intended only for generated CMake and Python output; it must not remove source, Git metadata,
  credentials, submodules, downloaded dependency bundles, or user documents.
- Every `build` and `build-*` directory is a target, including generated Raspberry Pi runtime trees. Back up
  any local overrides, calibration, or service configuration kept below a build directory before cleanup and
  restore them afterwards.
- Never substitute `git clean -fdx` for this script on a live application or device checkout.

## 9. Related notes

- Shell Agent
- [Clean Build Script Guide](../../../../08-xwalk-guides/Doc/note/Clean%20Build%20Script%20Guide.md)

---

[Previous page](../quality-tool/Quality%20Tool.md) · [Chapter index](../../../index.md) · [Next page](../../../../07-xwalk-trace/index.md)
