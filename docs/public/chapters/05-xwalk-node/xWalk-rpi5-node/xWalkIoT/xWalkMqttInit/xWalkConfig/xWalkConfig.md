<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [5. xWalk node](../../../../index.md) / xWalkConfig

**5. xWalk node &middot; Module 13**

<!-- xwalk-page-header:end -->

# xWalkConfig

`xWalkConfig` under `xWalkMqttInit` holds the tracked MQTT runtime inputs of the xWalk node: the connection
template, the node help text, the minimal legacy move sample, the sound-sample stager and one native Protobuf
JSON sample for every Request, confirmation (CFM) and Reject signal.

## 1. Overview

Each sample file contains one native Protobuf JSON message and can be passed directly to `xwalk json` or used by
`xwalk publish`. The files cover all 38 Request signals and their matching 38 CFM and 38 Reject signals. Each
family is grouped into `service`, `vehicle`, `vision` and `voice` directories. CMake copies these directories to
`<build-directory>/config` during configuration and refreshes them on reconfiguration. Copy a sample outside
these source directories before customizing it.

Sample data illustrates the IW schema; it is not a record of a completed hardware operation. Binary fields use
Protobuf JSON base64 (`AQI=` represents bytes `01 02`), enums use their schema names, and nested fields remain
nested objects. Paths in sound and configuration examples are placeholders for resources on the target machine.

## 2. Source location

`xWalk-rpi5-node/xWalkIoT/xWalkMqttInit/xWalkConfig` —
source directory

## 3. Directory layout

```text
xWalkConfig/
    xWalkMqttClient.conf     Connection template: broker host, client ID and CA file keys; no credentials
    xWalkMqttNodeHelp.json   xwalk CLI help text; @XWALK_MQTT_CONFIG_FILE@ is substituted by CMake
    xWalkMqttMove.json       Original minimal MoveReq example kept for compatibility and the JSON unit test
    stage-sound-sample.py    Stages a PCM16 horn derivative and the absolute-path SoundReq sample
    request/                 38 Request samples in service, vehicle, vision and voice directories
    cfm/                     38 CFM samples in the same functional directories
    reject/                  38 Reject samples in the same functional directories
```

Sample files are named `<family>/<functionality>/xWalkMqtt<Stem><Req|Cfm|Rej>.json`, for example
`request/vehicle/xWalkMqttMoveReq.json`
(vehicle).
The functionality of each stem is assigned by `xWalkMqttFunctions.json` in
[xWalkMqttNode](../../xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md); the registry generator rejects a missing
sample.

## 4. Public interface

### Signal and file index

The CFM and Reject signals of each stem replace the `_REQ` suffix with `_CFM` and `_REJ`. Request IDs come from
the generated `xHal_Rpi5CarGpbSigReq.h`.

### Service

| Stem | Request signal | Request ID |
| --- | --- | --- |
| `LifeMove` | `XWALK_LIFE_MOVE_REQ` | `0x2090` |
| `Health` | `XWALK_HEALTH_REQ` | `0x2091` |
| `Version` | `XWALK_VERSION_REQ` | `0x2092` |
| `Unknown` | `XWALK_CNTRL_UNKNOWN_REQ` | `0x2000` |
| `Help` | `XWALK_CNTRL_HELP_REQ` | `0x2001` |
| `Spi` | `XWALK_CNTRL_SPI_REQ` | `0x2002` |
| `Doctor` | `XWALK_CNTRL_DOCTOR_REQ` | `0x2003` |
| `AppCtrl` | `XWALK_CNTRL_APP_CONTROL_REQ` | `0x2012` |
| `TraceEnable` | `XWALK_TRACE_ENABLE_REQ` | `0x2093` |

### Vehicle

