<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkTest

**5. xWalk node &middot; Module 30**

<!-- xwalk-page-header:end -->

# xWalkTest

`xWalkTest` is the traffic controller's shared host-test infrastructure: a small fixture library and the
`xwalk_traffic_add_gtest` CMake helper that registers each submodule's GoogleTest executable consistently.

## 1. Overview

The parent [xWalkTrafCtrl](../xWalkTrafCtrl.md) build adds this directory only when
`XWALK_TRAFCTRL_BUILD_HOST_TESTS` is ON, which in turn requires `XWALK_TRAFCTRL_MODE=host` and a GoogleTest CMake
package. The `host` preset enables it.

`xwalk_traffic_add_gtest(<module>)` creates `<module>GoogleTest` from `test/src/<module>Test.cpp`, links it to the
module, `GTest::gtest_main`, `xWalkTrafficTestSupport` and `xWalkTrace`, and registers a CTest test with:

- labels `host;gtest;<module>`;
- a 40-second timeout;
- the `xWalkTrafficTrace` resource lock, so suites sharing the global trace configuration do not run
  concurrently.

Modules with additional test support (`xWalkAnnouncement`, `xWalkPublisher`) add their
`test/src/<Component>TestSupport.cpp` and `test/include` explicitly after calling the helper.

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkTest` -
source directory

## 3. Directory layout

```text
xWalkTest/
    CMakeLists.txt              xWalkTrafficTestSupport library and xwalk_traffic_add_gtest function
    include/xWalkTestSupport.h  Directory fixture declaration
    src/xWalkTestSupport.cpp    Directory fixture implementation
```

## 4. Public interface

Declared in
`xWalkTestSupport.h`
in namespace `xwalk::traffic::test`:

| Member | Contract |
| --- | --- |
| `Directory()` | Create a unique `xwalk-traffic-XXXXXX` directory under the system temporary path |
| `~Directory()` | Remove the directory and its fixtures without throwing |
| `write(name, content)` | Write a binary fixture and return its absolute path |
| `path(name)` | Resolve a fixture path inside the directory |

Fixture creation or write failure aborts the test process.

## 5. Testing

The helper registers seven suites: `xWalkConfiguration`, `xWalkProtocol`, `xWalkCapture`, `xWalkModel`,
`xWalkAnnouncement`, `xWalkPublisher` and `xWalkRuntime`. Select one with its label:

```bash
ctest --test-dir build-host -L xWalkModel --output-on-failure
```

`xWalkPathVisionTest` and `xWalkProximityTest` are registered by their own modules without this helper and carry
no labels. No suite uses hardware.

## 6. Dependencies

- `xWalkLibraryCommon` for project types; GoogleTest; `xWalkTrace`.

## 7. Related notes

- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkRuntime/xWalkRuntime.md) · [Chapter index](../../../index.md) · [Next page](../cmake/host-dependencies/xWalkTrafCtrl%20Host%20Dependencies.md)
