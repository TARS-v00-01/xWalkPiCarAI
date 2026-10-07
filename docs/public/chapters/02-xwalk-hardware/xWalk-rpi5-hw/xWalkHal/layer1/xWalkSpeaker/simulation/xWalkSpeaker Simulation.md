<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkSpeaker
Simulation

**2. xWalk hardware &middot; Module 98**

<!-- xwalk-page-header:end -->

# xWalkSpeaker Simulation

Silent executable that composes the public Speaker API over an in-memory decoder and stream backend. It
creates one temporary fixture below the build tree, does not open ALSA, and cannot produce physical sound.

## 1. Overview

`xWalkSpeakerSimulation` writes an empty fixture at `build-host/speaker-simulation.wav`, constructs
`XWalkSpeaker` over `XWalkSpeakerHostStub`, starts one playback task, waits 5 ms, and confirms that the task
list is empty. After the controller is destroyed it removes the fixture and validates one enable, one disable,
one decode, one stream open, two writes, and one stream close. The process returns `0` on success or `1` on
failure. Task identifiers use the form `speaker-simulation-<n>`.

The simulation emits trace IDs `RPI.316` through `RPI.318`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkSpeaker/simulation` —
source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                                   Standalone project and trace catalogue generation
├── config/
│   └── xHal_Rpi5CarSpeakerTraceConfig.py            Validates and merges the persistent trace catalogue
├── include/
│   ├── xHal_Rpi5CarSpeakerHostStub.h                In-memory decoder and stream backend with counters
│   ├── xHal_Rpi5CarSpeakerSimulation.h              Scenario entry point
│   ├── xHal_Rpi5CarSpeakerSimulationArguments.h     Command-line parser
│   └── xHal_Rpi5CarSpeakerSimulationConfig.h        Default trace, log, and fixture paths
└── src/
    ├── main.cpp                                     Argument handling, trace setup, and scenario run
    ├── xHal_Rpi5CarSpeakerHostStub.cpp
    ├── xHal_Rpi5CarSpeakerSimulation.cpp
    └── xHal_Rpi5CarSpeakerSimulationArguments.cpp
```

## 4. Build

The project adds the parent module and forces `XWALK_SPEAKER_BUILD_HOST_TESTS`,
`XWALK_SPEAKER_BUILD_HARDWARE_TESTS`, and `XWALK_SPEAKER_BUILD_ALSA_BACKEND` to `OFF`, so no ALSA dependency is
required. Run these commands from this `simulation` directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkSpeakerSimulation --parallel
./build-host/xWalkSpeakerSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`:

| Selector | Effect |
|---|---|
| `RPI.enable`, `RPI.disable` | Changes the default state of every `RPI` trace |
| `all.enable`, `all.disable` | Changes every trace |
| `RPI.<number>.enable`, `RPI.<number>.disable` | Changes one trace, for example `RPI.316.enable` |
| `<file>.json` | Applies a JSON trace selection file |

The build runs `config/xHal_Rpi5CarSpeakerTraceConfig.py` to produce
`build-host/generated/xWalkSpeakerTrace.xml` from the shared trace inventory, preserving previously saved
states. Trace changes persist in this XML. Enabled messages appear in the terminal and
`build-host/log/xWalkSpeakerSimulation.log`.

## 6. Testing

The simulation is a manual executable and is not registered with CTest. The module host test
`xWalkSpeakerTest` compiles `xHal_Rpi5CarSpeakerSimulationArguments.cpp` to cover argument parsing.

## 7. Dependencies

- Parent `xWalkSpeaker` core library.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory target.
- Python 3 for trace catalogue generation.

## 8. Safety and constraints

The executable is host-only and silent. Its only filesystem side effect outside the trace and log files is
the temporary fixture below the build tree. It does not validate decoding, ALSA timing, or acoustic output.

## 9. Related notes

- [xWalkSpeaker](../xWalkSpeaker.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkSpeaker.md) · [Chapter index](../../../../../index.md) · [Next page](../../xWalkVoiceAssistant/xWalkVoiceAssistant.md)
