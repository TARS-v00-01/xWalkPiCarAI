[Documentation](../index.md) / Chapter 1

# 1. Workspace

## 1.1 Overview

The integration repository ties independently versioned components into one reproducible product.
Its Git submodules record exact revisions; updating a checkout should preserve those selections.

**Coverage:** source access, prerequisites, and checkout verification.

**Prerequisites:** Git, a Linux development host, and component access if you intend to build the product.

**Start here:** confirm that your account can read the required components before a recursive clone.

## 1.2 Get the workspace

For contributors who already have component access, clone the integrated workspace:

```bash
git clone --recurse-submodules https://github.com/TARS-v00-01/xWalkPiCarAI.git
```

After entering the checkout, inspect its pinned components:

```bash
git submodule status --recursive
```

A leading space means the component matches its recorded revision. A leading `-` means it is uninitialized;
a leading `+` means its checkout differs from the recorded revision. Do not substitute arbitrary branch tips
when reproducing a product build.

## 1.3 Prerequisites and configuration

The host workflow uses Linux, CMake 3.25 or newer, Ninja, a C++17 compiler, Python 3, and the product's development
libraries. Dependency installation can change the host system; review the setup command before running it.

Keep passwords, tokens, calibration, and machine-specific overrides outside committed source.
Preserve local work and configuration before updating a checkout.

## 1.4 Chapter map

The workspace combines [hardware](../02-xwalk-hardware/index.md), [interfaces](../03-xwalk-interface/index.md),
[desktop software](../04-xwalk-software/index.md), [Node](../05-xwalk-node/index.md),
[tools](../06-xwalk-tool/index.md), and [tracing](../07-xwalk-trace/index.md).
The [guides](../08-xwalk-guides/index.md) provide a host build walkthrough.

Previous: [Documentation](../index.md) · Next: [2. Hardware](../02-xwalk-hardware/index.md)
