[Documentation](../index.md) / Chapter 2

# 2. Hardware

## 2.1 Overview

The hardware integration groups the Raspberry Pi 5 robot's hardware abstractions, behavior coordinators,
Controller, shared libraries, and audio resources. Its host mode supports development without driving a robot.

**Coverage:** component responsibilities and the boundary between simulation and physical hardware.

**Prerequisites:** [Workspace](../01-xwalk-workspace/index.md); physical wiring is unnecessary for host builds.

**Start here:** use host simulation before preparing a Raspberry Pi target.

## 2.2 Components

| Component | Responsibility |
| --- | --- |
| HAL | Hardware interfaces and the simulation or platform backends used to exercise them. |
| Driver | Robot behavior built from hardware capabilities. |
| Controller | Coordination and scheduling of robot requests. |
| Library | Shared facilities used by the hardware components. |
| Audio resources | Versioned sound and music assets. |

The integration's CMake presets select a product build. Component headers and version-matched developer
documentation remain authoritative for API contracts and dependencies.

## 2.3 Build and testing

A normal host build uses simulation or software backends. Follow the
[host walkthrough](../08-xwalk-guides/index.md#81-build-and-test-on-a-host) for configuration and tests.
A successful host test does not validate wiring, calibration, actuator behavior, or physical stopping distance.

## 2.4 Hardware constraints

Identify the Raspberry Pi and Robot HAT revision before choosing a hardware profile. Do not infer one HAT
revision merely because another was not detected. Keep host and hardware build directories separate.

Before physical operation, verify power, wiring, calibration, a clear movement area, and an emergency-stop plan.
Hardware tests are opt-in. Test discovery alone must not actuate the robot.

Previous: [1. Workspace](../01-xwalk-workspace/index.md) · Next: [3. Interface](../03-xwalk-interface/index.md)
