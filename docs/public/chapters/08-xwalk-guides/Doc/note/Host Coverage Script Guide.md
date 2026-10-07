<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / Host Coverage Script Guide

**8. xWalk guides &middot; Module 35**

<!-- xwalk-page-header:end -->

# Host Coverage Script Guide

host coverage script
configures, builds, tests, and reports host coverage in the foreground. It does
not create a detached process, install packages, request privileges,
or access Raspberry Pi hardware.

## 1. Requirements

- CMake and the build tools required by the root `coverage` preset.
- A working host compiler with GCC-compatible coverage instrumentation.
- `gcovr` available either on `PATH` or at `build-host/tools/gcovr-venv/bin/gcovr`.
- Project dependencies required by the normal host build.

The script does not download `gcovr`. Install it with the operating-system package manager or prepare the
documented repository-local virtual environment before running coverage.

## 2. Usage

Show usage without starting a build:

```sh
scripts/integration/shell-agent/quality-tool/run-host-coverage.sh --help
```

Run the complete workflow:

```sh
scripts/integration/shell-agent/quality-tool/run-host-coverage.sh run
```

`run` is the only execution action. Missing or unknown actions print usage and exit with status 2.

## 3. Workflow

The script performs these foreground steps in order:

1. Resolve the `gcovr` executable.
2. Change to the repository root resolved from the script location.
3. Remove only the dedicated `build-host/coverage` instrumentation tree.
4. Run `cmake --fresh --preset coverage`.
5. Run `cmake --build --preset coverage --parallel`.
6. Run `ctest --preset coverage`.
7. Run `gcovr` with `scripts/integration/shell-agent/env-tool/quality/gcovr.cfg`.

Any failing step stops the workflow and returns its failure status. No process is intentionally left running
in the background.

The final report enforces the reviewed regression floors: at least 75 percent
line coverage, 85 percent function coverage, and 66 percent branch coverage.
Falling below any threshold returns a non-zero status and fails CI. The current
measured baseline is 80.7, 85.2, and 66.6 percent respectively.

## 4. Output

The coverage preset uses `build-host/coverage`. The
`scripts/integration/shell-agent/env-tool/quality/gcovr.cfg` configuration prints a terminal summary and
generates:

```text
build-host/coverage/coverage.html
build-host/coverage/coverage.xml
```

The report excludes tests, generated sources, third-party content, and build
directories according to `scripts/integration/shell-agent/env-tool/quality/gcovr.cfg`. Coverage
percentages must be reported only after `gcovr` finishes successfully.

## 5. Missing gcovr

Check both supported locations:

```sh
command -v gcovr
test -x build-host/tools/gcovr-venv/bin/gcovr
```

If neither succeeds, the script exits before CMake configuration and explains that `gcovr` is required. It
does not start a background installation. Follow the host-readiness documentation for the approved local
installation method.

## 6. Safe verification

```sh
bash -n scripts/integration/shell-agent/quality-tool/run-host-coverage.sh
scripts/integration/shell-agent/quality-tool/run-host-coverage.sh --help
```

These commands do not build or run tests. The `run` action creates generated output and may take several
minutes, but it remains attached to the invoking terminal.

---

[Previous page](Hardware%20Provisioning%20Script%20Guide.md) · [Chapter index](../../index.md) · [Next page](Onboard%20MCU.md)
