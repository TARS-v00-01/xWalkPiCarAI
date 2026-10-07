<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkGPT
Simulation

**2. xWalk hardware &middot; Module 91**

<!-- xwalk-page-header:end -->

# xWalkGPT Simulation

Device-free executable that exercises speech recognition, file transcription, cancellation, speaker priming,
and speech output through in-memory callbacks. It opens no microphone, speaker, ALSA device, Vosk model,
synthesis provider, process, or network.

## 1. Overview

`xWalkGptSimulation` composes the real `XWalkSpeechToText`, `XWalkTextToSpeech`, and `XWalkBoardControl`
classes over the `XWalkGptHostStub` backend. The stub supplies GPIO, I2C, speaker-priming, recognition, and
synthesis callbacks. One run performs a 100 ms `listen()`, a `transcribeFile()` call, `stop()`, and one
`speak()` call, then validates the recorded results and callback counts. The process returns `0` when every
check passes and `1` otherwise.

The simulation emits trace IDs `RPI.363` through `RPI.365`.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkGPT/simulation` —
source directory

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                               Standalone project and trace catalogue generation
├── config/
│   └── xHal_Rpi5CarGptTraceConfig.py            Validates and merges the persistent trace catalogue
├── include/
│   ├── xHal_Rpi5CarGptHostStub.h                In-memory GPIO, I2C, STT, and TTS backend
│   ├── xHal_Rpi5CarGptSimulation.h              Scenario entry point
│   ├── xHal_Rpi5CarGptSimulationArguments.h     Command-line parser
│   └── xHal_Rpi5CarGptSimulationConfig.h        Default trace configuration and log paths
└── src/
    ├── main.cpp                                 Argument handling, trace setup, and scenario run
    ├── xHal_Rpi5CarGptHostStub.cpp
    ├── xHal_Rpi5CarGptSimulation.cpp
    └── xHal_Rpi5CarGptSimulationArguments.cpp
```

## 4. Build

The project adds the parent module and forces `XWALK_GPT_BUILD_HOST_TESTS` and
`XWALK_GPT_BUILD_HARDWARE_TESTS` to `OFF`. Run these commands from this `simulation` directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkGptSimulation --parallel
./build-host/xWalkGptSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no arguments, `--help` or `-h`, or `--trace <selector>`:

| Selector | Effect |
|---|---|
| `RPI.enable`, `RPI.disable` | Changes the default state of every `RPI` trace |
| `all.enable`, `all.disable` | Changes every trace |
| `RPI.<number>.enable`, `RPI.<number>.disable` | Changes one trace, for example `RPI.363.enable` |
| `<file>.json` | Applies a JSON trace selection file |

The build runs `config/xHal_Rpi5CarGptTraceConfig.py` to produce `build-host/generated/xWalkGptTrace.xml` from
the shared trace inventory. The generator preserves previously saved global, module, and trace states and
fails when no xWalkGPT trace is present. Trace changes persist in this XML, so a later run without a selector
loads them. Enabled messages appear in the terminal and `build-host/log/xWalkGptSimulation.log`.

## 6. Testing

The simulation is a manual executable and is not registered with CTest. The module host test
`xWalkSpeechToTextHostTest` compiles `xHal_Rpi5CarGptSimulationArguments.cpp` to cover argument parsing.

## 7. Dependencies

- Parent `xWalkGPT` library and, through it, `xWalkBoardControl`, `xWalkGpio`, `xWalkI2c`, and `xWalkAdc`.
- `xWalkTrace` and its `xWalkTraceMetadata` inventory target.
- Python 3 for trace catalogue generation.

## 8. Safety and constraints

The executable is host-only and uses no Raspberry Pi device, audio hardware, speech model, or external
process. It does not validate real recognition accuracy, synthesis, or acoustic output.

## 9. Related notes

- [xWalkGPT](../xWalkGPT.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkGPT.md) · [Chapter index](../../../../../index.md) · [Next page](../../test/xWalkHal%20Layer1%20Tests.md)
