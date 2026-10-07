<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkBoot

**2. xWalk hardware &middot; Module 04**

<!-- xwalk-page-header:end -->

# xWalkBoot

`xWalkBoot` builds the `xWalkControllerBoot` static library. Its `XWalkBoot` class derives from
`XWalkController` and owns the selected HOST or RPI5 HAL/Driver dependency graph, platform providers and the
asynchronous operation runtime that executes Controller requests and produces their typed CFM or REJ responses.

## 1. Overview

### Ownership and startup

Link `xWalkControllerBoot` and include `xControllerBoot.h` for production composition.
`XWalkBoot::create(callbacks, configurationPath)` constructs stopped Controller workers, configuration, platform
providers, shared HAL dependencies and Driver coordinators. `modules()` exposes a borrowed graph valid until Boot
destruction. The module and platform owners cannot be copied. Calling the Boot constructor alone does not create
that graph; use the factory before starting workers. The objects owned by the graph are listed in
[Boot module ownership](Modules.md).

The process composition (Node or standalone `xwalk-ctrl run`) owns the returned `XWalkBoot` pointer. Controller
has a virtual destructor and virtual `start()`/`stop()`, so lifecycle calls through a base pointer retain Boot
shutdown. Boot closes operation admission, cancels and joins the operation worker, drains and joins the four
Controller workers, then releases the module graph in reverse order.

The startup exception boundary converts construction failures to `NULL` after rollback. A separate operation
boundary contains Driver execution and cleanup exceptions and produces typed failure responses. Node contains
encoder exceptions and returns a failed delivery result. Ordinary Controller handlers keep return-value errors;
exception text from providers is not copied into responses.

| Selection | Backend behavior |
| --- | --- |
| HOST | Robot HAT simulation and inactive media, vision, speech and language callbacks |
| RPI5 | Linux I2C/GPIO/SPI, camera/OpenCV, ALSA, Vosk, Piper, Ollama and WebSocket providers |

Boot validates `hardware_mcu_reset_settle_ms` before opening providers, using the bounded unsigned parser:
200 ms by default, with an inclusive 1–10000 ms range. It constructs the reset GPIO, speaker-enable GPIO,
battery A4 ADC and BoardControl before PWM. BoardControl asserts reset low for 10 ms, releases it high for 10 ms,
then Boot waits the configured settling interval before the first PWM timer write. Dependencies remain owned by
the Boot graph throughout partial-startup rollback and shutdown. Invalid, fractional and out-of-range waits fail
startup. A successful host Boot regression verifies that reset is released.

Native OpenCV providers supply device callbacks and retain their own contexts. Controller composes complete vision
and recording tables: device operations forward to the matching original provider context, while delay and
continuation callbacks use the Boot module graph through `operationWait` and `operationContinue`. These bindings
service the motor watchdog and preserve cooperative cancellation. ComputerVision, BullFight, FaceTracking,
VideoCar, TreasureHunt, VideoRecording and AppControl all use this composition; stop callbacks remain non-throwing.
A native provider context is never interpreted as a module graph.

RPI5 startup requires configured devices and model resources. Construction does not initialize or arm the PiCar-X.
A successful `LifeMoveReq` to `ACTIVE` explicitly initializes it; motion and actuator calibration requests require
that state and retain the Driver's commissioning and maximum-output limits. Repeating `ACTIVE` while already
`ACTIVE` returns a confirmation without reinitializing devices, changing steering, or clearing an emergency stop.

Health messages identify `Controller RPI5 runtime ready` or `Controller HOST simulation runtime ready`. Doctor also
identifies the selected backend; dependency readiness alone is not physical hardware verification.

## 2. Source location

`xWalk-rpi5-hw/xWalkController/xWalkBoot` —
source directory

## 3. Directory layout

```text
xWalkBoot/
├── CMakeLists.txt                       # xWalkControllerBoot library and Boot host tests
├── xControllerBootConfiguration.cmake   # HOST/RPI5 selection and profile agreement checks
├── xControllerBootDependencies.cmake    # HAL/Driver subdirectories and bootModuleLibraries
├── include/
│   ├── xControllerBoot.h                # XWalkBoot startup owner
│   ├── xControllerBootModules.h         # Production HAL and Driver dependency graph
│   ├── xControllerBootPlatform.h        # Selected host or Linux providers and callback bindings
│   ├── xControllerBootBoundary.h        # Startup exception isolation behind C-style callbacks
│   ├── xControllerBootSettings.h        # Device-free deployment parsing
│   ├── xControllerBootHostCallbacks.h   # Device-free host callback tables
│   ├── xControllerOperation.h           # Cancellable operation and shared-device execution lease
│   ├── xControllerOperationCallbacks.h  # Cooperative cancellation and bounded terminal input
│   ├── xControllerOperationDiagnostics.h # Diagnostics accumulated before the final response
│   ├── xControllerMovementResponseGuard.h # Motor lease during blocking response publication
│   ├── xControllerBattery.h             # Five-second battery sampling and one-minute average
│   ├── xControllerProximity.h           # Front-proximity safety contract
│   ├── xControllerAnnouncementStore.h   # Bounded announcement storage and duplicate suppression
│   ├── xControllerSpeechSession.h       # Remote Treasure Hunt prompt worker
│   ├── xControllerVideoSession.h        # Background camera stream session
│   └── xControllerWorkerPlacement.h     # Functional CPU placement for background workers
└── src/
    ├── xControllerBoot.cpp, xControllerBootModules.cpp, xControllerBootBoundary.cpp
    ├── xControllerBootHost.cpp          # HOST-only hardware-free bindings
    ├── xControllerBootRpi5.cpp          # RPI5-only Linux providers
    ├── xControllerOperation*.cpp        # Admission, execution, power, control, response, callbacks
    ├── xControllerServiceOperation.cpp  # Read-only service requests outside the vehicle lease
    ├── xControllerAnnouncementOperation.cpp, xControllerAnnouncementStore.cpp
    └── xControllerBattery.cpp, xControllerProximity.cpp, xController*Session.cpp, ...
```

