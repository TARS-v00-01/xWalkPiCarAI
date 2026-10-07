[xWalk documentation](../index.md) / Chapter 5

# 5. Node

## 1. Section overview

Node services, messaging, and host-side execution.

## 2. Coverage

- 31 module and guide pages, listed below.
- Source locations, interfaces, build and configuration information, testing, and safety constraints.

## 3. Prerequisites

- Read the workspace and interface chapters before configuring a service.
- Private component access is needed for source builds; no account is needed to read these notes.

**Start here:** [xWalk-rpi5-node](xWalk-rpi5-node/xWalk-rpi5-node.md).

## 4. Modules and guides

- [xWalk-rpi5-node](xWalk-rpi5-node/xWalk-rpi5-node.md): `xWalk-rpi5-node` is the Raspberry Pi 5 node component of xWalk. It contains the MQTT IoT node, which builds the `xwalk` executable, and the separate Traffic Controller (`xWalkTrafCtrl`). The traffic process.
- [xWalkIoT](xWalk-rpi5-node/xWalkIoT/xWalkIoT.md): `xWalkIoT` is the CMake project (`xWalkNode`) that builds the C++17 `xwalk` executable. `xwalk` sends and receives binary IW Protobuf messages through HiveMQ Cloud over verified TLS on port 8883. RX and TX share one.
- [Raspberry Pi 5 CSI Camera Deployment](xWalk-rpi5-node/xWalkIoT/xWalkDeploy/rpi5-csi/Raspberry%20Pi%205%20CSI%20Camera%20Deployment.md): `xWalkDeploy/rpi5-csi` holds the reviewed deployment templates for a Raspberry Pi 5 with Robot HAT v4 and a CSI camera: a configuration fragment with GStreamer camera pipelines and the native `run-xwalk` launcher..
- [Future Raspberry Pi GPB verification](xWalk-rpi5-node/xWalkIoT/xWalkDeploy/rpi5-csi/GPB_VERIFICATION.md): This checklist has **not** been run for these changes. It requires a connected, reviewed Pi 5 / Robot HAT setup, a clear motion area, verified MQTT TLS configuration, and explicit operator permission. Use the.
- [xWalkMqttClient](xWalk-rpi5-node/xWalkIoT/xWalkMqttClient/xWalkMqttClient.md): `xWalkMqttClient` is the MQTT receive (RX) library of the xWalk node. `HiveMQClient` provides exact-topic subscriptions and serial message callbacks over the verified TLS connection owned by its `HiveMQInit` member.
- [xWalkMqttCommon](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttCommon.md): `xWalkMqttCommon` groups the shared MQTT building blocks of the xWalk node: signal types, bounded message queues, Protobuf JSON conversion and the node runtime. Each child is a CMake module within the node repository.
- [xWalkMqttJson](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttJson/xWalkMqttJson.md): `xWalkMqttJson` converts bounded JSON input into native IW Protobuf (GPB) messages, validates native GPB payloads before transport and converts validated GPB back into JSON for terminal consumers.
- [xWalkMqttNode](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md): `xWalkMqttNode` is the xWalk node runtime: command-line parsing, generated signal lookup, signal-qualified topic construction, foreground subscription, typed request publication with reply waits, the process-mode.
- [xWalkModule](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttNode/xWalkModule/xWalkModule.md): `xWalkModule` builds the Node-only `xwalk` terminal of the `module` composition. It validates one JSON message through the production codecs and owned queues, prints compact JSON and exits, without MQTT, the.
- [xWalkMqttQueue](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttQueue/xWalkMqttQueue.md): `xWalkMqttQueue` provides the bounded, thread-safe, in-process FIFOs of the xWalk node: three independent received-message queues for Requests, confirmations (CFM) and rejections (REJ), plus a separate outgoing.
- [xWalkMqttTypes](xWalk-rpi5-node/xWalkIoT/xWalkMqttCommon/xWalkMqttTypes/xWalkMqttTypes.md): `xWalkMqttTypes` is the header-only interface target that exposes the shared `xWalksSignal` send-argument type, the MQTT queue limits and the process Controller send macros to node components.
- [xWalkMqttInit](xWalk-rpi5-node/xWalkIoT/xWalkMqttInit/xWalkMqttInit.md): `xWalkMqttInit` owns the MQTT connection foundation of the xWalk node: runtime configuration loading, netrc credential lookup, verified TLS settings, the Eclipse Paho handle, synchronization, reconnect state and the.
- [xWalkConfig](xWalk-rpi5-node/xWalkIoT/xWalkMqttInit/xWalkConfig/xWalkConfig.md): `xWalkConfig` under `xWalkMqttInit` holds the tracked MQTT runtime inputs of the xWalk node: the connection template, the node help text, the minimal legacy move sample, the sound-sample stager and one native.
- [xWalkMqttServer](xWalk-rpi5-node/xWalkIoT/xWalkMqttServer/xWalkMqttServer.md): `xWalkMqttServer` is the MQTT transmit (TX) library of the xWalk node. `HiveMQServer` publishes encoded GPB requests and responses through the caller-owned connection of a `HiveMQClient`; it has no subscription or.
- [xWalkReceiver](xWalk-rpi5-node/xWalkIoT/xWalkAgent/xWalkReceiver/xWalkReceiver.md): `xWalkReceiver` is the receiving side of the xWalk node Agent. It decodes the 38 IW request messages into generated plain structures for the Controller interface, encodes and sends confirmations (CFM) and rejections.
- [xWalkTransmitter](xWalk-rpi5-node/xWalkIoT/xWalkAgent/xWalkTransmitter/xWalkTransmitter.md): `xWalkTransmitter` is the sending side of the xWalk node Agent. `XWalkTransmitter` encodes all 38 generated request structures with the native IW Protobuf classes, stamps their routing identity, publishes them.
- [xWalkTrafCtrl](xWalk-rpi5-node/xWalkTrafCtrl/xWalkTrafCtrl.md): `xWalkTrafCtrl` is a native C++17 traffic-announcement application. It captures local video or Raspberry Pi 5 CSI frames, runs the trained crosswalk detector and Random Forest, validates IW Protobuf observations,.
- [xWalkAnnouncement](xWalk-rpi5-node/xWalkTrafCtrl/xWalkAnnouncement/xWalkAnnouncement.md): `xWalkAnnouncement` turns one validated traffic observation into a grounded LLM prompt, calls the shared native language-model coordinator, validates the generated advisory and emits the `TRAFCTRL` announcement traces.
- [xWalkCameraSvc](xWalk-rpi5-node/xWalkTrafCtrl/xWalkCameraSvc/xWalkCameraSvc.md): `xWalkCameraSvc` is the C++ camera owner for concurrent traffic and IoT camera consumers. It opens the CSI camera (or, on a host, a local video) once and publishes JPEG snapshots by atomic rename into a private.
- [xWalkCapture](xWalk-rpi5-node/xWalkTrafCtrl/xWalkCapture/xWalkCapture.md): `xWalkCapture` provides native OpenCV frame acquisition for the traffic controller: a local video or still image on the host, or the Raspberry Pi CSI camera through GStreamer or the shared camera feed, with frame.
- [xWalkConfig](xWalk-rpi5-node/xWalkTrafCtrl/xWalkConfig/xWalkConfig.md): `xWalkConfig` holds the traffic controller's tracked runtime configuration: the default JSON profile, the host test and Raspberry Pi CPU overlays, the MQTT connection file, the generated build-header template and the.
- [xWalkConfiguration](xWalk-rpi5-node/xWalkTrafCtrl/xWalkConfiguration/xWalkConfiguration.md): `xWalkConfiguration` loads the traffic controller's JSON configuration, applies command-line precedence, resolves paths and validates every setting before the session starts.
- [xWalkInput](xWalk-rpi5-node/xWalkTrafCtrl/xWalkInput/xWalkInput.md): `xWalkInput` holds the traffic controller's default local evaluation input, the `xWalkTrafficTest.mp4` clip used by host replay and by the camera-service host tests.
- [xWalkModel](xWalk-rpi5-node/xWalkTrafCtrl/xWalkModel/xWalkModel.md): `xWalkModel` runs native crosswalk-risk inference: YOLO detection through OpenCV DNN (ONNX) or the opt-in Raspberry Pi 5 Hailo-8 backend, six-feature extraction, and exported scikit-learn Random Forest.
- [xWalkPathVision](xWalk-rpi5-node/xWalkTrafCtrl/xWalkPathVision/xWalkPathVision.md): `xWalkPathVision` provides camera path assessment: `PathVision` estimates likely open, likely blocked or unknown from BGR camera pixels. It is an experimental, advisory-only heuristic and never takes part in motor.
- [xWalkProtocol](xWalk-rpi5-node/xWalkTrafCtrl/xWalkProtocol/xWalkProtocol.md): `xWalkProtocol` validates IW `TrafficObservation` messages, reads bounded Protobuf observations and legacy JSON prediction reports, and produces JSONL evaluation records. It also owns the CMake step that generates.
- [xWalkProximity](xWalk-rpi5-node/xWalkTrafCtrl/xWalkProximity/xWalkProximity.md): `xWalkProximity` is the traffic controller's front proximity stop client. On the Raspberry Pi it polls the hardware owner's dedicated local safety endpoint independently of camera capture, inference, MQTT and LLM.
- [xWalkPublisher](xWalk-rpi5-node/xWalkTrafCtrl/xWalkPublisher/xWalkPublisher.md): `xWalkPublisher` serializes traffic advisories into the existing IW `SoundReq` with operation `ANNOUNCE`, broadcasts classified traffic observations, and delivers both through the shared `HiveMQClient`/`HiveMQServer`.
- [xWalkRuntime](xWalk-rpi5-node/xWalkTrafCtrl/xWalkRuntime/xWalkRuntime.md): `xWalkRuntime` composes the native traffic session: capture, path vision, model inference, evaluation JSONL, risk-level announcement pacing, observation broadcasts, camera-qualified proximity incidents and local speech.
- [xWalkTest](xWalk-rpi5-node/xWalkTrafCtrl/xWalkTest/xWalkTest.md): `xWalkTest` is the traffic controller's shared host-test infrastructure: a small fixture library and the `xwalk_traffic_add_gtest` CMake helper that registers each submodule's GoogleTest executable consistently.
- [xWalkTrafCtrl Host Dependencies](xWalk-rpi5-node/xWalkTrafCtrl/cmake/host-dependencies/xWalkTrafCtrl%20Host%20Dependencies.md): This standalone CMake project builds the pinned native OpenCV 4.12.0 dependency used by `xWalkTrafCtrl` into an isolated prefix inside the module, without replacing the system OpenCV installation.

## 5. Table of contents

- [Section overview](#1-section-overview)
- [Coverage](#2-coverage)
- [Prerequisites](#3-prerequisites)
- [Modules and guides](#4-modules-and-guides)

---

[Previous chapter](../04-xwalk-software/index.md) · [Next chapter](../06-xwalk-tool/index.md)

[Previous page](../04-xwalk-software/index.md) · [Chapter index](index.md) · [Next page](xWalk-rpi5-node/xWalk-rpi5-node.md)
