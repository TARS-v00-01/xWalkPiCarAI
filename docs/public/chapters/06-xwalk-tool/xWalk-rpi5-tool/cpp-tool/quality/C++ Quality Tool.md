<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / C++ Quality Tool

**6. xWalk tool &middot; Module 02**

<!-- xwalk-page-header:end -->

# C++ Quality Tool

The C++ quality tool stores the intentionally defective sanitizer probes and documents the host quality
instrumentation: sanitizers, coverage, Valgrind, Clang Static Analyzer, and ShellCheck. These checks execute
only host-safe tests. They do not validate Raspberry Pi, Robot HAT, camera, sensor, servo, or motor hardware.

## 1. Overview

The quality wrappers live in `xWalk-rpi5-tool/shell-agent/quality-tool`; this directory provides the negative
verification probes they compile and run before the real test suites. Every wrapper uses these result terms:

| Result | Exit status | Meaning |
| --- | --- | --- |
| `PASSED` | 0 | The tool executed fully and found no disallowed issue |
| `FAILED` | 1 | The tool executed and found a defect, build failure, or test failure |
| `SKIPPED_MISSING_TOOL` | 2 | A required executable was not installed |
| `BLOCKED_BY_ENVIRONMENT` | 3 | The executable exists but cannot initialize in the runtime |

## 2. Source location

`xWalk-rpi5-tool/cpp-tool/quality` - source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/cpp-tool/quality/
    probes/
        xWalkLeakSanitizerProbe.cpp     Intentional leak that LeakSanitizer must reject
        xWalkThreadSanitizerProbe.cpp   Intentional two-thread data race that ThreadSanitizer must reject
```

The probes are verification fixtures. They are not registered in the normal passing CTest suite.

## 4. Public interface

### Sanitizers

ASan/UBSan, LSan verification, and TSan have separate build directories. TSan must never be combined with ASan,
LSan, UBSan, or coverage because their runtime instrumentation and shadow-memory layouts are incompatible.
Successful compilation alone is not a sanitizer pass; the instrumented executable and the appropriate negative
verification probe must run.

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh asan
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh lsan
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh tsan
```

The ASan/UBSan mode deliberately uses `detect_leaks=0`; it is the separate mode usable for ordinary sanitizer
tests and restricted fuzz environments. The LSan mode uses `detect_leaks=1`, first verifies that the
intentional leak probe is rejected, then runs the complete project suite. LeakSanitizer cannot operate while the
process is traced by GDB, `strace`, ptrace-based wrappers, or some restricted containers. Such startup failures
are `BLOCKED_BY_ENVIRONMENT`, never passed.

TSan first records `/proc/sys/kernel/randomize_va_space`, verifies the intentional race probe, then runs focused
streaming, observability, shutdown, simulator, and lifecycle tests with `history_size=7`. Shadow-memory mapping
failures are also `BLOCKED_BY_ENVIRONMENT`. The scripts never change ASLR or sysctl settings.

### Coverage

GCC and Clang coverage use clean, independent build trees:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-coverage.sh run gcc
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-coverage.sh run clang
```

The measured GCC baseline on 2026-08-11 is 80.7 percent lines, 85.2 percent functions, and 66.6 percent
branches. Regression floors are 75, 85, and 66 percent respectively in
`gcovr.cfg`. The report includes all
project production sources while excluding generated code, tests, third-party sources, and non-executable
assets. Important exercised paths include configuration rejection, watchdog and emergency stops, camera loss and
EOF, streaming shutdown and disconnects, simulator I2C faults, and bounded observability. Hardware-only backend
failure branches and several host composition branches remain uncovered. Branch coverage is not yet 75 percent.

Open the GCC detailed report at `build-host/coverage/coverage.html`. GCC also produces Cobertura XML and JSON.
Clang produces a terminal summary, HTML under `build-host/coverage-clang/html/index.html`, LLVM profile data,
and JSON export.

### Valgrind and static analysis

Run focused non-sanitized Debug tests with CTest MemCheck:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-valgrind.sh
```

The wrapper checks leaks, all leak kinds, origins, invalid memory access, uninitialized values, and open
descriptors. It excludes long soak and fuzz workloads. CTest and CI runners may pass a variable number of report
and command descriptors to each child. The wrapper accepts descriptors that Valgrind names and marks as
inherited from the parent, while rejecting every non-standard descriptor opened by the tested process and left
open at exit. CTest labels all `still reachable` records as potential leaks; the wrapper separately rejects
nonzero definite, indirect, or possible loss and nonzero Valgrind error summaries. No suppression file is
provided because no demonstrated external-library false positive has been accepted.

Run the Clang Static Analyzer in its clean build directory:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-clang-static-analyzer.sh
```

Human-readable HTML and machine-readable plist reports are retained below `build-host/clang-analyzer/reports`.
`scan-build --status-bugs` makes actionable findings fail the command.

### ShellCheck and combined verification

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-shellcheck.sh
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-quality.sh
```

ShellCheck uses null-delimited discovery, so paths containing spaces are safe. It excludes only generated build
trees, generated source, third-party code, and reviewed architecture-specific dependency bundles. The combined
command runs all modes and preserves the strongest non-passing result: `FAILED` takes precedence, otherwise the
first other non-passing status is kept.

## 5. Configuration

Analyzer, Cppcheck, and coverage settings are stored in `xWalk-rpi5-tool/shell-agent/env-tool/quality`
(`.clang-tidy`, `.cppcheck-suppressions`, and `gcovr.cfg`). The wrappers use the `xWalk-rpi5-hw` CMake presets
for their dedicated build trees under `build-host`.

## 6. Testing

CI uses the same wrappers. LSan and TSan jobs require a native Linux runner whose security policy permits
sanitizer initialization; a restricted runner must report the environment block instead of converting it into
success.

## 7. Dependencies

Repository scripts report missing tools but never install them. Install the reviewed tool set manually on an
Ubuntu 24.04 host or VM:

```bash
sudo apt update
sudo apt install -y ansible-core clang clang-format clang-tools llvm gcovr lcov python3-yaml valgrind shellcheck
```

Inspect paths, versions, and availability without changing the machine:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/check-host-quality-dependencies.sh
```

## 8. Safety and constraints

- All modes are host-only and never access physical hardware.
- The probes are intentionally defective and must never be added to a passing test target.
- A skipped or blocked tool must never be reported as passed.

## 9. Related notes

- [Quality Tool](../../shell-agent/quality-tool/Quality%20Tool.md)
- [Fuzz Testing Tool](../fuzz/Fuzz%20Testing%20Tool.md)
- Gerrit Shell Tool
- Gerrit Tool
- xWalk-rpi5-tool

---

[Previous page](../../../index.md) · [Chapter index](../../../index.md) · [Next page](../fuzz/Fuzz%20Testing%20Tool.md)
