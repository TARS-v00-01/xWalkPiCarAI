<!-- xwalk-page-header:start -->

[xWalk documentation](../../index.md) / [7. xWalk trace](../index.md) / xWalk-rpi5-trace

**7. xWalk trace &middot; Module 01**

<!-- xwalk-page-header:end -->

# xWalk-rpi5-trace

`xWalkTrace` is the C++17 trace service shared by HAL, Controller, Driver, Library, MQTT node, traffic
controller, and OS desktop sources. Tagged traces are build-validated, filtered before format arguments are
evaluated, and written synchronously to the terminal and `<build-directory>/log/xWalkTrace.log`.

## 1. Overview

Each trace record carries UTC time, monotonic elapsed time, UID, and source location. Both destinations
receive the same completely formatted record. A Python pre-compiler scans the participating source trees at
build time, rejects duplicate or wrongly owned trace identifiers, and generates a deterministic XML catalogue
that the runtime loads once to resolve per-trace enable state.

The module also owns the unconditional warning, error, and assertion macros, the error selector catalogue,
transparent standard-stream output adapters, plain terminal command text, editable JSON help loading, the
optional copied Agent message formatter, and an optional Qt adapter for the OS desktop.

## 2. Source location

`xWalk-rpi5-trace` (source directory)

## 3. Directory layout

```text
xWalk-rpi5-trace/
├── CMakeLists.txt                              Trace library, metadata generation, optional targets and tests
├── cmake/
│   └── XWalkOsTrace.cmake                      Optional Qt adapter target xWalkOsTrace and its Google Test
├── config/
│   ├── xHal_Rpi5CarTraceBuildConfig.h.in       Build configuration header template
│   ├── xWalkHalHelp.json                       Editable HAL terminal help document
│   ├── xWalkTraceCriticalPriorities.json       Per-UID critical priorities
│   ├── xWalkTraceErrorPriorities.json          Per-UID error priorities
│   ├── xWalkTraceWarningPriorities.json        Per-UID warning priorities
│   └── xWalkTraceInfoPriorities.json           Per-UID info priorities, including MQTT
├── include/
│   ├── xHal_Rpi5CarTrace.h                     Filtered trace recording and public trace macros
│   ├── xHal_Rpi5CarTraceTypes.h                Trace severity and output callback types
│   ├── xHal_Rpi5CarErrorSignals.h              C++ error numbers and trace signal selectors
│   ├── xHal_Rpi5CarTraceScope.h                Scoped warning/error forwarding
│   ├── xHal_Rpi5CarTraceOutput.h               Transparent standard-stream output macros
│   ├── xHal_Rpi5CarTraceCommandText.h          Plain terminal command text and XWALK_TRACE_HELP
│   ├── xHal_Rpi5CarTraceMqttText.h             Mandatory MQTT command text through the central sink
│   ├── xHal_Rpi5CarTraceAgentMessage.h         Copied Agent message formatter and XAGENT_FORMAT
│   └── XWalkOsTrace.h                          Qt adapter for the OS trace catalogue
├── pre-compiler/
│   └── xHal_Rpi5CarTracePreCompiler.py         Trace UID scanner, validator, and XML catalogue generator
├── src/                                        Implementations of the headers above
└── test/
    ├── include/xHal_Rpi5CarTraceTestTypes.h    Host test support types
    ├── src/xHal_Rpi5CarTraceTest.cpp           Trace library host test
    ├── src/xHal_Rpi5CarTraceAgentTest.cpp      Agent formatter host test
    ├── src/xWalkOsTraceGoogleTest.cpp          Qt adapter Google Test
    ├── hardware/src/xHal_Rpi5CarTraceHardwareTest.cpp  Target compile test
    └── xHal_Rpi5CarTracePreCompilerTest.py     Scanner host test
```

## 4. Public interface

### Trace declarations

Each source tree owns a distinct macro and UID family:

