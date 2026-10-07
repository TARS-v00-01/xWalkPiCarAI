<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkMusic
Simulation

**2. xWalk hardware &middot; Module 94**

<!-- xwalk-page-header:end -->

# xWalkMusic Simulation

Silent executable that composes the public Music API over an in-memory callback backend. It does not open
ALSA, read audio files, or produce physical sound.

## 1. Overview

`xWalkMusicSimulation` constructs `XWalkMusic` over `XWalkMusicHostStub`. One run sets a 3/4 time signature,
90 BPM tempo, and G major key; plays a sound effect, a background sound, and streamed music; pauses, resumes,
and stops the music; queries a sound length; and generates one short 440 Hz tone. It then validates the
recorded enable, playback, control, and tone counts and returns `0` on success or `1` on failure.

The simulation emits trace IDs `RPI.302` through `RPI.305`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkMusic/simulation` —
source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                 Standalone project and trace catalogue generation
├── config/
│   └── xHal_Rpi5CarMusicTraceConfig.py            Validates and merges the persistent trace catalogue
├── include/
│   ├── xHal_Rpi5CarMusicHostStub.h                In-memory audio callback backend with counters
│   ├── xHal_Rpi5CarMusicSimulation.h              Scenario entry point
│   ├── xHal_Rpi5CarMusicSimulationArguments.h     Command-line parser
│   └── xHal_Rpi5CarMusicSimulationConfig.h        Default trace configuration and log paths
└── src/
    ├── main.cpp                                   Argument handling, trace setup, and scenario run
    ├── xHal_Rpi5CarMusicHostStub.cpp
    ├── xHal_Rpi5CarMusicSimulation.cpp
    └── xHal_Rpi5CarMusicSimulationArguments.cpp
```

## 4. Build

The project adds the parent module and forces `XWALK_MUSIC_BUILD_HOST_TESTS`,
`XWALK_MUSIC_BUILD_HARDWARE_TESTS`, `XWALK_MUSIC_BUILD_ALSA_BACKEND`, and `XWALK_MUSIC_BUILD_SNDFILE_DECODER`
to `OFF`, so no ALSA or libsndfile dependency is required. Run these commands from this `simulation`
directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkMusicSimulation --parallel
./build-host/xWalkMusicSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`:

| Selector | Effect |
|---|---|
| `RPI.enable`, `RPI.disable` | Changes the default state of every `RPI` trace |
| `all.enable`, `all.disable` | Changes every trace |
| `RPI.<number>.enable`, `RPI.<number>.disable` | Changes one trace, for example `RPI.303.enable` |
| `<file>.json` | Applies a JSON trace selection file |

The build runs `config/xHal_Rpi5CarMusicTraceConfig.py` to produce `build-host/generated/xWalkMusicTrace.xml`
from the shared trace inventory, preserving previously saved states. Trace changes persist in this XML.
Enabled messages appear in the terminal and `build-host/log/xWalkMusicSimulation.log`.

## 6. Testing

The simulation is a manual executable and is not registered with CTest. The module host test
`xWalkMusicHostTest` compiles `xHal_Rpi5CarMusicSimulationArguments.cpp` to cover argument parsing.

## 7. Dependencies

- Parent `xWalkMusic` core library.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory target.
- Python 3 for trace catalogue generation.

## 8. Safety and constraints

The executable is host-only and silent. It does not validate decoding, ALSA timing, mixer behavior, or
acoustic output.

## 9. Related notes

- [xWalkMusic](../xWalkMusic.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkMusic.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkRobot/xWalkRobot.md)