| Stem | Request signal | Request ID |
| --- | --- | --- |
| `I2c` | `XWALK_I2C_RPI5CAR_REQ` | `0x1081` |
| `ServoZero` | `XWALK_CNTRL_SERVO_ZEROING_REQ` | `0x2004` |
| `Move` | `XWALK_CNTRL_MOVE_REQ` | `0x200A` |
| `Keyboard` | `XWALK_CNTRL_KEYBOARD_CONTROL_REQ` | `0x200B` |
| `Avoid` | `XWALK_CNTRL_AVOID_OBSTACLES_REQ` | `0x200C` |
| `Cliff` | `XWALK_CNTRL_CLIFF_DETECTION_REQ` | `0x200D` |
| `Turn` | `XWALK_CNTRL_TURN_REQ` | `0x2013` |
| `Camera` | `XWALK_CNTRL_CAMERA_REQ` | `0x2014` |
| `Sensor` | `XWALK_CNTRL_SENSOR_REQ` | `0x2015` |
| `LineTrack` | `XWALK_CNTRL_LINE_TRACK_REQ` | `0x2016` |
| `SelfDrive` | `XWALK_CNTRL_SELF_DRIVE_REQ` | `0x2017` |
| `Calibrate` | `XWALK_CNTRL_CALIBRATE_REQ` | `0x201F` |

### Vision

| Stem | Request signal | Request ID |
| --- | --- | --- |
| `Vision` | `XWALK_CNTRL_COMPUTER_VISION_REQ` | `0x2005` |
| `VideoRecord` | `XWALK_CNTRL_RECORD_VIDEO_REQ` | `0x2006` |
| `Stare` | `XWALK_CNTRL_STARE_AT_YOU_REQ` | `0x200E` |
| `BullFight` | `XWALK_CNTRL_BULL_FIGHT_REQ` | `0x200F` |
| `Treasure` | `XWALK_CNTRL_TREASURE_HUNT_REQ` | `0x2010` |
| `VideoCar` | `XWALK_CNTRL_VIDEO_CAR_REQ` | `0x2011` |
| `VideoStream` | `XWALK_CNTRL_VIDEO_STREAM_REQ` | `0x2020` |

### Voice

| Stem | Request signal | Request ID |
| --- | --- | --- |
| `BgMusic` | `XWALK_CNTRL_SOUND_BACKGROUND_MUSIC_REQ` | `0x2007` |
| `VisionTalk` | `XWALK_CNTRL_TEXT_VISION_TALK_REQ` | `0x2008` |
| `LlmTest` | `XWALK_CNTRL_ONLINE_LLM_TEST_REQ` | `0x2009` |
| `Sound` | `XWALK_CNTRL_SOUND_REQ` | `0x2018` |
| `VoiceChat` | `XWALK_CNTRL_VOICE_CHAT_REQ` | `0x2019` |
| `ActiveCar` | `XWALK_CNTRL_VOICE_ACTIVE_CAR_REQ` | `0x201A` |
| `GptCar` | `XWALK_CNTRL_GPT_CAR_REQ` | `0x201B` |
| `VoiceCtrl` | `XWALK_CNTRL_VOICE_CONTROLLED_CAR_REQ` | `0x201C` |
| `VoicePrompt` | `XWALK_CNTRL_VOICE_PROMPT_CAR_REQ` | `0x201D` |
| `StoryRobot` | `XWALK_CNTRL_STORYTELLING_ROBOT_REQ` | `0x201E` |

## 5. Configuration

### Using the samples

From `xWalk-rpi5-node`, for example:

```bash
./build-host/cmake/xwalk publish --function service --signal XWALK_LIFE_MOVE_REQ
```

Wait for `LifeMoveCfm` with state `XWALK_LIFE_STATE_ACTIVE` before requesting movement:

```bash
./build-host/cmake/xwalk publish --function vehicle --signal XWALK_CNTRL_MOVE_REQ
```

JSON and publish modes select the staged sample automatically from `--signal`; `--file PATH` is an optional
override. The `json` command publishes once, disconnects and exits. Subscribe mode runs in the foreground in a
separate terminal.

