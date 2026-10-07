<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) /
xWalkVoiceAssistant Simulation

**2. xWalk hardware &middot; Module 100**

<!-- xwalk-page-header:end -->

# xWalkVoiceAssistant Simulation

The `xWalkVoiceAssistantSimulation` executable composes the voice-assistant coordinator with in-memory GPIO,
I2C, recognition, language-model, and speech-output callbacks and performs one complete listen, model, and
speech round.

## 1. Overview

`XWalkVoiceAssistantHostStub` supplies every dependency required by the round. The simulation opens no
microphone, ALSA device, Ollama endpoint, provider process, filesystem input, or network connection and produces
no audio.

Trace changes requested on the command line persist in a generated XML catalogue, and a later run without a
selector loads the saved state. Enabled messages appear in the terminal and in
`build-host/log/xWalkVoiceAssistantSimulation.log`. The simulation emits trace IDs `RPI.380` (start).

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/layer1/xWalkVoiceAssistant/simulation`
(source directory)

## 3. Directory layout

```text
simulation/
├── CMakeLists.txt                  Standalone simulation project
├── config/                         Persistent trace catalogue generator script
├── include/
│   ├── *HostStub.h                 In-memory dependencies used by the scenario
│   ├── *SimulationArguments.h      --help and --trace parsing
│   ├── *SimulationConfig.h         Default trace and log paths
│   └── *Simulation.h               Scenario entry point
└── src/
    ├── main.cpp                    Trace configuration, argument handling, and scenario run
    └── *.cpp                       HostStub, SimulationArguments, and Simulation implementations
```

Every header and source file carries the `xHal_Rpi5CarVoiceAssistant` prefix.

## 4. Build

The project adds the parent module with its host and hardware test options forced `OFF`. Run these commands from
this `simulation` directory:

```bash
cmake -S . -B build-host -DCMAKE_BUILD_TYPE=Debug
cmake --build build-host --target xWalkVoiceAssistantSimulation --parallel
./build-host/xWalkVoiceAssistantSimulation --trace RPI.enable
```

## 5. Configuration

The executable accepts no argument, `--help` or `-h`, or `--trace <selector>`:

- `<target>.enable` or `<target>.disable`, where the target is `RPI`, `all`, or `RPI.<number>`.
- A path ending in `.json`, applied as a global trace argument.

An invalid argument, or a selector whose identifier is absent from the trace inventory, exits with status 2.

At build time, the script `config/xHal_Rpi5CarVoiceAssistantTraceConfig.py` validates the workspace trace inventory
and merges it into `generated/xWalkVoiceAssistantTrace.xml`, preserving the global, module, and per-trace states
saved by earlier runs. CMake passes build-local paths through compile definitions; the configuration header
supplies source-visible defaults.

- `XWALK_VOICE_ASSISTANT_SIMULATION_TRACE_CONFIG_PATH`: header default `xwalk-traces.xml`, build value
  `<build>/generated/xWalkVoiceAssistantTrace.xml`.
- `XWALK_VOICE_ASSISTANT_SIMULATION_TRACE_LOG_PATH`: header default `log/xWalkVoiceAssistantTrace.log`, build value
  `<build>/log/xWalkVoiceAssistantSimulation.log`.

## 6. Testing

The simulation itself is not registered with CTest. Its argument parser is also compiled into the module host
test, and `xGoogleTest` checks its trace-argument boundaries in `TEST_SUITE_XWALK_SIMULATION`.

## 7. Dependencies

- `xWalkVoiceAssistant` and `xWalkTrace`.
- Python 3 for trace-catalogue generation, and the `xWalkTraceMetadata` target for the trace inventory.

## 8. Safety and constraints

The simulation is host-only and device-free. It opens no device, model, process, filesystem input, or network
connection and produces no audio.

## 9. Related notes

- [xWalkVoiceAssistant](../xWalkVoiceAssistant.md)
- [xWalkHal Layer1](../../xWalkHal%20Layer1.md)
- [xWalk-rpi5-trace](../../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkVoiceAssistant.md) · [Chapter index](../../../../../index.md) · [Next page](../../../sensor/xWalkHal%20Sensor%20Layer.md)
