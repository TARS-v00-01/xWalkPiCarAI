<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkAnnouncement

**5. xWalk node &middot; Module 18**

<!-- xwalk-page-header:end -->

# xWalkAnnouncement

`xWalkAnnouncement` turns one validated traffic observation into a grounded LLM prompt, calls the shared native
language-model coordinator, validates the generated advisory and emits the `TRAFCTRL` announcement traces.

## 1. Overview

The module formats detected person and vehicle counts and estimated crosswalk occupancy into a prompt. SAFE
observations (risk label 0) skip the LLM call entirely. For elevated risk, the provider receives fixed
instructions: a brief English public traffic advisory of at most two sentences and 60 words, using only supplied
observations, describing model risk as possible rather than confirmed, inventing no accidents, injuries,
locations, speeds, emergency responders or signal states, and never stating that it is safe to cross.

A provider failure, including a timeout, logs a warning and returns no advisory; monitoring continues. The module
can prefix advisories with an explicitly simulated Halmstad location for host-video test runs.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkAnnouncement` -
source directory

## 3. Directory layout

```text
xWalkAnnouncement/
    CMakeLists.txt                              Static library and GoogleTest registration
    include/xWalkAnnouncement.h                 Prompt, cleaning, location and announce functions
    src/xWalkAnnouncement.cpp                   Implementation and TRAFCTRL traces
    test/include/xWalkAnnouncementTestSupport.h Fake language-model state and callback factory
    test/src/xWalkAnnouncementTest.cpp          Host GoogleTests
    test/src/xWalkAnnouncementTestSupport.cpp   Fake provider callback implementation
```

## 4. Public interface

Declared in
`xWalkAnnouncement.h`
in namespace `xwalk::traffic`:

| Function | Contract |
| --- | --- |
| `announcementPrompt(observation)` | Validate the observation and format it as an LLM prompt |
| `cleanAnnouncement(text)` | Reject empty, blank or over-600-byte output; replace control characters with spaces |
| `halmstadTestLocation()` | Return `Simulated incident location: <place>, Halmstad. ` using `getrandom` |
| `withHalmstadTestLocation(message)` | Prefix a cleaned advisory with a random simulated location |
| `announce(observation, llm, simulatedHalmstad)` | Generate, clean, optionally prefix and trace one advisory |

The simulated places are Stora torg, Norre Port, Norre Katts park, Storgatan and Lilla torg. The location is a test
label, not an inferred camera or GPS position. Failure to obtain operating-system randomness throws.

| Trace | Meaning |
| --- | --- |
| `TRAFCTRL.001` | Traffic-model observation accepted |
| `TRAFCTRL.002` | No elevated crosswalk risk; announcement skipped |
| `TRAFCTRL.003` | Announcement text |

Warnings for elevated risk and provider failure are unfiltered. Disabling `TRAFCTRL` traces does not disable
announcement generation.

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md) through `xwalk_traffic_library`. It links publicly to
`xWalkProtocol` and `xWalkLanguageModel`.

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkAnnouncement --output-on-failure
```

`xWalkAnnouncementGoogleTest` (labels `host;gtest;xWalkAnnouncement`) uses in-memory synchronous language-model
callbacks from `xwalk::traffic::test`. It covers grounded prompt facts and SAFE skipping, trace independence,
output rejection and control-character sanitizing, the explicit Halmstad prefix, opt-in simulation, and provider
timeout recovery. No network listener or Ollama service is needed.

## 7. Dependencies

- [xWalkProtocol](../xWalkProtocol/xWalkProtocol.md) for `TrafficObservation` validation.
- [xWalkLanguageModel](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkHal/interface/xWalkLanguageModel/xWalkLanguageModel.md) for the
  provider-neutral LLM coordinator.
- `xWalkTrace` (private) for `TRAFCTRL` traces.

## 8. Safety and constraints

- The prompt cannot guarantee factual generated wording. SAFE is never permission to cross.
- Advisories are only produced for elevated risk; empty or oversized responses are rejected rather than
  truncated.

## 9. Related notes

- [xWalkPublisher](../xWalkPublisher/xWalkPublisher.md)
- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkTrafCtrl.md) · [Chapter index](../../../index.md) · [Next page](../xWalkCameraSvc/xWalkCameraSvc.md)