Host tests for Boot live in the parent `test` directory.

## 4. Public interface

### Handler adapters

All 38 production request handlers call `XWalkCoreCallbacks::operation`. Boot installs an adapter that deep-copies
the request into one asynchronous operation slot. All 76 typed CFM/REJ handlers call
`XWalkCoreCallbacks::response`; Node installs its typed GPB encoders and synchronous QoS 1 publisher. The outer
client address takes precedence over a present nested request address. Callbacks borrow payloads only until
return. A response handler returns `true` only when Node reports transport delivery.

| Request family | Operation interface |
| --- | --- |
| LifeMove, Health, Version, Help, Doctor | Runtime lifecycle, status, version and dependency checks |
| Unknown | Explicit typed rejection |
| TraceEnable | Shared trace UID, module or all-trace selection |
| I2c, Spi | HAL I2C probe/read/register operations and Driver SPI transfer |
| AppCtrl | App-control Driver session |
| Move, Turn, Camera, Sensor | PiCar-X movement, steering, camera servos and sensor reads |
| Keyboard, Avoid, Cliff, LineTrack, SelfDrive | Matching vehicle Driver coordinator |
| ServoZero, Calibrate | Servo zeroing and grayscale/servo-motor calibration routines |
| Vision, Stare, BullFight, Treasure, VideoCar | Matching vision Driver session |
| VideoRecord, VideoStream | Recording and streaming Driver sessions |
| Sound, BgMusic | HAL music control and background-music Driver session |
| VoiceChat, LlmTest, VisionTalk | Voice chatbot, online model and image conversation sessions |
| ActiveCar, GptCar, VoiceCtrl, VoicePrompt, StoryRobot | Matching voice/vehicle Driver session |

### Request outcome contract

All 38 production request signals use the same Boot outcome policy and their corresponding typed CFM/REJ:

- Successful execution and cleanup with no warning/error produce the matching CFM.
- Failed validation, a failed Driver result, an exception, or an execution/cleanup warning/error produce the
  matching REJ. Warning/error capture requests cooperative cancellation of an active operation.
- Client address, mailbox, local index and module type are preserved in the terminal result or Node publication.
- Intermediate command diagnostics remain local traces. The final response is selected once after cleanup, so a
  warned command cannot also emit a success CFM. Failed response delivery is logged without sending a second reply.
- Cancellation rejects the original operation; the separate stop request is confirmed only when cleanup succeeds
  without warnings/errors. Cleanup failure rejects the stop request too.

Diagnostic capture covers admission and the command's execution/cleanup thread across Controller, HAL and Driver
components. Background providers must report their failure through their coordinator return/status interface;
unrelated background/transport logs are not assigned to another request. Diagnostics before a request exists
remain lifecycle/status diagnostics rather than fabricated request responses. Module stubs remain inspection-only.

### Operation lease and cancellation

The operation worker holds an exclusive lease over shared devices, across service, vehicle, vision and voice
requests. A competing request receives its matching REJ instead of waiting behind an unbounded Driver session. A
same-session lifecycle `STOP`, sound `STOP`, or global `LifeMoveReq` to `STOPPING`/`STOPPED` requests cancellation.
The original session receives a cancellation REJ; the stop request receives its own CFM only after cleanup
succeeds. Global lifecycle stop also closes PiCar-X. Duplicate stop requests or stops for a different active
session are rejected.

Cancellation and accepted STOP ownership are separate: Ctrl+C, timeout, EOF, callback failure and owner shutdown
never create a STOP confirmation or publish lifecycle STOPPED. Only an accepted lifecycle stop closes PiCar-X and
updates that state. Every cancelled operation receives a cancellation REJ, including when Driver failure
diagnostics are also present; their error selector remains available. Emergency cleanup depends on cancellation,
regardless of its source. Admission resets per-operation cancellation and STOP state, so idle STOP is idempotent
and cannot affect later work. Cancellation and STOP admission freeze together before cleanup; owner shutdown during
completion joins the worker without changing its already determined outcome.

A repeated lifecycle `ACTIVE` request acknowledges an already active controller without acquiring the device
lease or reinitializing hardware. This lets another GUI connect while a sensor request is running. Shutdown,
pending STOP and proximity-stop admission checks still take precedence.