| Source tree | Macro family | UID tag |
| ----------- | ------------ | ------- |
| `xWalkHal` | `XWALK_HAL_TRACE_UIDn` | `RPI.<numeric-id>` |
| `xWalkController` | `XWALK_CTRL_TRACE_UIDn` | `CTRL.<numeric-id>` |
| `xWalkDriver` | `XWALK_RPIAGENT_TRACE_UIDn` | `RPIAGENT.<numeric-id>` |
| `xWalkLibrary` | `XWALK_LIB_TRACE_UIDn` | `LIB.<numeric-id>` |
| `xWalk-rpi5-node` clients | `XWALK_MQTT_TRACE_UIDn` | `MQTTUL.<numeric-id>` |
| `xWalk-rpi5-node` servers | `XWALK_MQTT_TRACE_UIDn` | `MQTTDL.<numeric-id>` |
| `xWalk-rpi5-node/xWalkIoT/xWalkAgent` | `XWALK_XAGENT_TRACE_UIDn` | `XAGENT.<numeric-id>` |
| `xWalk-rpi5-node/xWalkTrafCtrl` | `XWALK_TRAFCTRL_TRACE_UIDn` | `TRAFCTRL.<numeric-id>` |
| `xWalk-rpi5-os` | OS adapter (see below) | `OS.<numeric-id>` |

```cpp
XWALK_HAL_TRACE_UID1(RPI.001, "I2C probe: %u", address);
XWALK_CTRL_TRACE_UID0(CTRL.001, "Controller command execution started");
XWALK_RPIAGENT_TRACE_UID0(RPIAGENT.001, "Agent initialized");
XWALK_LIB_TRACE_UID0(LIB.001, "Library operation completed");
```

The numeric value must be unique within each trace tag across the complete repository, including modules,
submodules, and tests. The same numeric value is valid in different tags. `RPI.001` and `RPI.1` conflict
because they represent the same numeric value. The scanner also rejects a macro family used from the wrong
owned source tree. The `UIDn` suffix is the exact number of formatting arguments after the UID and format
string. Variants `UID0` through `UID5` are supported.

Per-UID record priorities remain separately defined in the named `critical`, `error`, `warning`, and `info`
objects in `config/xWalkTraceCriticalPriorities.json`, `config/xWalkTraceErrorPriorities.json`,
`config/xWalkTraceWarningPriorities.json`, and `config/xWalkTraceInfoPriorities.json`. Every file owns exactly
one level object, and every entry retains its matching numeric priority from zero through three so the
pre-compiler can reject an identifier placed in the wrong level file. Priorities do not bypass runtime state.

### Warnings, errors, and assertions

Warnings, errors, and numeric assertions remain intentionally unconditional:

```cpp
XWALK_HAL_WARNING(XWALK_RANGE, "HAL warning: %d", warningCode);
XWALK_HAL_ERROR(XWALK_RUNTIME, "HAL operation failed");
XWALK_HAL_ASSERT(100);
XWALK_CTRL_ERROR(XWALK_INVAL, "Controller input is invalid");
XWALK_RPIAGENT_WARNING(XWALK_SYSTEM, "Agent warning: %d", warningCode);
XWALK_LIB_ERROR(XWALK_RUNTIME, "Library operation returned status %d", errorCode);
```

MQTT uses `XWALK_MQTT_WARNING` and `XWALK_MQTT_ERROR`; both emit the `MQTT` component label. They retain the
selector-based warning/error contract; numbered UIDs identify normal tagged traces.

Each component has one variadic `ERROR` and one variadic `WARNING` macro. Both accept one selector from
`xHal_Rpi5CarErrorSignals.h`, a format
string, and optional printf-style arguments. C++ selectors are `XWALK_INVAL`, `XWALK_RANGE`, `XWALK_LENGTH`,
`XWALK_DOMAIN`, `XWALK_LOGIC`, `XWALK_RUNTIME`, `XWALK_OVERFLOW`, `XWALK_UNDERFLOW`, `XWALK_SYSTEM`,
`XWALK_ALLOC`, `XWALK_CAST`, `XWALK_TYPEID`, `XWALK_FUNCTION`, `XWALK_OPTIONAL`, `XWALK_VARIANT`,
`XWALK_WEAKPTR`, and `XWALK_EXCEPTION`.

