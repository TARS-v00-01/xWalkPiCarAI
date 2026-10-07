<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkPublisher

**5. xWalk node &middot; Module 28**

<!-- xwalk-page-header:end -->

# xWalkPublisher

`xWalkPublisher` serializes traffic advisories into the existing IW `SoundReq` with operation `ANNOUNCE`,
broadcasts classified traffic observations, and delivers both through the shared
`HiveMQClient`/`HiveMQServer` transport with non-retained QoS 1 publication.

## 1. Overview

`announcementRequest` fills matching nested and outer routing identities from the `mqtt` settings, a unique
announcement ID, the `Traffic advisory` title and the cleaned LLM body. `publishAnnouncement` serializes and sends
the request once on the existing request-topic base plus `/8216` (`CXX_XWALK_CMD_SOUND_REQ`). `publishObservation`
broadcasts every validated observation, including SAFE results, on
`xwalk/xwalk-pi5-controller/traffic/observation`. `publishSafetyAnnouncement` always broadcasts proximity safety
text with an explicitly simulated Halmstad location, reusing one location per session when requested.

The sender address `auto` uses the existing node IPv4 resolver (`xHal_Rpi5CarMqttNodeServerAddress.cpp`) and its
`XWALK_SERVER_IP` override; an explicit IPv4 address is also accepted. `server_ip` `0.0.0.0` broadcasts to all
connected nodes.

`MqttTransport` selects this process's connection file before the shared client starts: it sets
`HIVEMQ_CONFIG_FILE` from `XWALK_TRAFCTRL_MQTT_CONFIG_FILE`, or from the build-configured traffic file, so that an
inherited IoT value cannot redirect the process. When `XWALK_TRAFCTRL_NETRC_FILE` is set it selects dedicated
credentials through `HIVEMQ_NETRC_FILE`; otherwise the normal netrc lookup applies. The environment change is
local to the traffic process. The transport connects on demand and sends once, without automatic publication
retries.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkPublisher` -
source directory

## 3. Directory layout

```text
xWalkPublisher/
    CMakeLists.txt                          Library, shared MQTT server inclusion and GoogleTest registration
    include/xWalkPublisher.h                Transports and publication functions
    src/xWalkPublisher.cpp                  SoundReq construction, routing and delivery
    test/include/xWalkPublisherTestSupport.h  CaptureTransport test double
    test/src/xWalkPublisherTest.cpp         Host GoogleTests
    test/src/xWalkPublisherTestSupport.cpp  CaptureTransport implementation
```

## 4. Public interface

Declared in
`xWalkPublisher.h`
in namespace `xwalk::traffic`:

| Symbol | Contract |
| --- | --- |
| `AnnouncementTransport` | Abstract non-retained QoS 1 `send(topic, payload)`; host capture needs no broker |
| `MqttTransport` | Owns a `HiveMQClient` and a `HiveMQServer` that borrows it for the object's lifetime |
| `validateAnnouncementRouting(settings)` | Validate routing before a session starts |
| `announcementRequest(settings, body, id)` | Build the IW `SoundReq` ANNOUNCE contract |
| `publishObservation(value, transport)` | Broadcast one validated observation; false on delivery failure |
| `publishAnnouncement(settings, body, transport)` | Send an advisory once; throws on delivery failure |
| `publishSafetyAnnouncement(settings, body, transport, location)` | Broadcast safety text to every node |

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). Adds
[xWalkMqttServer](../../xWalkIoT/xWalkMqttServer/xWalkMqttServer.md) when its target does not yet exist, compiles
the node IPv4 resolver source from `xWalkMqttNode`, and links publicly to `xWalkAnnouncement` and
`xWalkMqttServer`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkPublisher --output-on-failure
```

`xWalkPublisherGoogleTest` (labels `host;gtest;xWalkPublisher`) runs with `XWALK_SERVER_IP=192.0.2.55` and decodes
captured publications through the real IW schema. It covers the existing sound signal and routing, validation
before sending and failure propagation, the automatic sender override, process-owned connection configuration,
device-independent risk broadcasts, safety broadcasts and per-session location reuse. Tests never connect to a
broker or trigger speaker hardware.

## 7. Dependencies

- [xWalkAnnouncement](../xWalkAnnouncement/xWalkAnnouncement.md) and
  [xWalkProtocol](../xWalkProtocol/xWalkProtocol.md).
- [xWalkMqttServer](../../xWalkIoT/xWalkMqttServer/xWalkMqttServer.md) and its verified-TLS client, Paho MQTT C and
  OpenSSL.
- [xWalkMqttNode](../../xWalkIoT/xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md) IPv4 resolver source.

## 8. Safety and constraints

- Broker completion does not confirm playback; the publisher does not wait for `SoundCfm` or `SoundRej`.
- Failed or uncertain delivery raises a module error without an application-level retry. QoS 1 may redeliver the
  same announcement ID.
- Offline clients do not receive non-retained broadcasts.
- Credentials are never placed in traffic JSON; only the netrc credential contract is configured.

## 9. Related notes

- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkProximity/xWalkProximity.md) · [Chapter index](../../../index.md) · [Next page](../xWalkRuntime/xWalkRuntime.md)
