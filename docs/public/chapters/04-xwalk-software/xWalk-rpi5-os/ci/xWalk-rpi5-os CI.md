<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalk-rpi5-os CI

**4. xWalk software &middot; Module 02**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-os CI

The desktop's continuous-integration entry point builds the standalone and host profiles, runs every module's
Google Tests with Qt offscreen, and verifies a staged installation.

## 1. Overview

Gerrit runs a dedicated `xwalk-os` module graph for each active desktop patch set. The graph checks the reviewed
patch, builds standalone and host modes, runs each module's Google Tests with Qt offscreen, and verifies a staged
installation. The integrated GitHub Host Quality workflow runs the same two commands.

The desktop repository also runs standalone CI on GitHub pushes and pull requests through
`.github/workflows/host-quality.yml`; it needs no private dependency credentials. A separate
`ci-log-archive.yml` workflow archives the already-masked logs of completed quality runs without checking out
source. Host dependency checks run in Gerrit and in the integrated repository against its exact Trace revision.

Publication uses Gerrit review, verification and submission before GitHub replication. The shared Tool
repository owns the project registration, mirror mapping and uplift routing into `xWalkPiCarAI`. The desktop
owns this build, test and install entry point.

## 2. Source location

`xWalk-rpi5-os/ci` - source directory

## 3. Directory layout

```text
xWalk-rpi5-os/ci/
    run-host-ci.sh    Configure, build, test, stage-install and smoke-check one profile (standalone or host)
```

## 4. Public interface

`run-host-ci.sh [standalone|host]` (default `standalone`; any other value exits with status 2):

1. Exports `QT_QPA_PLATFORM=offscreen` and a short private `TMPDIR` from `mktemp -d /tmp/xwalk-os-ci.XXXXXX`,
   avoiding Unix-domain socket path limits when the shared runner has a long `TMPDIR`. The directory is removed
   when the job exits.
2. Unsets `XWALK_OS_LIVE_TEST_CONFIG`, `XWALK_OS_LIVE_VIDEO` and `XWALK_OS_LIVE_START_ONLY`, so physical-device
   tests stay disabled even on a hardware runner.
3. Configures `build-ci-<mode>` with `-DXWALK_OS_MODE=<mode> -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON`,
   builds with `XWALK_CI_JOBS` jobs (default two) and runs `ctest --output-on-failure --no-tests=error`.
4. Installs into `build-ci-<mode>/stage` with prefix `/usr` and checks the executable
   `usr/bin/xwalk-pi5car`, the non-empty `applications/xwalk-pi5car.desktop`, `xwalk-pi5car/desktop.cfg` and
   `xwalk-pi5car/robot.cfg`, then runs the staged `xwalk-pi5car --help`.

## 5. Build

Install CMake 3.20+, a C++17 compiler, Qt 5.15 Widgets, Network and Test development packages and Google Test
(`qtbase5-dev` and `libgtest-dev` on Ubuntu). Host mode also requires the integration's submitted
`xWalk-rpi5-trace` revision. Standalone mode requires no sibling repository.

```bash
bash ci/run-host-ci.sh standalone
bash ci/run-host-ci.sh host
```

Results and staged artifacts remain under `build-ci-standalone` and `build-ci-host`.

## 6. Safety and constraints

- Real Pi deployment and movement checks remain explicit, supervised hardware tests; CI never enables them.
- Commit subjects follow `[xWalk-087][OS] Summary`, followed by `[x]` change bullets, validation results and the
  Gerrit hook-generated `Change-Id`.

## 7. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkTest](../xWalkTest/xWalkTest.md)

---

[Previous page](../xWalk-rpi5-os.md) · [Chapter index](../../index.md) · [Next page](../xWalkCli/xWalkCli.md)