Cancellation is cooperative: delay callbacks check every 10 ms, terminal input polls every 50 ms, and active
backend calls must return before cleanup can finish. No thread is forcibly terminated. Keep deployed camera, speech
and network provider timeouts bounded. EOF cancels terminal-driven sessions. Interactive input is read from the
process terminal; the existing request schemas do not contain keyboard or prompt text.

Conversation loops recheck session state after terminal input and recognition, and after model inference before
using its result. Cancelled text input cannot start inference; cancelled image-chat input cannot start camera
capture. Voice chatbot cancellation prevents a later model prompt or response speech, and vehicle conversation
loops check again before action dispatch. These checks prevent subsequent work after cancellation is observed;
they do not forcibly interrupt an already-running synchronous camera, recognition, retrieval or model call.
Those calls retain their own timeouts and cleanup contracts.

A terminal response can reach its client before the transport callback returns. After device cleanup, ordinary
follow-up requests wait for that publication to finish instead of receiving a false device-busy rejection. Request
storage stays owned until the old worker is joined. Active operations still reject conflicting commands. STOP also
waits through terminal publication after cleanup; during active execution, it retains its cancellation behavior.
Power updates and response-callback reentry keep their admission rules. Owner shutdown wakes waiting admission and
rejects it as stopping. This ordering uses a condition variable, without a client delay or an automatic retry.

### Provider cancellation and rejection diagnostics

Boot binds the operation cancellation latch to both HTTP model instances and the Piper provider. The latch
outlives provider calls and is reset only on new operation admission. Typed provider interruption is an expected
cancellation REJ; it does not create a user STOP request. Accepted session STOP and lifecycle STOPPED retain their
separate request identities and complete only after required cleanup. Lifecycle STOPPED alone closes the vehicle
and changes lifecycle state. Cleanup failure rejects STOP rather than confirming an unsafe completion.

Treasure Hunt warm-up cancellation and optional farewell suppression use the same cooperative contract. The
original operation remains a REJ. Fixed Piper, HTTP, missing-model, and invalid-response diagnostic categories
preserve useful context through the existing rejection fields without forwarding provider bodies, credentials,
headers, or arbitrary exception text. Genuine provider/cleanup errors are retained alongside cancellation; unknown
exceptions keep a safe generic fallback. Emergency-stop failure is itself a cleanup failure.

### Movement, sensors and battery

Move defaults to 20 percent speed and 1000 ms when those optional values are absent; explicit durations must be
1–60000 ms. Speed must be finite and within the commissioned Driver limit. Movement stops on completion or failure.
Turn defaults to 30 degrees. Sensor results use JSON text in the response message; I2C/SPI results use binary data.
VideoRecord starts recording after opening the camera. TreasureHunt uses red as its default target. Calibration
routines do not mark commissioning verified automatically. Invalid arguments, unavailable providers and Driver
failures produce REJ; shared-device admission failures never start another operation.

