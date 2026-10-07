<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) /
xWalkSoundBackgroundMusic

**2. xWalk hardware &middot; Module 16**

<!-- xwalk-page-header:end -->

# xWalkSoundBackgroundMusic

`xWalkSoundBackgroundMusic` ports upstream `example/13.sound_background_music.py` through one caller-owned
`XWalkMusic`. It toggles background music and plays the horn synchronously or in the background.

## 1. Overview

The `q` key toggles the supplied MP3, space plays the horn synchronously, and `c` starts the horn in the
background. Letter keys are case-insensitive; other input is ignored. Both horn operations preserve the
source's 50-millisecond post-play delay, which polls cancellation in slices no longer than 20 milliseconds.

The Agent resolves reviewed sound and music assets below caller-owned resource directories, sets
streamed-music volume to 20 percent at startup, and stops active music during normal or cancelled cleanup. It
owns no ALSA device, decoder, terminal, worker, or filesystem deployment policy.

The Raspberry Pi application keeps `SIGINT` and `SIGTERM` on its Controller thread. ALSA playback workers block
those signals, allowing `Ctrl+C` to interrupt terminal input and complete the same joined cleanup path as `x`.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkMedia/xWalkSoundBackgroundMusic`
(source directory)

## 3. Directory layout

```text
xWalkSoundBackgroundMusic/
    CMakeLists.txt                                     Library and alias
    include/
        xAgent_Rpi5CarSoundBackgroundMusic.h           Public coordinator contract
        xAgent_Rpi5CarSoundBackgroundMusicTypes.h      Callbacks, events, configuration, and result
    src/
        xAgent_Rpi5CarSoundBackgroundMusic.cpp         Key handling and playback
        xAgent_Rpi5CarSoundBackgroundMusicLifecycle.cpp  Validation, start, finish, and cancellable waits
```

## 4. Public interface

`xwalk::agent::XWalkSoundBackgroundMusic` (non-copyable, non-movable) is constructed from a
`hal::XWalkMusic&`, a callback context, required delay and continuation callbacks, the sound and music
directories, and an optional `XWalkSoundBackgroundMusicConfiguration`.

| Member | Behavior |
| --- | --- |
| `start()` | Returns `false` unless both assets are readable regular files; sets the music volume |
| `handleKey(key)` | Applies one key and returns the event and music state |
| `finish()` | Stops active music and clears the started state |
| `started()` | Reports the started state |

`handleKey()` before `start()` is a logic error. `XWalkSoundBackgroundMusicEvent` values are `Ignored`,
`MusicStarted`, `MusicStopped`, `SoundPlayed`, `BackgroundSoundStarted`, and `Cancelled`. Cancellation stops
active music.

## 5. Configuration

| Field | Default | Valid range |
| --- | --- | --- |
| `hornFilename` | `car-double-horn.wav` | Non-empty |
| `musicFilename` | `slow-trail-Ahjay_Stelino.mp3` | Non-empty |
| `musicVolumePercent` | 20.0 | Finite, 0 through 100 |
| `postSoundDelayMs` | 50 | At most 1,000 milliseconds |

## 6. Build

The module has no options of its own. It builds `xWalkSoundBackgroundMusic` (alias
`xWalk::SoundBackgroundMusic`) and adds the `xWalkMusic` HAL with host tests, ALSA backend, and sndfile decoder
off by default when the target is not already defined.

## 7. Testing

The module registers no standalone test. The [xWalkMedia](../xWalkMedia.md) group host suite verifies the
default configuration contract.

## 8. Dependencies

- [xWalkMusic](../../../xWalkHal/layer1/xWalkMusic/xWalkMusic.md) (public).
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md) (private).

## 9. Safety and constraints

The caller-owned `XWalkMusic` must outlive the Agent; the Agent moves no actuator. The module emits
`RPIAGENT.018` when its resources are validated and it starts; see the
[Agent trace table](../../xWalkDriver.md#runtime-tracing).

## 10. Related notes

- [xWalkMedia](../xWalkMedia.md)
- [xWalkAudioResources](../../../xWalkAudioResources/xWalkAudioResources.md)
- [xWalkSelfDrive](../../xWalkVehicle/xWalkSelfDrive/xWalkSelfDrive.md)

---

[Previous page](../xWalkMedia.md) · [Chapter index](../../../../index.md) · [Next page](../../xWalkVehicle/xWalkVehicle.md)
