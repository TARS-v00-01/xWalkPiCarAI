<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [2. xWalk hardware](../../../index.md) / xWalkStandAlone

**2. xWalk hardware &middot; Module 06**

<!-- xwalk-page-header:end -->

# xWalkStandAlone

`xWalkStandAlone` builds the `xwalk-ctrl` terminal for the Controller. It runs bounded routing, confirmation and
rejection checks without MQTT or hardware access, decodes Protobuf JSON message samples, and, in HOST and RPI5
builds, runs the complete Boot runtime directly with `xwalk-ctrl run`. It also holds the 12 handler stubs that
replace the production request, CFM and REJ handlers in the Controller-only `module` build.

## 1. Overview

| Mode | Command | Boot | Purpose |
| --- | --- | --- | --- |
| Help | no arguments or `--help` | no | Show JSON-defined help |
| Request check | `--function <group> --count N` | no | Start four workers, submit, drain and count callbacks |
| CFM/REJ check | `--mode cfm` or `--mode reject` | no | Verify the no-adapter response path |
| JSON | `json --signal S [--file F]` | no | Decode one sample or custom JSON message |
| Runtime | `run [--signal S] [--config P] [--timeout-ms N]` | yes | Execute real operations, HOST or RPI5 |

Request mode starts all four functional workers, submits shared generated request structures, drains their FIFOs,
and verifies callback counts. Output uses the shared trace module and shows the actual Linux CPU for each selected
function. Four CPUs must be available in the process affinity mask. It exits automatically after the selected
checks. Verification commands do not construct devices; Driver completion and physical movement are not tested.

`xwalk-ctrl run` owns Boot directly for standalone operation. Node continues to own its own Boot instance when
using the MQTT application. The `module` build rejects `run` and retains its stubs.

## 2. Source location

`xWalk-rpi5-hw/xWalkController/xWalkStandAlone` —
source directory

## 3. Directory layout

```text
xWalkStandAlone/
├── CMakeLists.txt              # xwalk-ctrl target, JSON generation, sample copies and terminal tests
├── main.cpp                    # Terminal entry point
├── include/
│   ├── xControllerTerminal.h          # Terminal options and entry point
│   ├── xControllerTerminalMacros.h    # Terminal selections
│   ├── xControllerTerminalRuntime.h   # Standalone Boot execution and completion waiting
│   └── xControllerTerminalSupport.h   # Shared terminal helper declarations
├── src/
│   ├── xControllerTerminal.cpp          # Mode dispatch
│   ├── xControllerTerminalHelp.cpp      # JSON-defined help output
│   ├── xControllerTerminalOptions.cpp   # Option parsing and validation
│   ├── xControllerTerminalCallbacks.cpp # Request and rejection result recording
│   ├── xControllerTerminalRequest.cpp   # Bounded request submission and checks
│   ├── xControllerTerminalResponse.cpp  # CFM/REJ handler checks
│   └── xControllerTerminalRuntime.cpp   # Real Boot operations for run
├── stub/
│   ├── request/src/            # Four typed request/dispatch stub files (module build only)
│   ├── cfm/src/                # Four typed confirmation stub files
│   └── reject/src/             # Four typed rejection stub files
├── test/
│   └── xControllerFullRuntimeTest.py  # HOST full-runtime terminal test
└── xWalkConfig/
    ├── xWalkControllerHelp.json       # Terminal help text
    └── {request,cfm,reject}/{service,vehicle,vision,voice}/  # 114 Protobuf JSON samples
```

The terminal sources separate mode dispatch, help output, option parsing, callbacks, request execution and
response checks into `xControllerTerminal*.cpp` files. Shared declarations stay in
`xControllerTerminalSupport.h`.

## 4. Public interface

### Verification options

| Command options | Check |
| --- | --- |
| No arguments or `--help` | Show JSON-defined help |
| `--function service` | Health request |
| `--function vehicle --count 2` | Two Move requests, with sample speed 25 percent |
| `--function vision` | Vision request |
| `--function voice` | Sound request |
| `--function all --count 8` | All four groups |
| `--mode cfm --function all` | CFM returns unsent without a Node adapter |
| `--mode reject --function all` | REJ returns unsent without a Node adapter |

