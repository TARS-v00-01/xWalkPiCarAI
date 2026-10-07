[Documentation](../index.md) / Chapter 8

# 8. Guides

**Coverage:** host builds, test discovery, physical safety, and troubleshooting.

**Prerequisites:** an initialized [workspace](../01-xwalk-workspace/index.md) and installed dependencies.

**Start here:** build and test on a host before considering physical operation.

## 8.1 Build and test on a host

From the integration root, after host setup, configure the hardware integration's host preset:

```bash
cmake --preset host-debug -S xWalk-rpi5-hw
```

Build the configured product:

```bash
cmake --build build-host/cmake --parallel 2
```

Run its host tests:

```bash
ctest --test-dir build-host/cmake --output-on-failure --no-tests=error
```

Use separate build directories for different target modes. A passing host suite validates its simulated
and software paths; it is not a hardware acceptance result.

## 8.2 Discover hardware tests without running them

If you already have a configured Raspberry Pi build tree, list its hardware-labelled tests:

```bash
ctest --test-dir build-rpi/cmake -N -L hardware
```

Keep `-N`: it requests discovery without execution. The command requires the build tree to exist.
This public guide does not instruct you to execute physical hardware tests.

## 8.3 Before physical operation

- Identify the Raspberry Pi model and Robot HAT revision.
- Inspect wiring and power with the equipment in a safe state.
- Preserve and verify the robot's calibration and local configuration.
- Secure the robot and clear its movement area.
- Establish an emergency-stop method and a responsible operator.
- Explicitly approve the intended physical test before running it.

Never treat simulation, a successful build, or network availability as approval to move the robot.

## 8.4 Troubleshooting a host build

If cloning fails, confirm component access before retrying. If configuration fails, check the compiler,
CMake version, dependency installation, and selected preset. If a test fails, retain the failure output and
reproduce it in the same mode before changing configuration.

Preserve local state before maintenance. Avoid resetting or cleaning an entire live checkout to fix one build.

Previous: [7. Trace](../07-xwalk-trace/index.md) · Next: [Documentation](../index.md)
