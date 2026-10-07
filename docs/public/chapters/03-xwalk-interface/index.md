[Documentation](../index.md) / Chapter 3

# 3. Interface

## 3.1 Overview

The shared interface component defines Protocol Buffer schemas and signal registries used by communicating
parts of the product. Consistent message definitions let producers and consumers agree on their data format.

**Coverage:** message compatibility, generated bindings, and version selection.

**Prerequisites:** [Workspace](../01-xwalk-workspace/index.md) and basic familiarity with structured messages.

**Start here:** use the interface revision pinned by the integration you are building.

## 3.2 Working with messages

Keep schemas and their consumers compatible. A generated binding is derived from an interface definition;
editing generated output directly does not update that definition or its other consumers.

Use the owning component's generation instructions when changing interfaces. Rebuild affected consumers and
run their host tests before integration. Exact field definitions, signal identifiers, and generator options
belong to the version-matched component documentation.

## 3.3 Dependencies and testing

Schema generation depends on the required Protocol Buffer tools and the languages supported by each consumer.
The shared interface is used by the [Node](../05-xwalk-node/index.md) and other application components.

Test serialization, input validation, and compatible request/response behavior on the host.
A well-formed message is not, by itself, permission to operate a physical actuator.

Previous: [2. Hardware](../02-xwalk-hardware/index.md) · Next: [4. Software](../04-xwalk-software/index.md)