`--count` accepts 1–8 in request mode, avoiding deliberate FIFO overflow. CFM/reject modes require count 1; they
verify the no-adapter response path, not network publication. Exit codes are 0 for passed checks/help, 1 for a
failed check or worker startup, and 2 for invalid arguments. No arguments display help; use `--function all` to
start the bounded request test explicitly.

Help follows the Node CLI pattern: edit
`xWalkControllerHelp.json`.
CMake copies it to `<build-directory>/config` and installs it to `share/xwalk/help`; the terminal prints it through
the trace module's `XWALK_TRACE_HELP`. Rebuilding after a source JSON edit refreshes the copied help.

### JSON message samples

All 114 supported request, CFM and rejection signals (38 of each) have Protobuf JSON samples in
`xWalkConfig/{request,cfm,reject}/{service,vehicle,vision,voice}`. CMake copies these files into
`<build-directory>/config/controller`. Edit the source samples and rebuild, or use `--file` for a custom input.
Enum names, camelCase fields and base64 binary values match Node samples. The native Protobuf decoder validates the
JSON; generated CLI copies populate the plain structures. Protobuf dependencies belong to the terminal executable,
not the Controller scheduling library.

Each `json` invocation processes one message and exits. Request mode starts four workers and drains the selected
FIFO; it requires four allowed CPUs. CFM/reject invoke their typed handlers and check that no-adapter delivery
returns unsent. No hardware action or MQTT publication is performed. `--signal` accepts symbolic names or
decimal/hex IDs; optional `--function` must match the signal. Do not combine `json` with `--mode` or repeated
counts. Input is limited to 65,536 bytes. Missing, oversized or malformed files fail with a Controller warning.
Trace settings control whether the request JSON is printed.

In HOST and RPI5 builds, JSON mode installs a terminal adapter that prints the decoded typed message using
`XAGENT_FORMAT` at the Controller handler boundary, so HOST requests do not report a missing Driver adapter.
Responses remain unsent: the adapter prints input messages without executing Boot operations or publishing
confirmations. Module mode retains its formatted stub handlers.

### Standalone runtime

`run` initializes Boot, its shared HAL/Driver graph and Controller workers directly in this process. It requires no
Node process, MQTT broker or credentials. Commands return real operation CFM/REJ messages through the terminal
`XAGENT_FORMAT` callback. HOST uses simulated providers; RPI5 uses the configured physical devices and providers.

In the interactive terminal, enter a signal followed by an optional JSON file path:

```text
XWALK_HEALTH_REQ
XWALK_VERSION_REQ
quit
```

Boot remains alive between commands, preserving lifecycle state. `--config PATH` selects a Boot configuration file.
`--timeout-ms N` sets the per-request wait from 1 to 600000 ms (default 60000). A timeout or Ctrl+C stops the
session, cooperatively cancels the operation and joins workers before releasing providers. Cleanup still depends on
backend calls returning; this is not forced thread termination. EOF and `quit` also shut down Boot. Long
interactive voice operations may consume stdin while executing.

Single-request exit status is 0 for CFM, 1 for REJ/startup failure, 2 for invalid input, 124 for timeout and 130
for interruption. Interactive sessions retain nonzero command results.

### Terminal trace selection

`xwalk-ctrl` preserves the shared trace configuration when Boot or verification starts. Use a TraceEnable request
to explicitly select UIDs, modules or all normal traces. Ordinary CLI invocations do not re-enable GPIO polling
traces or overwrite an operator's selection. Warnings and errors remain available independently of normal traces.

### Module-build stubs

