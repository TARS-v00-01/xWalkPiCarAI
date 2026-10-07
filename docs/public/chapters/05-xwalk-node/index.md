[Documentation](../index.md) / Chapter 5

# 5. Node

## 5.1 Overview

Node supplies the product's messaging and application layer. It uses MQTT and Protocol Buffer messages to
connect application requests with robot functionality and response handling.

**Coverage:** transport responsibilities, interface compatibility, and execution modes.

**Prerequisites:** [Interface](../03-xwalk-interface/index.md) and the
[hardware overview](../02-xwalk-hardware/index.md).

**Start here:** build and verify the host configuration before selecting a robot deployment.

## 5.2 Requests and responses

Keep the sender, receiver, and shared interface revisions compatible. Distinguish a request being accepted
from its operation completing. Applications must handle rejection, transport failure, and shutdown explicitly.

Messaging settings belong to the selected deployment. Do not copy broker addresses, account stores, pairing
data, or credentials from a different environment into source or public examples.

## 5.3 Host and robot modes

HOST selects simulation. Building a HOST binary on a Raspberry Pi does not turn it into a hardware build.
Native hardware operation requires the intended Raspberry Pi configuration and separately approved physical setup.

Use the component's matching build presets and host tests. Network connectivity and software tests do not
establish that motors, sensors, or emergency stopping are safe on a particular robot.

Previous: [4. Software](../04-xwalk-software/index.md) · Next: [6. Tools](../06-xwalk-tool/index.md)