Without `--file`, the lifecycle request targets `XWALK_LIFE_STATE_ACTIVE` and enables actuators. Observe the
matching successful `LifeMoveCfm` with state `XWALK_LIFE_STATE_ACTIVE` before requesting movement; a successful
publisher exit only confirms sending. The Controller still requires ACTIVE and enforces commissioning limits and
all other safety checks.

### Client identities

Client identities use mailbox 1, local index 1 and the loopback address for both `clientAddress` and `serverIp`,
with the matching functional module ID: service=1, vehicle=2, vision=3, voice=4. Before sending a real CFM or
Reject, replace its complete `clientAddress` object with the identity echoed from the actual request. Request
sending assigns the outer identity through the transmitter. Any nested `clientAddress` values shown are separate
schema fields.

### Runnable movement and sound samples

`MoveReq` requests `XWALK_MOVE_ACTION_FORWARD` at 15% for 250 ms. Explicit ACTIVE lifecycle admission and the
configured commissioning limit still apply; this sample never marks calibration verified or changes the limit.
The legacy `xWalkMqttMove.json` requests 25% for 250 ms and is used by the JSON unit test.

The source `SoundReq` JSON is a staging template whose `filePath` is the placeholder `@XWALK_STAGED_SOUND_SAMPLE@`.
`stage-sound-sample.py` derives a PCM16 WAV from the original PCM24
`xWalk-rpi5-hw/xWalkAudioResources/sounds/car-double-horn.wav` and writes its absolute path into the build's
`config/request/voice/xWalkMqttSoundReq.json`. Use that staged sample; the source placeholder is not a live path.
The sound volume is 20%. The staged sample works outside the repository working directory; regenerate after
moving a build. For a publisher on another host, use `--file` with the asset path on the receiving Pi.

The original licensed asset is unchanged. The generated derivative retains its provenance and licence from
[the audio-resource attribution](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkAudioResources/xWalkAudioResources.md). The
decoder's PCM16 contract is unchanged.

### Connection template

`xWalkMqttClient.conf`
is seeded into `<build-directory>/config` only if absent. It carries the `HIVEMQ_HOST`, `HIVEMQ_CLIENT_ID` and
`HIVEMQ_CA_FILE` keys and no username or password. Connection credentials belong in a private connection file or
netrc as described in [xWalkMqttInit](../xWalkMqttInit.md), never in message samples or this template.

## 6. Testing

Host tests inspect the staged WAV and exercise JSON and GPB conversion; no audio is played and nothing is
published during these checks.

| CTest name | Labels | Owner note |
| --- | --- | --- |
| `xWalkMqttStagedSampleHostTest` | `host;mqtt;sample` | xWalkMqttInit |
| `xWalkMqttSample<Type>HostTest` | `host;mqtt;json;sample;protobuf` | xWalkMqttJson |
| `xWalkNodeModuleTerminalTest` | `host;node;module;json` | xWalkModule |

## 7. Dependencies

- Python 3 for `stage-sound-sample.py` (standard library `wave` and `json` only).
- The packaged horn sound in
  [xWalkAudioResources](../../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkAudioResources/xWalkAudioResources.md).

## 8. Safety and constraints

- Never commit credentials, tokens or account data into this directory.
- A sample that enables actuators or requests motion is sent to the real robot when published to a live
  subscriber; publish it only with a confirmed safe Raspberry Pi and Robot HAT setup.

## 9. Related notes

- [xWalkMqttInit](../xWalkMqttInit.md)
- [xWalkMqttJson](../../xWalkMqttCommon/xWalkMqttJson/xWalkMqttJson.md)
- [xWalkMqttNode](../../xWalkMqttCommon/xWalkMqttNode/xWalkMqttNode.md)
- [xWalkIoT](../../xWalkIoT.md)

---

[Previous page](../xWalkMqttInit.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkMqttServer/xWalkMqttServer.md)