The `module` build substitutes the 12 files in `stub/{request,cfm,reject}/src` for the four functional groups'
request, CFM and reject implementations. They use the Controller declarations and are selected instead of the
production handlers, never linked alongside them. All stubs format their typed payloads with `XAGENT_FORMAT`.
CFM/reject stubs also trace the signal and size and return `false` because nothing is published. Stub output uses
the shared trace logger with category `MODULE`. A successful terminal exit means the Controller checks passed;
CFM/reject stubs still return `false` and report `not sent`. Keep these copies aligned with public Controller
signatures when adding or changing messages.

## 5. Build

`xwalk-ctrl` is built by the parent [xWalkController](../xWalkController.md#6-build) project and placed in the
Controller build directory. Controller CMake automatically invokes the shared `xWalkPyAgent controller-json`
command through `xWalk-rpi5-tool/py-agent/dev-tool/xHal_Rpi5CarControllerJsonGenerator.py` to produce
`xControllerJson.cpp/.h` under the build directory; no manual generation is needed. The terminal links
`xWalkIwProtobuf` (adding `xWalk-rpi5-iw` with `XWALK_IW_GENERATED_DIRECTORY` set to the Controller `auto-gen`
copy) and, outside the module build, `xWalkControllerBoot` with `XWALK_CONTROLLER_TERMINAL_BOOT=1`. The `rpi5`
preset fails configuration unless the compiler targets ARM64.

Run from **`xWalk-rpi5-hw/xWalkController`**. Module build and checks:

```bash
cmake --preset module
cmake --build --preset module
ctest --preset module
./build-module/xwalk-ctrl --function all --count 8
./build-module/xwalk-ctrl --mode cfm --function all
./build-module/xwalk-ctrl --mode reject --function all
./build-module/xwalk-ctrl json --signal XWALK_CNTRL_MOVE_REQ
./build-module/xwalk-ctrl json --signal XWALK_CNTRL_MOVE_CFM
./build-module/xwalk-ctrl json --signal XWALK_CNTRL_MOVE_REJ
```

HOST build, verification and simulated runtime:

```bash
cmake --preset host
cmake --build --preset host --parallel 4
ctest --preset host
./build-host/xwalk-ctrl --function all --count 8
./build-host/xwalk-ctrl json --signal XWALK_HEALTH_REQ
./build-host/xwalk-ctrl json --signal XWALK_HEALTH_CFM
./build-host/xwalk-ctrl json --signal XWALK_HEALTH_REJ
./build-host/xwalk-ctrl run --signal XWALK_HEALTH_REQ
./build-host/xwalk-ctrl run --signal XWALK_VERSION_REQ
./build-host/xwalk-ctrl run
```

To exercise motion on HOST, create these files, start `run`, and enter the commands below:

```bash
printf '%s\n' '{"target":"XWALK_LIFE_STATE_ACTIVE"}' > active.json
printf '%s\n' '{"request":{"action":"XWALK_MOVE_ACTION_FORWARD","speedPercent":10,"durationMs":100}}' > move.json
./build-host/xwalk-ctrl run
```

```text
XWALK_LIFE_MOVE_REQ active.json
XWALK_CNTRL_MOVE_REQ move.json
quit
```

From **`xWalk-rpi5-hw`**, after the hardware parent preset builds, the terminal is under the aggregate tree:

```bash
../build-host/cmake/xWalkController/xwalk-ctrl --help
../build-host/cmake/xWalkController/xwalk-ctrl --function all --count 8
../build-host/cmake/xWalkController/xwalk-ctrl json --signal XWALK_CNTRL_MOVE_REQ
../build-host/cmake/xWalkController/xwalk-ctrl json --signal XWALK_HEALTH_REQ --file custom.json
```

Replace `../build-host/cmake` with `../build-rpi/cmake` for the native RPI preset, or use
`../build-module/cmake/xWalkController/xwalk-ctrl` for the parent `module` preset. For the standalone Controller
build without presets, use `./build-host/xwalk-ctrl` or `./build-rpi/xwalk-ctrl` from `xWalkController`.

On a configured 64-bit Raspberry Pi, the native RPI5 runtime is built and started with:

```bash
cmake --preset rpi5
cmake --build --preset rpi5 --parallel 4
./build-rpi5/xwalk-ctrl run --signal XWALK_HEALTH_REQ
./build-rpi5/xwalk-ctrl run
```

Running RPI5 `run` accesses physical hardware; see Safety and constraints before using it.

## 6. Configuration

- `xWalkConfig/xWalkControllerHelp.json` — help text copied to `<build-directory>/config`.
- `xWalkConfig/{request,cfm,reject}/...` — samples copied to `<build-directory>/config/controller`; the path is
  compiled in as `XWALK_CONTROLLER_SAMPLE_DIRECTORY`.
- `run --config PATH` overrides the Boot configuration file; selection order is documented in
  [xWalkBoot](../xWalkBoot/xWalkBoot.md#6-configuration).

## 7. Testing

Tests are registered when `XWALK_CONTROLLER_BUILD_HOST_TESTS` is enabled:

| CTest name | Labels | Check |
| --- | --- | --- |
| `xWalkControllerTerminalDefaultHelp` | `host;controller;terminal` | No arguments prints `Usage: xwalk-ctrl` |
| `xWalkControllerTerminal{Help,Requests,Vehicle}` | `host;controller;terminal` | Help and bounded requests |
| `xWalkControllerTerminalCfm`, `...Reject` | `host;controller;terminal` | No-adapter response path |
| `xWalkControllerTerminalInvalidCount` | `host;controller;terminal` | `--count 9` must fail |
| `xWalkControllerJson<Type>` (114 tests) | `host;controller;json` | Every request, CFM and REJ sample |
| `xWalkControllerJson{Unknown,MissingFile,Mismatch,Malformed}` | `host;controller;json` | Must fail |
| `xWalkControllerTerminalHealthJsonOutput` | `host;controller;terminal;json` | HOST JSON adapter output |
| `xWalkControllerFullRuntimeHostTest` | `host;controller;boot;terminal` | HOST `run` (not module) |

The full-runtime test executes simulated Health, Version, lifecycle, motion, rejection, invalid configuration,
timeout and interruption paths. The module suite covers routing, FIFO ownership, deep copies, lifecycle, terminal
modes and all 114 JSON message samples, plus invalid-input checks; it requires four allowed Linux CPUs and verifies
Controller behavior without hardware access or MQTT publication. An earlier recorded module run passed all 128
then-registered tests; the current CMake registers 130 tests in the module configuration.

```bash
ctest --preset module
ctest --preset host -L terminal --output-on-failure
```

The terminal registers no hardware tests; discover hardware tests with `ctest -N -L hardware`.

## 8. Dependencies

- `xWalkController` and, outside the module build, `xWalkControllerBoot`.
- `xWalkIwProtobuf` from [xWalk-rpi5-iw](../../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md).
- Python 3 and the `xWalkPyAgent` sources in `xWalk-rpi5-tool/py-agent/py-src`.
- Plain generated headers in `xWalk-rpi5-hw/xWalkLibrary/auto-gen`, including `xHal_Rpi5CarGpbSig{Req,Cfm,Rej}.h`,
  which the CMake test generator reads to map each sample to its signal.

## 9. Safety and constraints

- Verification and JSON modes perform no hardware action or MQTT publication.
- RPI5 `run` initializes device providers even for Health. Deployment configuration, libraries, models and device
  permissions must be ready before startup. Run it only with explicit approval on a confirmed safe Raspberry Pi and
  Robot HAT setup. Do not use the HOST motion example on connected hardware without commissioning it first.
- Request mode limits `--count` to 8 so the terminal never deliberately overflows a FIFO (overflow aborts).
- `run` cancellation is cooperative; Ctrl+C and timeouts wait for backend calls to return.

## 10. Related notes

- [xWalkController](../xWalkController.md)
- [xWalkBoot](../xWalkBoot/xWalkBoot.md)
- Python Agent
- [xWalk-rpi5-iw](../../../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md)

---

[Previous page](../xWalkBoot/Modules.md) · [Chapter index](../../../index.md) · [Next page](../../xWalkDriver/xWalkDriver.md)
