# xWalk Documentation

xWalk is a C++17 control and automation workspace for the SunFounder PiCar-X on Raspberry Pi 5.
It brings together hardware abstractions, robot control, desktop software, messaging, and development tools.

This public edition introduces the project in eight chapters. Start with the workspace and use a Linux host
for ordinary development and testing. Physical robot operation requires separate setup and safety checks.

## Read the chapters

| Chapter | What you will learn |
| --- | --- |
| [1. Workspace](01-xwalk-workspace/index.md) | Repository access, prerequisites, and reproducible checkouts. |
| [2. Hardware](02-xwalk-hardware/index.md) | The hardware integration and the roles of its components. |
| [3. Interface](03-xwalk-interface/index.md) | Shared message definitions and compatibility. |
| [4. Software](04-xwalk-software/index.md) | Desktop and command-line interaction. |
| [5. Node](05-xwalk-node/index.md) | Messaging and host versus robot execution. |
| [6. Tools](06-xwalk-tool/index.md) | Setup, builds, verification, and documentation. |
| [7. Trace](07-xwalk-trace/index.md) | Diagnostics and responsible handling of logs. |
| [8. Guides](08-xwalk-guides/index.md) | A host build walkthrough and hardware safety checklist. |

## Source and access

The [public integration repository](https://github.com/TARS-v00-01/xWalkPiCarAI) records the product layout
and selected component revisions. Building the complete product requires access to its private components.
Reading this website does not require an account.

Detailed component contracts and team administration procedures remain in the developer documentation
available to authorized contributors. This public edition contains no device-specific configuration,
internal service addresses, account instructions, or private source downloads.

**Start here:** [1. Workspace](01-xwalk-workspace/index.md).
