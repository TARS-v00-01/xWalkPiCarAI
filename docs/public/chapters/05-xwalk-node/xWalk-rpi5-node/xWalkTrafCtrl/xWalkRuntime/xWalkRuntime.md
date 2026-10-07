<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkRuntime

**5. xWalk node &middot; Module 29**

<!-- xwalk-page-header:end -->

# xWalkRuntime

`xWalkRuntime` composes the native traffic session: capture, path vision, model inference, evaluation JSONL,
risk-level announcement pacing, observation broadcasts, camera-qualified proximity incidents and local speech.

## 1. Overview

`run(settings)` configures traces, optionally enables the detection preview when `XWALK_TRAFFIC_PREVIEW_FILE` is
set, loads models once per session and processes frames until end of input, the frame limit, or SIGINT/SIGTERM.
Signals request exit after the current synchronous capture, inference, LLM or MQTT operation.

### Host replay

Host video, image, report and Protobuf replay validate each observation, optionally write one evaluation JSONL
record per processed frame, broadcast the observation on the classified-risk topic, and pass elevated risk through
`AnnouncementGate`. The gate accepts a risk change immediately and repeats the same elevated risk only after
`announcement_interval` seconds; SAFE never repeats. It rejects non-monotonic timestamps. Accepted risk is turned
into an advisory by [xWalkAnnouncement](../xWalkAnnouncement/xWalkAnnouncement.md) and published by
[xWalkPublisher](../xWalkPublisher/xWalkPublisher.md). Host-video advisories carry a simulated Halmstad location.

### Live Pi incidents

The sensor still stops movement immediately at 80 mm. After 0.5 seconds of sustained blockage, the separate
announcement worker speaks one local warning through the existing Espeak/ALSA provider: "Obstacle very close.
Movement stopped. Please check the path." This reports proximity, not proven contact. It requires a configured
local speech executable and ALSA PCM and mixer, at 50 percent volume. `xWalkRpi5Cpu.conf` retains this Pi's
`default` playback, `pulse` mixer and `Master` control. The active Controller owns and enables the Robot HAT
speaker through BoardControl during startup; traffic does not acquire a second speaker GPIO owner. A standalone
ALSA probe with Controller stopped can complete successfully without audible output; verify playback with the
hardware owner running and confirm the warning at the physical speaker. Successful synthesis alone is not an
audibility check. Speech failure is logged and never changes motor safety or causes an MQTT fallback.

The runtime then evaluates a camera frame acquired after that blockage transition. Frames finishing inference more
than three seconds after acquisition, pre-blockage frames and inactive or missing owners cannot qualify a traffic
report. Current, valid, fresh sensor blockage is rechecked before classification. A valid observation with a
detected person or vehicle occupying the model's crossing region qualifies as a **possible traffic blockage**.
Three or more detected vehicles with vehicle crossing occupancy qualify as **possible heavy traffic**. The model's
pedestrian-risk label is not a congestion classifier; these categories are explicit heuristics, not trained
congestion classes or proof of the obstacle's cause. Background vehicles outside the crossing, isolated objects,
invalid model output or missing camera confirmation produce no MQTT incident. Pixel size alone never proves
congestion or physical contact.

One fresh frame decision is consumed per episode. Only qualified traffic episodes send one MQTT SoundReq ANNOUNCE
and one clearance announcement after the sensor's sustained clearance; both use the same explicitly simulated
Halmstad location. Local-only episodes have no MQTT clearance message. Live Pi operation bypasses periodic
observation and risk broadcasts so that an isolated obstacle cannot leak through that second publication path.
Vehicle/All restarts pause the episode without repeating its speech or report; restarting the traffic runtime
itself starts a new session. MQTT failures have unknown delivery and are never automatically retried. Camera
inference, local speech and MQTT never delay the independent motor-stop polling worker.

Each sampled live frame is also passed to [xWalkPathVision](../xWalkPathVision/xWalkPathVision.md); classification
changes produce local diagnostic warnings only.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkRuntime` -
source directory

## 3. Directory layout

```text
xWalkRuntime/
    CMakeLists.txt                  Library, Espeak provider inclusion and GoogleTest registration
    include/xWalkRuntime.h          IncidentKind, CameraIncident, AnnouncementGate and run
    src/xWalkRuntime.cpp            Session composition and incident routing
    test/src/xWalkRuntimeTest.cpp   Host GoogleTests
```

## 4. Public interface

Declared in `xWalkRuntime.h` in
namespace `xwalk::traffic`:

| Symbol | Contract |
| --- | --- |
| `IncidentKind` | `None`, `LocalObstacle`, `TrafficBlock`, `HeavyTraffic` |
| `CameraIncident` | `begin(nowMs)`, `evaluate(observation, capturedMs, nowMs)` once per episode, `clear()` |
| `AnnouncementGate(interval)` | `accept(risk, seconds)` paces repeated risk; interval finite and >= 0 |
| `run(settings)` | Run the configured native session and return the process status |

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md). Adds the
[xWalkGPT](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/xWalkGPT.md) Espeak provider when
`xWalkTextToSpeechEspeak` does not yet exist. Links publicly to `xWalkConfiguration` and `xWalkProtocol`, and
privately to the speech provider, `xWalkPathVision`, `xWalkProximity`, `xWalkCapture`, `xWalkModel`,
`xWalkAnnouncement`, `xWalkPublisher` and `xWalkLanguageModelOllama`.

For a binary built outside its deployment checkout, configure `XWALK_TRAFCTRL_CONFIG_DIR` with the target machine's
absolute `xWalkConfig` path. This controls the generated default and host overlay paths and the initial MQTT
configuration default. If reusing a build cache, also update `XWALK_MQTT_CONFIG_FILE` explicitly. Copy the tracked
configuration directory with the executable; retain target-local overrides and credentials separately. Set
`XWALK_TRAFCTRL_RUNTIME_BUILD_DIR` to the target build directory as well, and deploy `generated/xwalk-traces.xml`
from the build alongside the executable. Trace logs go into its `log` directory. This avoids references to the
build machine's temporary directories at runtime. Native checkout builds keep their existing defaults.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkRuntime --output-on-failure
```

`xWalkRuntimeGoogleTest` (labels `host;gtest;xWalkRuntime`) covers risk changes and interval pacing, native replay
writing evaluation output without models or network, isolated obstacles and invalid camera observations staying
local, post-blockage camera evidence with one clearance, background traffic, and cancellation of a pending
evaluation. Socket tests in [xWalkProximity](../xWalkProximity/xWalkProximity.md) verify typed transitions across
owner activity cycles. Audible playback and live CSI capture are not covered by host tests.

## 7. Dependencies

- All traffic submodules listed under Build.
- `xWalkLanguageModelOllama` from
  [xWalkLanguageModel](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/xWalkLanguageModel.md).
- Espeak (`espeak-ng` by default) and ALSA on the Pi for local speech.

## 8. Safety and constraints

- Camera inference, local speech, LLM generation and MQTT are never on the motor-stop path.
- Traffic categories are heuristics; they do not prove the cause of an obstacle.
- Slow inference or LLM work can delay subsequent frames; there is no added hard timeout around capture or
  inference.

## 9. Related notes

- [xWalkProximity](../xWalkProximity/xWalkProximity.md)
- [xWalkModel](../xWalkModel/xWalkModel.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkPublisher/xWalkPublisher.md) · [Chapter index](../../../index.md) · [Next page](../xWalkTest/xWalkTest.md)
