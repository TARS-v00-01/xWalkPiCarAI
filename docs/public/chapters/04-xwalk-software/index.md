[Documentation](../index.md) / Chapter 4

# 4. Software

## 4.1 Overview

The desktop component provides the PiCar-X user interface and local command-line interaction.
It supports status display, configuration, and application operation through a native C++17 and Qt interface.

**Coverage:** desktop responsibilities, local interaction, and configuration care.

**Prerequisites:** [Workspace](../01-xwalk-workspace/index.md); Qt development dependencies for desktop builds.

**Start here:** select the host or standalone development profile documented for your checked-out revision.

## 4.2 User-facing responsibilities

| Area | Purpose |
| --- | --- |
| Desktop | Robot status, controls, and visual feedback. |
| Command line | Local scripted interaction with supported operations. |
| Configuration | Loading and editing settings for the selected deployment. |
| Runtime | Application lifecycle and readiness information. |
| Simulation | Development and testing without a connected robot. |

Check the component's version-matched help for supported commands. Do not assume that a desktop display or a
successful request means a physical operation has completed.

## 4.3 Configuration and testing

Back up local settings before installation or updates. Keep account data, network credentials, device pairing,
and calibration private. Examples from another machine are not verified settings for your robot.

Use the host or standalone test profile for ordinary verification. Physical operation requires the checks in
the [hardware safety guide](../08-xwalk-guides/index.md#83-before-physical-operation).

Previous: [3. Interface](../03-xwalk-interface/index.md) · Next: [5. Node](../05-xwalk-node/index.md)
