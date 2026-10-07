<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkMedia

**2. xWalk hardware &middot; Module 15**

<!-- xwalk-page-header:end -->

# xWalkMedia

`xWalkMedia` is the Media functional group of the xWalk Agent layer. It contains `xWalkSoundBackgroundMusic`,
which coordinates sound effects and background music through the shared music HAL, behind the
`xWalk::AgentMedia` interface target.

## 1. Overview

Audio device ownership remains in the HAL and Raspberry Pi composition rather than this Agent group.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkMedia`
(source directory)

## 3. Directory layout

```text
xWalkMedia/
    CMakeLists.txt                  Group options, xWalk::AgentMedia target, and group test registration
    test/
        src/                        xWalkDriverMediaGroupTest host suite
        hardware/src/               xWalkDriverMediaGroupHardwareTest hardware-profile suite
    xWalkSoundBackgroundMusic/      Horn and background-music coordinator
```

## 4. Child modules

| Note | Responsibility |
| --- | --- |
| [xWalkSoundBackgroundMusic](xWalkSoundBackgroundMusic/xWalkSoundBackgroundMusic.md) | Horn, music toggle |

## 5. Public interface

`xWalkDriverMedia` (alias `xWalk::AgentMedia`) is a C++17 `INTERFACE` target that links
`xWalkSoundBackgroundMusic`.

## 6. Build

| Option | Default | Effect |
| --- | --- | --- |
| `XWALK_AGENT_MEDIA_BUILD_HOST_TESTS` | `OFF` | Builds the group host suite |
| `XWALK_AGENT_MEDIA_BUILD_HARDWARE_TESTS` | `OFF` | Builds the hardware-profile group suite |

Either option includes `xWalkLibrary/XWalkDependencies.cmake` and requires GoogleTest.

## 7. Testing

`xWalkDriverMediaGroupHostTest` (labels `host`, `agent-group`) checks the `SoundBackgroundMusic` default
configuration contract directly, because the child module has no standalone test.

```bash
ctest --test-dir xWalk-rpi5-hw/xWalkDriver/build-host --output-on-failure -R xWalkDriverMediaGroupHostTest
```

`xWalkDriverMediaGroupHardwareTest` (labels `hardware`, `agent-group`) checks the RPi build graph. Discover
hardware tests with `ctest -N -L hardware`; do not run them without explicit approval and a confirmed safe
Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- [xWalkMusic](../../xWalkHal/layer1/xWalkMusic/xWalkMusic.md) music HAL.

## 9. Safety and constraints

Every Media child module owns a registered `RPIAGENT` lifecycle trace. Use the authoritative
[Agent trace table](../xWalkDriver.md#runtime-tracing) to select SoundBackgroundMusic without recording audio
data or resource paths.

## 10. Related notes

- [xWalkDriver](../xWalkDriver.md)
- [xWalkAudioResources](../../xWalkAudioResources/xWalkAudioResources.md)

---

[Previous page](../xWalkConnectivity/xWalkSpiTransfer/xWalkSpiTransfer.md) · [Chapter index](../../../index.md) · [Next page](xWalkSoundBackgroundMusic/xWalkSoundBackgroundMusic.md)
