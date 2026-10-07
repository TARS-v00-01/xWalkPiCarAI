[Documentation](../index.md) / Chapter 6

# 6. Tools

## 6.1 Overview

Development tooling supports dependency installation, build preparation, code quality, deployment, and
documentation. Select a tool for its intended environment and review operations that modify the host or robot.

**Coverage:** common setup commands, host verification, and reproducibility.

**Prerequisites:** [Workspace](../01-xwalk-workspace/index.md) and access to initialized components.

**Start here:** prepare a host build; physical deployment is a separate task.

## 6.2 Host preparation

From the integration root, the installer can prepare dependencies and configure a host build:

```bash
./install.sh --target host
```

Run the installer as your normal user. It requests elevated access for system changes when needed.
Read its help and the public repository's setup instructions before running it on a shared machine.

To build after setup and run host tests, follow [Guides](../08-xwalk-guides/index.md).

## 6.3 Verification and retained state

Use compiler checks, host tests, and documentation validation before submitting changes.
Keep generated build files and rendered documentation outside tracked source.

Before maintenance, preserve local overrides, calibration, credentials, account stores, device pairing,
and installed service settings. Removing build output must not remove operational state.
Changes to tracked defaults should remain reproducible from their owning component's source.

Previous: [5. Node](../05-xwalk-node/index.md) · Next: [7. Trace](../07-xwalk-trace/index.md)