The macros evaluate formatting arguments once and write the selected category, selector tag, caller location,
and formatted message. An `ERROR` with a C++ selector throws that exception after logging. An `ERROR` with an
operating-system signal selector reports the observed condition without raising the signal again.
`XWALK_EXCEPTION` records a generic non-throwing error for callers that return a status or continue
explicitly. Warnings never throw or raise a signal.

Operating-system signal selectors are separate: `XWALK_ABORT`, `XWALK_FLOAT`, `XWALK_ILL`, `XWALK_SEGV`,
`XWALK_TERM`, `XWALK_INT`, `XWALK_PIPE`, `XWALK_HANG`, and `XWALK_TRAP`. They resolve through
namespace-backed signal constants. Use them with `ERROR` or `WARNING` only when reporting the matching
operating-system signal. `XWALK_PIPE`, `XWALK_HANG`, and `XWALK_TRAP` are available only when the platform
headers provide `SIGPIPE`, `SIGHUP`, and `SIGTRAP`, respectively.

`XWalkErrorSignalNumber` assigns stable values `0` through `26` to the complete selector catalogue for
transport through `TraceRej`. These values remain independent of the platform's numeric `SIG*` definitions.
Value `27`, `WrongServer`, is a protocol rejection rather than a trace selector: the node reports it through
the `XWALK_WRONG_SERVER` selector name when a request's `server_ip` does not address that node.

The legacy `XWALK_VERBOSE` name remains as a disabled no-op for source compatibility. Production normal
diagnostics must use a registered UID macro.

### Diagnostic policy

Project-owned normal, informational, status, progress, success, and debug diagnostics use the registered UID
macro belonging to their source tree. Warnings use that component's singular `WARNING` macro, errors use its
`ERROR` macro, and numeric assertion signals use `ASSERT` only for genuine invariant failures. Direct
standard-output, standard-error, C printing, platform logging, and locally defined diagnostic macros are
prohibited for diagnostics.

Functional command output remains separate from tracing. Help, version text, machine-readable results,
protocol responses, interactive prompts, and command results retain their existing output contract and must
not receive trace metadata that would change that interface.

### MQTT node traces

`XWalkTrace::setMqttTracesEnabled(true)` selects the node connection/RX (`MQTTUL`) and TX (`MQTTDL`) trace
IDs; pass `false` to disable them. MQTT priorities are maintained in `config/xWalkTraceInfoPriorities.json`.
The catalogue includes node call sites when the node component is present in the workspace. Warning and
error calls continue to use `XWALK_MQTT_WARNING` and `XWALK_MQTT_ERROR` with the shared severity
configuration.

### Node functional Agent traces

Sources below `xWalk-rpi5-node/xWalkIoT/xWalkAgent` use `XWALK_XAGENT_TRACE_UIDn` and numeric `XAGENT.xxx`
identifiers. `XWALK_XAGENT_WARNING` and `XWALK_XAGENT_ERROR` use the shared diagnostic policy. Enable the
module with `XAGENT.enable` through the existing trace control API. Request preparation logs bounded escaped
copied values; the node Agent has no separate filtering switch. The scanner permits these call sites to be
absent during a separate node-component uplift, while retaining strict checks for unknown IDs.

Queue delivery priorities are required when the queue headers are present and `xWalkNodeTransmitter` links
`xWalkTrace`. Legacy queues without this dependency do not enable the delivery trace group. Coverage remains
strict for enabled groups and unrelated trace identifiers.

