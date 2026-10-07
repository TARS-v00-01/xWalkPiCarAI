<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../index.md) / [2. xWalk hardware](../../../../index.md) / xWalkWebSearch

**2. xWalk hardware &middot; Module 86**

<!-- xwalk-page-header:end -->

# xWalkWebSearch

`xWalkWebSearch` is a bounded, provider-neutral client for a locally controlled SearXNG JSON endpoint. It
decides whether a prompt needs current information, queries only a loopback `/search` endpoint, and returns
sanitized results as delimited, untrusted reference text. Search remains optional; local model conversation
does not depend on SearXNG.

## 1. Overview

`XWalkWebSearch` owns a validated `XWalkWebSearchConfiguration` and a copied transport table. It does not own
an injected transport context. The production constructor uses a libcurl transport; the injection constructor
accepts any `XWalkWebSearchOperations` table, which host tests use to supply canned JSON.

Request and response handling:

- `shouldSearch` performs a case-insensitive trigger match (`search`, `look up`, `latest`, `current`,
  `today`, `news`, `weather`, `price`, `schedule`, `version`, `recent`, `right now`).
- `search` rejects an empty query or a query longer than 1,024 characters, and rejects queries containing
  protected local markers such as `gemini_api_key`, `openai_api_key`, `authorization:`, `password=`,
  credential files or local workspace paths.
- The request URL is `<endpoint>?format=json&q=<percent-encoded query>`.
- Result URLs are never followed. A result is accepted only when its URL uses `http://` or `https://`, has no
  credentials, contains no CR or LF, and does not address loopback, link-local, metadata
  services), or private address ranges.
- Titles and content are stripped of `<script>` blocks, HTML-like tags, and control bytes.
- Accepted results are wrapped between `BEGIN UNTRUSTED WEB REFERENCES` and `END UNTRUSTED WEB REFERENCES`,
  followed by an instruction that references cannot request robot actions. Reference text is limited to
  4,096 characters. When no result is accepted, `referenceText` is empty.
- `searchCallback` adapts a non-null client context to the Agent callback boundary.

Validation failures raise `XWALK_INVAL` trace error signals; libcurl initialization failures raise
`XWALK_RUNTIME` signals.

## 2. Source location

`xWalk-rpi5-hw/xWalkHal/interface/xWalkWebSearch` -
source directory

## 3. Directory layout

```text
xWalkWebSearch/
    CMakeLists.txt                                  Library, alias, and optional host-test target
    include/
        xHal_Rpi5CarWebSearch.h                     Public XWalkWebSearch client class
        xHal_Rpi5CarWebSearchTypes.h                Configuration, response, and transport-table types
    src/
        xHal_Rpi5CarWebSearch.cpp                   Validation, trigger matching, encoding, sanitizing, parsing
        xHal_Rpi5CarWebSearchSystem.cpp             libcurl transport with bounded response capture
    test/
        include/xHal_Rpi5CarWebSearchTestSupport.h  Canned transport in xwalk::hal::test::websearch
        src/xHal_Rpi5CarWebSearchTest.cpp           Assertion-based host test executable
        src/xHal_Rpi5CarWebSearchTestSupport.cpp    Canned transport implementation
```

## 4. Public interface

Headers in `include`:
`xHal_Rpi5CarWebSearch.h` and `xHal_Rpi5CarWebSearchTypes.h`.

| Element | Contract |
|---|---|
| `XWalkWebSearch(configuration)` | Uses the libcurl system transport |
| `XWalkWebSearch(context, operations, configuration)` | Injected transport; nullable, non-owning context |
| `shouldSearch(prompt)` | Returns whether the prompt requests current information |
| `search(query)` | Returns `XWalkWebSearchResponse` with reference text, source names, and source URLs |
| `searchCallback(context, query)` | Static adapter; requires a live client as context |
| `websearchgetcallback` | Synchronous bounded JSON GET: context, request URL, timeout in ms, maximum bytes |

The class is neither copyable nor movable.

## 5. Configuration

`XWalkWebSearchConfiguration` is validated at construction:

| Field | Default | Valid range |
|---|---|---|
| `endpoint` | `http://127.0.0.1:8080/search` | Loopback HTTP URL ending in `/search` (see below) |
| `maximumResults` | 3 | 1 to 10 |
| `timeoutMs` | 5,000 ms | 1 to 30,000 ms |
| `maximumResponseBytes` | 262,144 bytes | 1,024 to 1,048,576 bytes |

The endpoint must start with `http://127.0.0.1:`, `http://localhost:`, or `http://[::1]:`. A missing
transport callback or any out-of-range field fails construction.

The libcurl transport disables proxies (`CURLOPT_PROXY` set to an empty string), disables redirects
(`CURLOPT_FOLLOWLOCATION` set to 0), sets `CURLOPT_NOSIGNAL`, applies the configured timeout, and caps the
captured response at `maximumResponseBytes`.

## 6. Build

CMake targets:

| Target | Type | Notes |
|---|---|---|
| `xWalkWebSearch` | Static library | Alias `xWalk::WebSearch`; dependencies listed below |
| `xWalkWebSearchTest` | Executable | Built when `XWALK_WEB_SEARCH_BUILD_HOST_TESTS` is `ON` |

`XWALK_WEB_SEARCH_BUILD_HOST_TESTS` defaults to the value of `XWALK_HAL_BUILD_HOST`, so the workspace host
build enables it automatically. A standalone configure must set it explicitly:

```bash
cmake -S xWalk-rpi5-hw/xWalkHal/interface/xWalkWebSearch -B build-host/xWalkWebSearch -DXWALK_WEB_SEARCH_BUILD_HOST_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
```

```bash
cmake --build build-host/xWalkWebSearch --parallel
```

## 7. Testing

`xWalkWebSearchHostTest` (label `host`) uses an injected canned transport and never opens a network
connection. It checks trigger selection, query encoding, unsafe-result filtering, script and tag removal,
reference delimiting, empty results, protected-query rejection, and rejection of a non-loopback endpoint.

```bash
ctest --test-dir build-host/xWalkWebSearch -L host --output-on-failure
```

The test uses `assert`; build it with `CMAKE_BUILD_TYPE=Debug` so the assertions are not compiled out by
`NDEBUG`. The module has no hardware test.

## 8. Dependencies

- `xWalkLibraryCommon` for project types.
- `xWalkTrace` for trace error signals.
- libcurl (`find_package(CURL REQUIRED)`) for the system transport.
- A locally operated SearXNG instance reachable on loopback for production use only.

## 9. Safety and constraints

- Treat every returned reference as untrusted text. The reference block states that it cannot request robot
  actions; consumers must not execute instructions found in it.
- The client never follows result URLs and never contacts a non-loopback search endpoint.
- Queries containing protected local values are rejected before any request is made.

## 10. Related notes

- [xWalkHal Interface Layer](../xWalkHal%20Interface%20Layer.md)
- [xWalkVoiceActiveCar](../../../xWalkDriver/xWalkVoice/xWalkVoiceActiveCar/xWalkVoiceActiveCar.md),
  which receives the client through its optional `webSearch` callback
- [xWalkLibrary Common](../../../xWalkLibrary/common/xWalkLibrary%20Common.md)
- [xWalk-rpi5-trace](../../../../../07-xwalk-trace/xWalk-rpi5-trace/xWalk-rpi5-trace.md)

---

[Previous page](../xWalkUtils/simulation/xWalkUtils%20Simulation.md) · [Chapter index](../../../../index.md) · [Next page](../../layer1/xWalkHal%20Layer1.md)