A read-only worker samples `BoardControl::batteryVoltage()` through Robot HAT ADC A4 every five seconds. Sensor
type Battery (2) returns only the latest completed 60-second voltage average, formatted as `battery_voltage`,
`battery_percent` and `estimated` in `SensorCfm.message`. It also reports `battery_sample_age_ms` (monotonic age
of the last valid physical sample) and `battery_valid` (the latest physical sampling attempt's outcome). Retaining
an average does not refresh this age or turn a failed attempt into success. These fields let boot/HUD readiness
reject cached averages while preserving the last known voltage for display.

Each normal window contains twelve samples. Invalid voltages and failed ADC transactions are excluded. A window
with no valid samples retains the previous average. Before the first valid minute, the response is
`{"battery_pending":true}`; instantaneous readings are never sent. The sampler joins before HAL teardown.
`battery_empty_voltage` (default 6.0 V) and `battery_full_voltage` (default 8.4 V) configure the estimate. Values
must be finite, within the ADC range, and full must exceed empty; invalid settings reject the request. The
percentage is the nearest integer of the clamped linear position between those endpoints. The defaults use the
[Robot HAT input range](https://docs.sunfounder.com/projects/robot-hat/en/v2.0/features.html), not a calibrated
discharge curve. Voltage under load or while charging is not an accurate state-of-charge gauge. HOST tests exercise
the same ADC and Controller code through the Robot HAT simulator without physical hardware.

### Continuous manual movement

`MoveArg.continuous` (field 4, default false) makes `duration_ms` a renewable lease of 200–1000 ms. A successful
`MoveCfm` with message `Continuous movement applied` acknowledges applied motor power while the worker retains the
device lease. Further continuous Move requests renew the lease and update power without stopping between
confirmations. Zero power stops the motors and ends the lease; shutdown and lost renewals also stop output. No
second response is emitted for an already acknowledged request when its lease expires. If a valid zero-power
request without steering is queued when the lease expires, it receives its own confirmation only after successful
motor cleanup. Unapplied power or steering updates remain rejected. Ordinary Move requests retain bounded pulse
execution. Remote Treasure Hunt retains bounded pulses only. Regenerate interfaces and update Node's
receive/transmit adapters with the schema.

Optional `MoveArg.steering_angle_degrees` (field 5) applies signed steering in the inclusive range −30° through
+30° before motor power on the same worker. An absent field preserves the previous steering command. Non-finite or
out-of-range angles are rejected before output. Continuous combined requests confirm with
`Continuous movement and steering applied`; bounded combined requests use `Movement and steering applied`. The GUI
uses these messages to detect older nodes that would silently ignore an unknown optional field. Releasing the GUI
control sends zero motor power, then confirmed Turn steps back to zero. The node retains its lease-expiry stop if
the client disconnects; it does not assume that a steering command measures wheel position.

While a Move confirmation is being published, a joined safety worker services the motor watchdog only until the
original lease deadline. Slow MQTT delivery cannot prolong movement or disarm an otherwise healthy motor pair by
starving its heartbeat. Lease expiry stops motor output; cancellation disarms it. A genuinely disarmed motor is
rejected with reason 18 and requires lifecycle activation; request handling never automatically rearms it.

During continuous manual movement, ultrasonic, grayscale and battery `SensorReq` messages (types 0–2) are admitted
in a separate four-entry FIFO, including the in-flight response. The same operation worker samples and publishes
its correlated response between Move renewals; no concurrent device owner is introduced. Pending Move updates and
STOP take priority. Sensor reads do not extend the motor lease; the motor safety guard retains the original
movement deadline during sensor access and response publication. Sensor faults reject only the sample; they do not
cancel healthy movement. A sample still pending when movement ends receives a correlated rejection with reason 18.
A full sensor FIFO is rejected as busy; other operations retain exclusive device admission.

### Mode motor-power requests

Line Follower, Bull Fight, Treasure Hunt, Obstacle Avoidance and Cliff Guard accept `motor_power_percent` in their
GPB requests. Set `update_motor_power` to true to change the matching running mode without stopping or restarting
it. Valid power is finite and between 0 and 100 percent; STOP requests omit it. The matching CFM echoes accepted
power, while the existing REJ reports invalid, busy, or unsupported requests. Face Tracking remains camera-only
and rejects motor power. Request/reply signals and client routing remain unchanged. Deploy matching IW, Node,
Controller and Driver revisions before enabling updates.

### Stored spoken announcements

Sound operation ANNOUNCE (4) retains the host ID, title and body in the Boot session, then invokes the shared
text-to-speech coordinator. Confirmation means speech returned successfully. Validation, resource and speech
failures reject the request. IDs must contain 1–64 ASCII letters, digits, hyphens or underscores; title and body
are NUL-free, nonblank UTF-8, limited to 480 and 40000 bytes. Other sound operations remain unchanged.

The store is the robot's received-message Inbox: it keeps the latest eight unique records in session memory until
Boot destruction. A valid ninth record evicts the oldest record (first arrival) before being spoken. Duplicate
retained IDs do not move to the end of the queue or renew FIFO age. Evicted IDs are no longer covered by duplicate
suppression. The voice worker owns the store; unrelated cores never mutate it.

An identical completed ID is confirmed without another speech call. Changed text for a retained ID, or an ID
whose speech has an uncertain/failed outcome, is rejected. Suppression is session-local; restarting the node
clears it. Incomplete initial deliveries are not automatically retried. Storage is not persistent. The host
Outbox keeps its own status; local deletion does not delete node records. The desktop Inbox and Outbox each
retain eight session entries; standalone uses the same node capacity but does not play audio.

Announcements are shared broadcasts, not device-addressed messages. The MQTT node subscribes to the common
SoundReq request topic and accepts broadcasters independently of their client addresses. ClientAddr identifies
the sender for CFM/REJ routing; it does not restrict announcement storage to one broadcaster. All broadcasters
share the same eight slots and ID namespace. Use globally unique IDs: retransmission by another broadcaster is
still a duplicate. Existing admission and resource checks apply, so overlapping speech requests can be rejected
as busy.

Announcements are spoken in sequential UTF-8 aligned chunks of at most 4096 bytes, including scheduled replays.
The complete text is retained; storage is marked spoken only after every chunk completes. Cancellation is checked
between chunks as well as by the speech provider. The provider input limit remains intact.

#### Automatic announcement playback

A new announcement is read immediately; completed announcements are then replayed together in arrival order every
30 minutes. The first successful speech starts the timer; each scheduled round starts a fresh interval when it
finishes. FIFO insertion does not reset that deadline. Incomplete initial speech records are retained for
duplicate protection but excluded from scheduled playback.

Configure `announcement_interval_ms = 1800000` in `picar-x.d/voice.conf` (1000–86400000 ms). The deadline polling
period is `announcement_poll_ms = 1000` (100–60000 ms) in the same file. The timer uses monotonic time and the
independent announcement worker; vehicle operations do not delay it. It pauses in lifecycle states other than
Passive Ready or Active. Delayed rounds do not accumulate or replay in a burst. Stopping the Controller joins the
timer and cancels its active operation before resources are destroyed. Scheduled rounds do not emit unsolicited
request confirmations. Storage and timers reset on node restart.

#### Concurrent announcement playback

Announcements and scheduled replay own a separate copied request, thread, Piper provider and cancellation latch.
The single vehicle/device lease continues to serialize movement, mode, camera-control and sensor operations;
announcement playback does not acquire that lease or stop background video. Only one announcement/replay is
admitted at a time. Both lanes retain correlated completion and rejection responses.

Movement release and mode-specific STOP leave announcements running. Global lifecycle STOP and Boot shutdown
cancel both lanes and join speech before reporting completion. Sound STOP cancels announcement playback when the
device lane is idle. Clients must use the matching updated node; older nodes reject concurrent operations. The
playback executable uses the configured default audio route; simultaneous mode prompts require a mixer such as
PulseAudio (the deployed Pi default) or ALSA dmix, rather than an exclusive raw hardware PCM.

### Background video sessions

`VideoStreamReq.background = true` starts an independently owned CSI/MJPEG worker and confirms once camera and
listener startup succeed. `stop = true` is valid only with `background = true` and confirms cleanup of that
background session. Both fields default to false, preserving the foreground streaming command. The handwritten
Node encode/decode adapters carry both fields.

The background worker owns only the streaming camera and HTTP listener. Bounded vehicle requests, camera angles
and sensor requests retain the ordinary Controller operation slot. Camera-consuming vision modes stop the
background worker before acquiring the camera. Lifecycle Stop, Controller shutdown and capture failure close its
clients, listener and camera. A successful start CFM does not guarantee future camera availability; later capture
failures are traced and close the HTTP connection. The stream remains loopback-only by default and the desktop
accesses it through an authenticated SSH tunnel. Deploy updated IW interfaces, Node adapters and Controller
together before using desktop background mode.

### Remote Treasure Hunt

`TreasureReq.remote_control = true` runs target detection without reading standard input. The active session
admits one copied Move, Turn or Camera request between detection steps, using its device-owning worker. Each
command receives its own correlated confirmation or rejection. Move requires an explicit duration of 1–1000 ms and
forward/backward action; demos are rejected. Motor cleanup precedes the command response and the next detection
step. Actuator limits apply. Busy slots reject additional commands, and session termination rejects commands that
were not applied. Lifecycle Stop interrupts movement and ends the session. The default false value preserves
terminal control.

Remote Treasure Hunt queues spoken prompts through a session-owned audio worker. One pending prompt is coalesced
to the latest target, while foreground movement remains responsive. STOP cancels provider processes and joins
speech before releasing the operation lease. Speech failures become logged operation rejections.

Native Boot supplies the libsndfile decoder to Music ALSA, allowing packaged WAV and MP3 resources to use the
shared audio backend. Host playback remains simulated.

### Functional worker placement and parallel signals

Each functional queue has its own worker and one of four distinct allowed Linux CPUs. On the Pi these are CPU 0
(services), CPU 1 (vehicle), CPU 2 (vision) and CPU 3 (voice). Boot captures the lifecycle owner's CPU map before
startup. Operation workers use their request's role; camera streaming explicitly uses vision, and announcements,
replay timing and Treasure Hunt prompts explicitly use voice. A worker never chooses its CPU by inheriting the
thread that happened to submit its work. Fewer than four allowed CPUs or an affinity failure prevents
startup/admission rather than silently sharing CPUs.

The queue threads are named `xw-service`, `xw-vehicle`, `xw-vision` and `xw-voice`. Background threads use
`xw-operation`, `xw-camera`, `xw-announce`, `xw-prompts` and `xw-voice-timer`. Linux and library threads can still
share these CPUs; this is functional affinity, not exclusive OS CPU reservation or real-time scheduling. Device
leases, request cancellation and the motor watchdog remain unchanged.

The four independent FIFOs dispatch and complete requests on their functional workers. Health, Version, Help and
Doctor read stable runtime metadata without taking the vehicle lease or clearing its cancellation flag. An
already-running background video stream can confirm a repeated background START on the vision worker without
restarting the camera or disturbing movement. Camera acquisition and conflicting actuator commands retain their
device ownership checks. Global lifecycle STOP still coordinates all active work. The Node response transport
releases its locks while each functional caller awaits QoS completion. Shared network failure or operations on the
same physical hardware cannot be isolated by CPU affinity alone.

## 5. Build

The parent [xWalkController](../xWalkController.md#6-build) build adds this directory unless
`XWALK_CONTROLLER_BUILD_MODULE=ON`. With `XWALK_CONTROLLER_BUILD_RPI5`, CMake enables the Linux I2C, GPIO, SPI,
camera, OpenCV, audio, music, speaker, STT, Vosk, Piper, Ollama, computer-vision, recording and app-control
WebSocket backends and links `xControllerBootRpi5.cpp`. Otherwise it links `xControllerBootHost.cpp` and
`xWalkRobotHatSimulation`. `XWALK_CONTROLLER_BOOT_CONFIG` is compiled from `XWALK_CONTROLLER_RUNTIME_CONFIG_FILE`.

```bash
cmake --preset host
cmake --build --preset host --parallel 4
```

Run from `xWalk-rpi5-hw/xWalkController`; see the parent note for module, RPI5 and cross presets.

## 6. Configuration

### Configuration file selection

Boot selects one existing configuration file, in this order:

1. The explicit `XWalkBoot::create(callbacks, configurationPath)` argument (including terminal `--config`).
2. A nonempty process environment variable `XWALK_PICARX_CONFIG_FILE`.
3. The absolute CMake-selected `XWALK_PICARX_CONFIG_FILE`, exported internally as
   `XWALK_CONTROLLER_RUNTIME_CONFIG_FILE` and compiled into Boot.

A missing selected file fails startup; Boot does not create an empty replacement or fall back to another file.
Node uses the same Boot default. An explicit CMake path is cached and survives reconfiguration; remove that cache
entry with `-U XWALK_PICARX_CONFIG_FILE` only when deliberately returning to the product default. HOST always
compiles simulated providers, even with an explicitly selected deployment file.

| Build | Default selected file |
| --- | --- |
| Native Node `rpi5-native` | `xWalk-rpi5-node/runtime/picar-x.conf` |
| Full RPi aggregate | `<CMake-binary-directory>/../runtime/picar-x.conf` |
| Standalone Controller or HOST | `<CMake-binary-directory>/config/picar-x-profile.conf` |

Paths are resolved to absolute paths during CMake configuration. A process override is interpreted by the process;
use an absolute path in service environments. `config/picar-x-profile.conf` remains a generated diagnostic/profile
entry point in full Pi products, but does not override their selected deployment file.

For newly generated Pi runtimes, `runtime/picar-x.conf` includes `generated/picar-x.conf`. Keep deployment
overrides, provider selections and calibration **after that include**, or include another deployment-owned `.conf`
below `runtime` at the end. Generated defaults live below `runtime/generated/`; do not edit that marked directory.
Configure refreshes only generated defaults. It never replaces an existing primary file, deployment include tree,
or executable. Calibration continues to persist in the selected primary file.

Includes are expanded in order and later values win. Relative `.conf` includes must stay below their including
file's directory and respect the depth/cycle checks. Quote values containing significant spaces. An explicit
configuration path is a complete entry point: Boot does not implicitly merge another deployment file.

Existing runtimes with `runtime/picar-x.d` are preserved byte-for-byte. Their old includes remain authoritative;
new defaults are staged under `runtime/generated` but cannot replace those potentially commissioned settings. To
opt into refreshed defaults, review the old fragments against `generated/picar-x.d`, retain your deployment values
in the primary file, and replace its old baseline includes with `include = generated/picar-x.conf` before those
overrides. This migration is deliberately manual so configure cannot discard unknown calibration or settings.

The tool's `rpi-defaults.conf` supplies full-product `XWALK_RPI_*` settings. Reconfigure with explicit
`-D XWALK_RPI_GPIO_DEVICE=...`, `-D XWALK_RPI_PROFILE=...`, or other deployment options to update generated
defaults. Full-product `XWALK_RPI_*` values take precedence over cached `XWALK_CONTROLLER_RPI_*` profile values.
Standalone Controller accepts `XWALK_CONTROLLER_RPI_*`; these explicit overrides remain cached. To clear legacy
inherited Controller cache entries, use `-U 'XWALK_CONTROLLER_RPI_*'` and reapply any intended standalone
overrides.

HOST profiles retain build-local disabled device paths and an empty device-tree fixture. The host stream provider
keeps its in-memory source defaults because the real stream validator accepts only actual V4L2 syntax or CSI. No
host Boot provider opens those devices. GPIO placeholders alone are not a hardware sandbox.

### Runtime setting audit

| Settings | Native Boot behavior |
| --- | --- |
| `resource_sound_directory`, `resource_music_directory` | Passed to SoundBackgroundMusic |
| `camera_output`, width, height, timeout | Passed to the still camera and capture coordinator |
| Old `sound_directory`, `music_directory`, `camera_output_path` | Fallback aliases; established keys win |
| Pan, tilt, steering, v4/v5 motor PWM keys | Parsed by the HAL channel parser before providers open |
| Battery and grayscale ADC keys | Parsed before providers open; BoardControl still requires battery A4 |
| PWM ownership | One shared timer state; duplicate channels and cross-role timer conflicts are rejected |
| RGB P4/P5/P6 and buzzer P8 | Fixed auxiliary outputs remain reserved; no configuration keys exist |
| SPI speed/mode/word size, GPIO identity checks | Passed to validated Linux constructors |
| Audio capture/playback/mixer, Piper/Vosk paths | Passed to native providers; packaged Vosk paths preserved |
| Vosk endpoint timing, silence threshold, transcript opt-in | Passed to the ALSA recognizer configuration |
| Computer vision and recording settings | Backend, source, output paths, size, FPS and timeout reach OpenCV |
| Video-stream settings | CSI/V4L2 selection, dimensions, JPEG/timeout, listener and queue limits |
| App-control identity, port and video URL | Passed to the coordinator configuration; bind policy retained |
| Generic language-model profile | Provider, endpoint, model/key environment, timeout and output bound |

Pan, tilt, steering and motor PWM parsing retains board topology. The language-model environment name wins when it
resolves to a nonempty model; otherwise the explicit generic model and legacy `boot_llm_model`/`voice_ollama_model`
values are used. No model or credential is logged or persisted. Native Ollama and the repository OpenAI-compatible
profiles use their configured HTTP dialect; unknown provider names are rejected. Provider endpoint/dialect
compatibility still needs deployment validation. Legacy `boot_llm_endpoint`/`voice_ollama_endpoint` remain
fallback keys.

TextVisionTalk uses a separate native Ollama provider configured by `text_vision_ollama_endpoint`,
`text_vision_ollama_model` and `text_vision_timeout_ms`. Defaults are `http://127.0.0.1:11434/api/chat`,
`llava:7b` and 120000 ms; the timeout accepts 1–300000 ms. The deployment must supply the configured image-capable
model. Host Boot retains fake providers for both language-model consumers.

`camera_csi_device` is deployment/diagnostic metadata: rpicam selects its camera itself and has no media-node
argument in this adapter. Still capture, MJPEG streaming, computer vision and recording have separate backend
keys. The tracked vision configuration selects quoted CSI GStreamer pipelines for computer vision and recording.
USB runtime generation selects `v4l2` and `/dev/video0` for both consumers; provider fallbacks remain V4L2 when
settings are absent. Selecting a CSI still camera does not silently rewrite another camera consumer's device.
Quote each pipeline value: the flat parser removes spaces from unquoted values, which would corrupt GStreamer
element arguments. A CSI deployment may require target-specific `LD_LIBRARY_PATH` and `GST_PLUGIN_PATH` entries
for locally installed libcamera/GStreamer libraries and plugins. Inspect those directories on the target and
preserve existing environment entries when composing its launcher. Match recording pipeline frame rate to
`video_recording_fps`; these settings do not verify camera discovery or installed plugins, and target paths must
not replace host defaults.

The `voice_espeak_*` and `treasure_hunt_*` speech-provider keys describe alternative example providers; current
Boot uses its shared Piper adapter. The numerous example-specific AI feature settings still need separate
request/coordinator wiring; they are not advertised as active native Boot overrides. Generic profile settings apply
to the shared language model. Motor calibration gates, output limits, watchdog and explicit lifecycle activation
remain in the PiCar-X consumer without changed safety policy.

### Refresh and compile on the Pi

From the integrated repository root, these commands configure and build without starting the robot:

```bash
cmake --preset rpi5-native -S xWalk-rpi5-node/xWalkIoT
cmake --build xWalk-rpi5-node/build-rpi5-native --parallel 4
```

Use `-D XWALK_PICARX_CONFIG_FILE=/absolute/operator/picar-x.conf` on configure for another primary file. Existing
runtime overrides survive both commands. Confirm the configure log's `Controller configuration` path. Only build on
the Pi with its existing dependencies; these commands do not install packages or provision services. Before
separately authorized runtime use, validate the selected Robot HAT wiring/calibration, GPIO/I2C/SPI permissions,
CSI executable and GStreamer provider, audio devices, Vosk library/model, Piper model and required model
environment. No physical-device execution is implied by successful host tests or native-backend compilation.

## 7. Testing

Boot host tests are registered only when `XWALK_CONTROLLER_BUILD_HOST_TESTS` and `XWALK_CONTROLLER_BUILD_HOST` are
both enabled. Sources and `<Component>TestSupport` files are in the parent `test` directory.

| CTest name | Labels | Coverage |
| --- | --- | --- |
| `xWalkControllerBootHostTest` | `host;controller;boot` | Simulated construction, partial failure, rollback |
| `xWalkControllerBootConfigurationHostTest` | `host;controller;boot` | Configuration file selection |
| `xWalkControllerConfigurationCmakeHostTest` | `host;controller;boot` | CMake configuration generation script |
| `xWalkControllerOperationHostTest` | `host;controller;boot` | Initialization and operation cleanup |
| `xWalkControllerOperationPowerHostTest` | `host;controller;boot` | Mode power updates and sensor reads |
| `xWalkControllerOperationCancellationHostTest` | `host;controller;boot` | Cancellation and STOP (60 s) |
| `xWalkControllerOperationCompletionHostTest` | `host;controller;boot` | Follow-up admission after completion |
| `xWalkControllerOutcomeHostTest` | `host;controller;outcome` | 38 CFM/REJ mappings and single delivery |
| `xWalkControllerAnnouncementHostTest` | `host;controller;boot` | Announcement storage and scheduled replay |
| `xWalkControllerAnnouncementConcurrencyHostTest` | `host;controller;boot` | Announcement lane concurrency |
| `xWalkControllerVideoSessionHostTest` | `host;controller;boot` | Background video session |
| `xWalkControllerWorkerPlacementHostTest` | `host;controller;boot` | Functional CPU placement |
| `xWalkControllerServiceConcurrencyHostTest` | `host;controller;boot` | Service requests beside vehicle work |
| `xWalkControllerProximityOperationHostTest` | `host;controller;safety` | Front-proximity pause and recovery |
| `xWalkControllerBatteryHostTest` | none | Battery sampling and averaging |

The cancellation regression uses silent backend barriers to verify normal completion, user and lifecycle STOP,
owner shutdown during execution and cleanup, callback cancellation/failure, duplicate rejection, independent
correlation, motor disarming, idle STOP and restart. Its reusable barriers and response snapshots live in
`xControllerOperationTestSupport.h/.cpp`. The outcome test checks all 38 CFM/REJ mappings, original correlation and
single-delivery behavior under success, failure, warning, error, mixed severity and failed transport. The placement
test checks all four single-CPU masks, nested service-to-voice worker creation, invalid roles, and rejection when
the captured CPU set has fewer than four members. Provider-specific host tests cover stalled HTTP and owned speech
children within a two-second acceptance bound; this does not establish a universal or measured Pi STOP latency:
camera, recognition, other injected providers, synchronous DNS builds, and kernel uninterruptible I/O can retain
separate blocking boundaries.

```bash
ctest --preset host -L boot --output-on-failure
```

Boot has no hardware-labelled tests of its own; discover any hardware tests with `ctest -N -L hardware`.

## 8. Dependencies

- `xWalkController` (parent scheduling library) and `xWalkUtilsLinux`.
- `bootModuleLibraries` from [xWalkDriver](../../xWalkDriver/xWalkDriver.md) and
  [xWalkHal](../../xWalkHal/xWalkHal.md) coordinators and devices; see [Boot module ownership](Modules.md).
- HOST: `xWalkRobotHatSimulation` ([xWalkRobotHat](../../xWalkHal/simulation/xWalkRobotHat/xWalkRobotHat.md)).
- RPI5: `xWalkI2cLinux`, `xWalkGpioLinux`, `xWalkSpiLinux`, `xWalkCameraLinux`, `xWalkCameraStreamOpenCv`,
  `xWalkAudioAlsa`, `xWalkMusicAlsa`, `xWalkMusicSndFileDecoder`, `xWalkSpeakerAlsa`, `xWalkSpeechRecognizerVosk`,
  `xWalkSpeechToTextAlsa`, `xWalkTextToSpeechPiper`, `xWalkLanguageModelOllama`, `xWalkComputerVisionOpenCv`,
  `xWalkVideoRecordingOpenCv` and `xWalkAppControlWebSocket`.

## 9. Safety and constraints

### Front proximity safety

The Pi Boot owner starts a dedicated ultrasonic monitor before admitting commands. It defaults to 80 mm front
clearance (`proximity_stop_mm`) with configurable sensor setback (`proximity_sensor_inset_mm`). Invalid/stale
samples and same-user `AllStop` IPC requests inhibit the paired motor HAL and cancel the current operation without
waiting for normal request queues. The inhibit survives lifecycle requests and rejects subsequent actuator
operations with a nonmodal proximity-pause reason. Read-only sensor requests continue through the service path
without clearing cancellation or rearming motors.

During a pause, distance reporting uses the shared ultrasonic observer, with a 250 ms freshness limit, rather than
the retrying reader. Replies carry `proximity_blocked` and either a valid distance or an explicit stale/no-echo
status; no distance is fabricated from an invalid echo. Battery and grayscale reporting remain available.
Proximity freshness uses each ultrasonic acquisition's original trigger timestamp, including samples completed by
ordinary sensor requests, so concurrent reads cannot hide fresh acquisitions from the safety worker and repeated
observation of cached data cannot keep a stale sensor safe.

After one second of fresh clearance above 100 mm or fresh finite negative raw readings, the owner can release
inhibition at zero output. Negative raw readings are policy-defined open road, not measured clearance; this
includes error sentinels and can mask sensor faults. Zero, non-finite, failed and stale readings still stop.
Positive readings inside the sensor setback remain obstacles. Camera assessments never gate recovery. IPC stops
additionally require fresh traffic `Clear` reports. Active autonomous modes resume after cleanup, retaining their
last accepted power. Explicit Stop or shutdown cancels the paused session; timed actions are not replayed. Host
Boot leaves this monitor disabled unless `proximity_stop_enabled = 1` is set.

A front-proximity pause permits an explicit manual reverse escape while lifecycle is ACTIVE and prior operation
cleanup is complete. Reverse uses its own 200–1000 ms lease and calibrated steering/power; normal motor arming and
forward commands remain inhibited. Repeated front-stop samples preserve a current reverse lease. Release, STOP or
shutdown cancels it; lack of renewal or clock rollback stops it. Heartbeat cannot prolong the reverse lease.
Recovery of paused autonomous work waits until reverse ends. This is a front-obstacle exception, not permission to
bypass an explicit lifecycle stop or hardware fault.

Traffic-controller integration and the local protocol are documented in
[xWalkProximity](../../../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkProximity/xWalkProximity.md). Hardware tests must
measure stopping latency and braking distance; the threshold alone cannot guarantee collision avoidance.

### General constraints

- RPI5 Boot initializes physical device providers even for Health; deployment configuration, libraries, models and
  device permissions must be ready before startup.
- Construction never arms the vehicle; only an accepted lifecycle `ACTIVE` request initializes it.
- Cancellation is cooperative; blocking backend calls must return before cleanup completes.
- Do not use HOST motion examples on connected hardware without commissioning it first.

## 10. Related notes

- [xWalkController](../xWalkController.md)
- [Boot module ownership](Modules.md)
- [xWalkStandAlone](../xWalkStandAlone/xWalkStandAlone.md)
- [xWalkDriver](../../xWalkDriver/xWalkDriver.md), [xWalkHal](../../xWalkHal/xWalkHal.md)
- [xWalkIoT](../../../../05-xwalk-node/xWalk-rpi5-node/xWalkIoT/xWalkIoT.md)

---

[Previous page](../xWalkController.md) · [Chapter index](../../../index.md) · [Next page](Modules.md)