The optional `xWalkTraceAgent` library owns copied Agent message field traversal, formatting, escaping, and
bounded text preparation in `src/xHal_Rpi5CarTraceAgentMessage.cpp`. Video stream request JSON includes
`background` and `stop` alongside client correlation fields. Handlers emit this text through
`XWALK_XAGENT_TRACE_UID1(uid, "%s", XAGENT_FORMAT(request))`. The library is built only when the generated
plain request headers exist in both the node `xWalkMqttCommon/auto-gen` and the Library `auto-gen`
directories; it compiles against the Library copy. The base trace library remains independent of node types;
the formatter receives borrowed generated request structures and never invokes node decoding or dispatch
functions.

### Copied Agent message JSON

`XAGENT_FORMAT` formats all 38 copied request types as indented, multiline JSON inside the existing
`XWALK_XAGENT_TRACE_UID1` record. Trace timestamps, identifiers, terminal output, and log-file routing stay
controlled by this module. The complete log record retains its trace prefix. JSON starts on the next line
after `Copied <type>:` and uses four-space indentation, matching a readable JSON file.

Optional absent fields appear as `null`. Numbers and Booleans retain their JSON types; strings preserve UTF-8
and escape quotes, backslashes, and control bytes. Binary fields use hexadecimal strings. Non-finite
floating-point values become `null`. The bounded per-thread formatter returns
`{"error":"trace message truncated"}` if the complete record exceeds its buffer. It does not emit partial JSON
or modify MQTT payloads.

Sound request formatting includes announcement ID, title, and body when normal request tracing is enabled.
The existing bounded JSON formatter still limits output; oversized messages report truncation.

### Traffic-controller traces

`xWalk-rpi5-node/xWalkTrafCtrl` owns `XWALK_TRAFCTRL_TRACE_UID0` through `XWALK_TRAFCTRL_TRACE_UID5` and
`TRAFCTRL.<digits>` identifiers. Its `XWALK_TRAFCTRL_WARNING` and `XWALK_TRAFCTRL_ERROR` macros retain the
shared selector/error policy and bypass normal trace filtering. Use `TRAFCTRL.enable` or an individual
selector such as `TRAFCTRL.003.enable` for announcement output. The scanner enforces this ownership
separately from MQTT and functional Agent traces. Priorities for the optional controller are excluded when its
source is absent, so standalone trace checkouts continue to build.

### OS desktop traces

The optional Qt adapter in `XWalkOsTrace.cmake`
defines the `xWalkOsTrace` static library (linking `Qt5::Core` and `xWalkTrace`) and integrates the desktop
with this repository's scanner, selectors, and file sink. It does not add Qt dependencies to ordinary trace
consumers. See [OS trace IDs and behavior](docs/OS_TRACES.md).

### Plain terminal help

Command-line help uses `xwalk::trace::writeCommandText` from
`xHal_Rpi5CarTraceCommandText.h`. This
trace-owned terminal sink writes literal text to stdout (or stderr for usage errors), without timestamps,
severity labels, UID filtering, or log/configuration initialization. It preserves newlines and percent signs.
Normal diagnostic trace APIs remain unchanged. The OS adapter exposes `XWalkOsTrace::commandText`, with the
same contract in the standalone stub. Help must return before connecting to services, opening hardware, or
starting the GUI.

### Transparent output macros and editable help

Use `XWALK_TRACE_PUTS`, `XWALK_TRACE_FPUTS`, `XWALK_TRACE_PUTC`, `XWALK_TRACE_FPUTC`, `XWALK_TRACE_PUTCHAR`,
`XWALK_TRACE_PRINTF`, `XWALK_TRACE_FPRINTF`, `XWALK_TRACE_VPRINTF`, `XWALK_TRACE_VFPRINTF`,
`XWALK_TRACE_FWRITE`, and `XWALK_TRACE_FFLUSH` from
`xHal_Rpi5CarTraceOutput.h` for existing
standard-stream output. They preserve the corresponding C function's stream, exact bytes, newline behavior,
return value, and argument evaluation. They do not add log prefixes, filter data, redirect stdout, or
initialize trace configuration. Format checking remains enabled. Memory-only formatting uses the
library-owned `XWALK_SNPRINTF` / `XWALK_VSNPRINTF` macros from `xHal_Rpi5CarFormatFunctions.h` in
`xWalkLibrary/common`. These preserve bounded formatting behavior without emitting traces. Qt widget text
setters remain unchanged. The OS standalone profile carries a matching dependency-free adapter; host and Pi
builds use this trace module.

