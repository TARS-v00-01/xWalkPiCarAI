<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkSelfDrive

**2. xWalk hardware &middot; Module 24**

<!-- xwalk-page-header:end -->

# xWalkSelfDrive

`xWalkSelfDrive` is a C++17 Agent coordinator for the named gesture, short movement, horn, engine-start,
background-music, status, queue, and worker behavior while keeping platform and hardware ownership outside the
module.

## 1. Overview

- accepts the exact upstream movement names: `shake head`, `nod`, `wave hands`, `resist`, `act cute`,
  `rub hands`, `think`, `twist body`, `celebrate`, `depressed`, `forward`, `backward`, and `stop`;
- accepts the upstream sound names `honking` and `start engine`;
- accepts `play background music` and `stop background music` for the configured packaged song;
- preserves servo angles, motor commands, delay intervals, action names, and sound volumes;
- provides synchronous `doAction()` plus explicit standby, think, queued-actions, start, stop, and wait flow;
- injects timing and stores non-owning PiCar-X and Music pointers instead of owning hardware or audio
  resources;
- rejects unknown queued actions without executing or storing them;
- optionally checks a controlling-thread cancellation callback during delays in slices no longer than
  20 milliseconds;
- divides each one-second forward or backward action into 100-millisecond intervals that refresh the motor
  watchdog without weakening its configured timeout; and
- reports a worker delay failure as a Boolean completion status and lets ordinary synchronous failures escape
  after command-scope actuator cleanup has run.

Standby is an explicit idle state. It does not select random intervals, enqueue actions, play sounds, or move
an actuator. The unused upstream completed-actions state was removed; queue completion transitions directly to
standby and wakes waiting callers.

Voice-requested `stop` is queued through the worker with every other action. It therefore waits for an active
thinking pose to finish before touching the PiCar-X motors and cannot race the worker's actuator writes.

### Audio resources

The preset sound actions resolve `car-double-horn.wav` and `car-start-engine.wav` below the constructor's sound
directory. The root-level xWalkAudioResources directory
supplies development assets and provenance; installed composition uses `/usr/share/xwalk/sounds` by default
(`resource_sound_directory` in the Controller configuration). A missing or unreadable regular file rejects its
action before playback or movement.

The background-music action resolves `slow-trail-Ahjay_Stelino.mp3` below the constructor's music directory,
uses twenty-percent volume, and can be stopped idempotently. Coordinator shutdown also stops music that it
started. Installed composition uses `/usr/share/xwalk/music` by default (`resource_music_directory`).

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVehicle/xWalkSelfDrive`
(source directory)

## 3. Directory layout

```text
xWalkSelfDrive/
    CMakeLists.txt                                  Library, alias, and host test registration
    include/
        xAgent_Rpi5CarSelfDrive.h                   Preset-action, queue, worker, and dependency contract
        xAgent_Rpi5CarSelfDriveTypes.h              Status enumeration and injected callbacks
    src/
        xAgent_Rpi5CarSelfDriveActions.cpp          Exact action-name dispatch, movement, and sound actions
        xAgent_Rpi5CarSelfDriveGestures.cpp         Ordered steering, camera, and motor gesture sequences
        xAgent_Rpi5CarSelfDriveLifecycle.cpp        Dependency validation and worker ownership
        xAgent_Rpi5CarSelfDriveWorker.cpp           Status transitions and first-in, first-out processing
    test/
        include/xAgent_Rpi5CarSelfDriveTestSupport.h  Reusable deterministic fake state and callbacks
        src/xAgent_Rpi5CarSelfDriveTestSupport.cpp    Deterministic callback and fake-clock implementations
        src/xAgent_Rpi5CarSelfDriveTest.cpp           Gesture, watchdog, sound, validation, and queue tests
```

## 4. Public interface

`xwalk::agent::XWalkSelfDrive` is constructed from an `XWalkPicarx&`, a `hal::XWalkMusic&`, a callback context,
a required `noexcept` delay callback returning `bool`, an optional continuation callback, and the sound
directory, music directory, and background-music filename. The directory defaults are
`../xWalkAudioResources/sounds` and `../xWalkAudioResources/music`.

| Member | Behavior |
| --- | --- |
| `doAction(action)` | Runs one named action synchronously |
| `addAction(action)` | Queues a supported action; rejects unknown names |
| `start()` / `stop()` | Starts or stops the worker thread |
| `setStatus(status)` / `status()` | Selects or reports `Standby`, `Think`, or `Actions` |
| `waitActionsDone()` | Waits for the queue; returns `false` after a worker delay failure |
| `setCancellation(context, continueOperation)` | Binds the controlling-thread cancellation callback |
| `running()` | Reports whether the worker is running |

## 5. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_SELF_DRIVE_BUILD_HOST_TESTS` | `OFF` | Builds and registers the host test |
| `XWALK_SELF_DRIVE_BUILD_HARDWARE_TESTS` | `OFF` | Compiles with Linux/RPi dependencies; Linux only |
| `XWALK_SELF_DRIVE_HAL_ROOT` | `../../../xWalkHal` | HAL source tree used for `xWalkMusic` |

The module builds `xWalkSelfDrive` (alias `xWalk::SelfDrive`) and adds `xWalkPicarx` and `xWalkMusic` when the
targets are not already defined.

## 6. Testing

`xWalkSelfDriveHostTest` (label `host`) uses the development sound and music directories from
`xWalkAudioResources` and a writable configuration path below the build directory's `test-data`:

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkSelfDriveHostTest
```

`XWALK_SELF_DRIVE_BUILD_HARDWARE_TESTS=ON` only compiles the module and its Linux/RPi dependencies; the module
does not register a physical preset-action test because automatically running its gesture catalog would be
unsafe.

## 7. Dependencies

- [xWalkPicarx](../xWalkPicarx/xWalkPicarx.md) and [xWalkMusic](../../../xWalkHal/layer1/xWalkMusic/xWalkMusic.md)
  (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 8. Safety and constraints

Every gesture can move steering, camera servos, or drive motors. Configure the cancellation callback before
starting movement. Cancellation latches the shared PiCar-X emergency stop, attempts both motors independently,
and suppresses later actuator commands in the current action. The application command boundary owns the
non-throwing safety guard that performs the same cleanup during normal return and stack cleanup. The worker
delay callback returns `false` on failure; this performs emergency shutdown and makes `waitActionsDone()`
return `false` to the controlling thread. A failed movement heartbeat follows the same stopped and disarmed
status path, preventing a later queued action from reaching a disarmed motor command. No exception-handling
statement is required. Call direct action methods and queue-control methods from one controlling context.

The module emits `RPIAGENT.002` through `RPIAGENT.009` for lifecycle, worker, and action events and
`RPIAGENT.083` for gestures; see the [Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 9. Related notes

- [xWalkVehicle](../xWalkVehicle.md)
- [xWalkAudioResources](../../../xWalkAudioResources/xWalkAudioResources.md)
- [xWalkSoundBackgroundMusic](../../xWalkMedia/xWalkSoundBackgroundMusic/xWalkSoundBackgroundMusic.md)

---

[Previous page](../xWalkPicarx/xWalkPicarx.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkVision/xWalkVision.md)
