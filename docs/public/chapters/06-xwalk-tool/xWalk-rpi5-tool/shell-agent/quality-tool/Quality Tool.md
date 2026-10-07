<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [6. xWalk tool](../../../index.md) / Quality Tool

**6. xWalk tool &middot; Module 21**

<!-- xwalk-page-header:end -->

# Quality Tool

`quality-tool` contains the shared host-safe quality wrappers used locally, by GitHub Actions, and by Gerrit and
Zuul: sanitizers, coverage, Valgrind, Clang Static Analyzer, ShellCheck, and dependency inspection.

## 1. Overview

Run commands from the integrated repository root. The wrappers configure the product from `xWalk-rpi5-hw` and keep
generated output below `build-host`. These checks never authorize Raspberry Pi, Robot HAT, motor, servo, GPIO,
camera commissioning, or other physical hardware operations.

| Status | Exit status | Meaning |
|---|---:|---|
| `PASSED` | `0` | The check completed without a disallowed finding. |
| `FAILED` | `1` | A build, test, probe, threshold, or analysis check failed. |
| `SKIPPED_MISSING_TOOL` | `2` | A required executable is unavailable. |
| `BLOCKED_BY_ENVIRONMENT` | `3` | Runtime restrictions prevent a valid check. |

Do not convert missing tools, restricted sanitizer initialization, timeouts, or
analysis findings into success. LSan and TSan may require a native Linux runner
that permits their runtime initialization.

## 2. Source location

`xWalk-rpi5-tool/shell-agent/quality-tool` -
source directory

## 3. Directory layout

```text
xWalk-rpi5-tool/shell-agent/quality-tool/
    check-host-quality-dependencies.sh   Reports tool availability and versions without installing anything
    install-github-host-packages.sh      GitHub Actions-only package installer using the official Ubuntu archive
    run-host-sanitizer.sh                asan, lsan, and tsan modes with negative probes
    run-host-coverage.sh                 GCC or Clang coverage in clean build trees
    run-host-valgrind.sh                 CTest MemCheck over focused non-sanitized Debug tests
    validate-valgrind-descriptors.sh     Accepts only inherited descriptors in Valgrind reports
    run-clang-static-analyzer.sh         scan-build with --status-bugs
    run-host-shellcheck.sh               ShellCheck over project-owned shell scripts
    run-host-quality.sh                  Combined suite preserving the strongest non-passing status
    test/
        validate-valgrind-descriptors-test.sh   Descriptor validator host test
```

## 4. Public interface

### Run individual checks

AddressSanitizer and UndefinedBehaviorSanitizer:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh asan
```

LeakSanitizer and ThreadSanitizer use separate GCC runtimes and build
directories. ThreadSanitizer disables address-space randomization for only its
probe and test processes so the runtime can reserve its shadow-memory layout:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh lsan
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-sanitizer.sh tsan
```

Generate GCC or Clang coverage reports:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-coverage.sh run gcc
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-coverage.sh run clang
```

Run memory, static-analysis, and shell checks:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-valgrind.sh
xWalk-rpi5-tool/shell-agent/quality-tool/run-clang-static-analyzer.sh
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-shellcheck.sh
```

### Run the combined suite

The combined wrapper runs dependency inspection, all three sanitizer modes,
GCC coverage, Valgrind, Clang Static Analyzer, and ShellCheck while preserving
the strongest non-passing exit status:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/run-host-quality.sh
```

This is resource intensive. CI normally schedules independent jobs through
`xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh` instead.

### Parallel stress verification

The shared `stress-tests` job runs up to four tests concurrently, capped by
`nproc`, with all 20 `until-fail` repetitions retained for each test. One CTest
scheduler honors `RUN_SERIAL`, fixture dependencies and resource locks; aggregate
tests that change shared trace metadata remain exclusive. Compiler, sanitizer
and coverage stages keep their separate build directories and existing order.
This applies to Gerrit, GitHub Actions and Zuul through the same dispatcher.

Override the stress worker count for a smaller runner or a serial diagnostic run:

```bash
XWALK_CI_STRESS_WORKERS=1 xWalk-rpi5-tool/shell-agent/gerrit-tool/run-host-ci-job.sh stress-tests
```

The override accepts integers from 1 to 999, capped by available CPUs. Invalid
values fail before building. The explicit worker count overrides inherited
`CTEST_PARALLEL_LEVEL`; failed tests still fail the job. Parallelism does not
reduce the test set, repetition count or sanitizer/coverage requirements.

### Reports

| Check | Report location |
|---|---|
| GCC coverage | `build-host/coverage/coverage.html` |
| Clang coverage | `build-host/coverage-clang/html/index.html` |
| Clang Static Analyzer | `build-host/clang-analyzer/reports` |
| Valgrind | `build-host/valgrind/Testing/Temporary` and CTest memcheck output |
| Sanitizers | Their respective build directory and `ctest.log` when retained |

The complete policy, prerequisites, coverage floors, probe behavior, and CI constraints are documented in the
[C++ Quality Tool](../../cpp-tool/quality/C++%20Quality%20Tool.md) note.

## 5. Configuration

Coverage, Clang-Tidy, and Cppcheck settings live in `xWalk-rpi5-tool/shell-agent/env-tool/quality`. The
wrappers use the `xWalk-rpi5-hw` CMake presets for their dedicated build directories.

## 6. Testing

The Valgrind descriptor validator can be tested independently:

```bash
bash xWalk-rpi5-tool/shell-agent/quality-tool/test/validate-valgrind-descriptors-test.sh
```

Lint the wrappers themselves with `run-host-shellcheck.sh`.

## 7. Dependencies

Inspect tool availability and versions without installing or changing the
host:

```bash
xWalk-rpi5-tool/shell-agent/quality-tool/check-host-quality-dependencies.sh
```

The command reports missing tools and prints the reviewed Ubuntu 24.04 package
installation command. Package installation remains an explicit administrator
action.

GitHub Actions jobs install their dependencies through
`install-github-host-packages.sh`. The helper replaces the Azure-hosted Ubuntu
mirror with the official HTTPS Ubuntu archive before updating package indexes.
It refuses to run outside GitHub Actions so local package sources cannot be
changed accidentally.

## 8. Safety and constraints

- All wrappers are host-only.
- `install-github-host-packages.sh` refuses to run outside GitHub Actions.
- A missing tool or blocked runtime is never reported as passed.

## 9. Related notes

- [C++ Quality Tool](../../cpp-tool/quality/C++%20Quality%20Tool.md)
- Gerrit Shell Tool
- Environment Tool
- Shell Agent

---

[Previous page](../deploy-tool/HARDWARE_INDEPENDENT_READINESS.md) · [Chapter index](../../../index.md) · [Next page](../repo-tool/Repository%20Tool.md)