`XWALK_TRACE_HELP("name.json")` reads a nonempty JSON `help` array of strings on each call. Documents are
limited to 64 KiB and validated before any help text is printed. A failed load returns false and reports to
stderr. Set `XWALK_HELP_DIR` to select an explicit directory. Otherwise the loader checks the executable's
`config`, parent `config`, installed `../share/xwalk/help`, then its build config directory. Edit the runtime
JSON to update help without rebuilding. HAL help substitutes `{program}` with the binary name. Node,
Controller, Traffic, Camera, and HAL each use their own JSON template. OS uses the Qt loader described in its
CLI guide and `XWALK_OS_HELP_FILE`, retaining a build independent of other repositories.

## 5. Build

The build requires CMake 3.16 or later, Python 3, TinyXML2, and the `libjson-c-dev` development package, all
resolved locally without network access. Compiler warnings `-Wall -Wextra -Wpedantic -Wconversion
-Wsign-conversion` apply to GNU and Clang builds.

```bash
cmake -S xWalk-rpi5-trace -B xWalk-rpi5-trace/build-host -DXWALK_TRACE_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-trace/build-host --parallel
```

| CMake target | Responsibility |
| ------------ | -------------- |
| `xWalkTraceMetadata` | Runs the pre-compiler and generates `generated/xwalk-traces.xml` |
| `xWalkTrace` | Static trace library; depends on `xWalkTraceMetadata` |
| `xWalkTraceAgent` | Optional copied Agent message formatter library |
| `xWalkOsTrace` | Optional Qt adapter, defined by `cmake/XWalkOsTrace.cmake` |

The build copies `config/xWalkHalHelp.json` to `<build-directory>/config` and installs it to
`share/xwalk/help`.

### Build validation and XML catalogue

`xHal_Rpi5CarTracePreCompiler.py`
tokenizes the registered `XWALK_<component>_TRACE_UIDn` macro families recursively across the scanned source
roots, including generated project sources and participating nested repositories. Build trees, CI overlay
checkouts, and third-party/external trees are excluded. This macro inventory is the sole source for
validation, ownership enforcement, XML generation, runtime registration, and trace discovery.

The normal CMake build depends on the scanner. It reports every duplicate ID and every declaration path and
line in one run, then returns non-zero before the dependent compilation or link completes. For example:

```text
Trace validation error: non-unique trace IDs are used.

Duplicate trace ID: RPI.001
  Declared at: src/rpi/camera.cpp:42 (XWALK_HAL_TRACE_UID1)
  Declared at: src/rpi/motor.cpp:87 (XWALK_HAL_TRACE_UID2)

Compilation stopped because trace IDs must be unique.
```

A successful build atomically creates:

```text
<build-directory>/generated/xwalk-traces.xml
```

The UTF-8 catalogue is deterministic: modules are sorted by canonical name, traces are sorted numerically and
then by preserved ID text, paths are project-relative, and no timestamps are stored. CMake depends on the
scanner, the priority files, and every recursively discovered project C/C++ source, so additions, removals,
IDs, text, module changes, and source-line changes regenerate it. Regeneration preserves valid state flags
for retained IDs, assigns `disable` to new IDs, and removes absent IDs. Identical content is not rewritten.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xwalkTraceCatalogue version="1.0" defaultState="disable">
  <module name="RPI" defaultState="disable">
    <trace
      id="001"
      fullId="RPI.001"
      defaultState="disable"
      name="I2C probe"
      sourceFile="xWalk-rpi5-hw/xWalkHal/interface/xWalkI2c/core/src/xHal_Rpi5CarI2c.cpp"
      sourceLine="73"
      priority="2"
      formatArgumentCount="1"
      owningComponent="HAL" />
  </module>
</xwalkTraceCatalogue>
```

XML attributes are escaped by the generator and parsed with real XML parsers in the automated tests. The
runtime loads the catalogue once and writes it only for a requested configuration update; it does not parse
XML or JSON for every trace call.

## 6. Configuration

### CMake options and cache variables

| Option or variable | Default | Effect |
| ------------------ | ------- | ------ |
| `XWALK_TRACE_BUILD_HOST_TESTS` | `OFF` | Builds the trace and scanner host tests |
| `XWALK_TRACE_BUILD_AGENT_HOST_TESTS` | `OFF` | Builds the Agent formatter host test independently |
| `XWALK_TRACE_BUILD_HARDWARE_TESTS` | `OFF` | Builds the target compile test |
| `XWALK_TRACE_PROJECT_ROOT` | Workspace root | Root used to resolve trace source paths |
| `XWALK_TRACE_LIBRARY_ROOT` | `xWalk-rpi5-hw/xWalkLibrary` | Path to the `xWalkLibrary` module |

CMake resolves `xWalkLibrary` from `xWalk-rpi5-hw/xWalkLibrary` in the root layout and from the sibling
`xWalkLibrary` module in the legacy nested layout. Isolated checkouts can set `XWALK_TRACE_LIBRARY_ROOT`
explicitly. Metadata generation scans the hardware product (`xWalk-rpi5-hw`) and, when it is not inside that
product, the Trace module source root. It adds `xWalk-rpi5-node` when `xWalkIoT/xWalkMqttInit` exists and
`xWalk-rpi5-os` when `xWalkMain/main.cpp` exists; it does not scan unrelated workspace modules or CI overlay
checkouts.

### Runtime trace selection

New normal traces start disabled. At startup, the shared thread-safe registry loads the saved XML states. It
resolves an effective state in this order: individual tag, module, then global. Settings are applied from
left to right; a later global setting clears earlier module and tag overrides, and a later module setting
clears earlier tag overrides in that module. This makes the last applicable setting win.

```bash
xwalk-picarx-control --trace RPI.001.enable
xwalk-picarx-control --trace RPI.001.disable
xwalk-picarx-control --trace CTRL.001.enable
xwalk-picarx-control --trace CTRL.001.disable
xwalk-picarx-control --trace RPI.enable
xwalk-picarx-control --trace RPI.disable
xwalk-picarx-control --trace CTRL.enable
xwalk-picarx-control --trace CTRL.disable
xwalk-picarx-control --trace RPIAGENT.enable
xwalk-picarx-control --trace LIB.disable
xwalk-picarx-control --trace all.enable
xwalk-picarx-control --trace all.disable
xwalk-picarx-control --trace xWalk-rpi5-hw/xWalkController/xWalkConfig/xwalk-traces.json
```

JSON uses one top-level `trace` object. It applies `all`, then module states, then tag states. State values
must be the strings `enable` or `disable`; Boolean values are rejected. Unknown modules and complete IDs,
malformed or missing files, and invalid selectors produce startup status 2 before hardware composition. A
successful selector or JSON update atomically replaces the XML and updates memory. The next run loads that
XML automatically, so the selector does not need to be repeated. Example files, including
`xwalk-traces.json`, `trace-all-enable.json`, and `trace-all-disable.json`, are in
`xWalk-rpi5-hw/xWalkController/xWalkConfig`.

## 7. Testing

Host tests run first and require no hardware:

```bash
ctest --test-dir xWalk-rpi5-trace/build-host --output-on-failure
```

| CTest test | Labels | Enabled by |
| ---------- | ------ | ---------- |
| `xWalkTraceHostTest` | `host` | `XWALK_TRACE_BUILD_HOST_TESTS` |
| `xWalkTraceScannerHostTest` | `host;tooling` | `XWALK_TRACE_BUILD_HOST_TESTS` |
| `xWalkTraceAgentHostTest` | `host;trace` | Host or Agent host tests, when `xWalkTraceAgent` exists |
| `xWalkTraceTargetCompileTest` | `hardware` | `XWALK_TRACE_BUILD_HARDWARE_TESTS` |
| `xWalkOsTrace.*` | `xWalkOsTrace` | `BUILD_TESTING` in a consumer that includes `XWalkOsTrace.cmake` |

`xWalkTraceTest` creates and reads its mutable fixtures under
`<trace-build-directory>/test-output/xWalkTraceTest/`, including `trace-global-initialization/`. This location
also applies when the executable is launched directly from another working directory; source directories are
not used for generated test configurations or logs.

When the Node generated request structures are available, the host suite also runs
`xWalkTraceAgentHostTest`. It checks all 38 request formatters, optional fields, nested addresses, JSON
escaping, binary data, truncation, and thread-local storage. The integrated host build enables this test
through `XWALK_TRACE_BUILD_AGENT_HOST_TESTS`, independently of the legacy Trace tests collected by
`xGoogleTest`.

Hardware tests are opt-in. During ordinary development, only build and list them:

```bash
cmake -S xWalk-rpi5-trace -B xWalk-rpi5-trace/build-rpi -DXWALK_TRACE_BUILD_HARDWARE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build xWalk-rpi5-trace/build-rpi --parallel
```

```bash
ctest --test-dir xWalk-rpi5-trace/build-rpi -N -L hardware
```

Do not run hardware tests without explicit approval and a confirmed safe Raspberry Pi and Robot HAT setup.

## 8. Dependencies

- `xWalkLibraryCommon` from [`xWalkLibrary/common`](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md),
  added when the target does not already exist, and `XWalkDependencies.cmake` from `xWalkLibrary`.
- TinyXML2 (`tinyxml2::tinyxml2`, public) and json-c through pkg-config (`PkgConfig::JSON_C`, private).
- Python 3 for the pre-compiler and scanner test.
- Optional: generated plain IW request headers for `xWalkTraceAgent`; Threads for its test; `Qt5::Core` and
  GoogleTest for `xWalkOsTrace`.

## 9. Safety and constraints

- Trace UIDs must be unique per tag across the repository; duplicates fail the build before compilation
  completes.
- `ERROR` with a C++ selector throws after logging; use `XWALK_EXCEPTION` for a non-throwing error.
- Normal traces never replace functional command output, protocol responses, or help text.
- The Agent formatter is bounded per thread and never emits partial JSON or modifies MQTT payloads.
- Hardware tests are opt-in and are only listed during ordinary development.

## 10. Related notes

- [OS trace IDs and behavior](docs/OS_TRACES.md)
- [xWalk-rpi5-iw](../../03-xwalk-interface/xWalk-rpi5-iw/xWalk-rpi5-iw.md)
- [xWalkHal](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkHal/xWalkHal.md)
- [xWalkController](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkController.md)
- [xWalkDriver](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkDriver/xWalkDriver.md)
- [xWalkLibrary](../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/xWalkLibrary.md)
- [xWalkIoT](../../05-xwalk-node/xWalk-rpi5-node/xWalkIoT/xWalkIoT.md)
- [xWalkTrafCtrl](../../05-xwalk-node/xWalk-rpi5-node/xWalkTrafCtrl/xWalkTrafCtrl.md)
- [xWalk-rpi5-os](../../04-xwalk-software/xWalk-rpi5-os/xWalk-rpi5-os.md)

---

[Previous page](../index.md) · [Chapter index](../index.md) · [Next page](docs/OS_TRACES.md)
