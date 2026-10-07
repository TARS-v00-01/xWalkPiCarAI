<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../index.md) / [5. xWalk node](../../../index.md) / xWalkProximity

**5. xWalk node &middot; Module 27**

<!-- xwalk-page-header:end -->

# xWalkProximity

`xWalkProximity` is the traffic controller's front proximity stop client. On the Raspberry Pi it polls the
hardware owner's dedicated local safety endpoint independently of camera capture, inference, MQTT and LLM
announcements, requests `AllStop` for a close or invalid front reading, and derives typed blockage and clearance
announcement transitions.

## 1. Overview

When a live Vehicle or All subscriber reports itself active, a fresh front clearance at or below 80 mm causes an
`AllStop` request. Fresh finite negative raw readings are treated as open road by the configured application
policy, including timeout (-1) and incomplete-pulse (-2) results. This does not prove physical clearance and can
mask sensor faults. Zero, non-finite, out-of-range positive, failed and stale readings still request a stop. An
acknowledgement reports that motor outputs accepted stopping; it does not measure physical standstill.

The hardware-owning Controller additionally enforces this rule itself. The traffic process never opens GPIO or the
ultrasonic sensor, and losing traffic IPC cannot disable the owner's direct proximity monitor. Ordinary sensor
requests and safety reads share the ultrasonic measurement lock and a 60 ms minimum trigger interval, including
retries. Safety sampling does not wait behind a busy reader: after 250 ms without a fresh sample it latches a stop
at the next poll. The owner samples every 60 ms, with the existing bounded 20 ms echo waits. IPC handling is
bounded so that local clients cannot indefinitely starve sampling. Actual scheduling and braking latency must be
measured on the Pi; 80 mm is a trigger threshold, not a guaranteed stopping distance.

The module also hosts `xWalkPathAssessment.h`, the shared path-state type used by
[xWalkPathVision](../xWalkPathVision/xWalkPathVision.md).

## 2. Source location

`xWalk-rpi5-node/xWalkTrafCtrl/xWalkProximity` -
source directory

## 3. Directory layout

```text
xWalkProximity/
    CMakeLists.txt                          Library and host tests; also usable as a standalone project
    include/xWalkProximity.h                ProximityAnnouncementState and ProximityMonitor
    include/xWalkPathAssessment.h           PathState, PathAssessment and pathDescription
    src/xWalkProximity.cpp                  Polling, stop requests and announcement transitions
    test/include/xWalkProximityTestSupport.h  Test fixture declarations
    test/src/xWalkProximityTest.cpp         Socket and policy GoogleTests
    test/src/xWalkProximityClientTest.cpp   Helper client process used by the socket tests
```

## 4. Public interface

Declared in
`xWalkProximity.h`
in namespace `xwalk::traffic`:

| Symbol | Contract |
| --- | --- |
| `ProximityAnnouncementState::evaluate` | Consume at most one blocked or cleared transition from fresh evidence |
| `ProximityMonitor(...)` | Start the poll worker and, with callbacks, a publisher thread |
| `ProximityMonitor::poll(...)` | One bounded poll; inactive or unavailable owners return false |

The monitor owns its worker and publisher threads and joins them on destruction; it is not copyable.

### Ownership and transport

The owner binds the Linux abstract Unix `SOCK_SEQPACKET` endpoint `xwalk.proximity.<effective-uid>`. Both ends
validate `SO_PEERCRED`; run the controller and traffic services as the same user and in the same network
namespace. Frames are fixed-size and versioned. `Status` returns clearance, freshness, validity, Vehicle/All
process eligibility and latch and output-stop status. The protocol uses version 3; update Library, Controller and
Node together. Older frames are rejected. `AllStop` bypasses MQTT, functional worker queues and busy-operation
admission. It is distinct from the Node IPC `Stop` command used to terminate child processes.

The shared protocol lives in the common library's
`xHal_Rpi5CarProximityIpc.h`.
Controller owns sampling and cancellation; HAL owns the persistent motor inhibit. The socket closes automatically
on owner exit; no stale socket file is removed. A second owner cannot bind the same endpoint.

Inspect the same-user owner without loading models, or request the latched stop directly:

```bash
./xWalkTrafCtrl --proximity-status
```

```bash
./xWalkTrafCtrl --all-stop
```

## 5. Build

Built as part of [xWalkTrafCtrl](../xWalkTrafCtrl.md), or standalone as `xWalkProximityHost`, in which case host
tests are enabled automatically. The library links `Threads::Threads` and includes the common library headers.

## 6. Configuration

Controller deployment settings in `picar-x.d/vehicle.conf`:

- `proximity_stop_enabled`: defaults to 1 on Pi and 0 on host; host video evaluation never starts this client.
- `proximity_stop_mm`: default 80, configurable from 50 to 1000 mm to allow earlier stopping.
- `proximity_sensor_inset_mm`: default 0, configurable from 0 to 1000 mm. Calibrate this to the sensor's setback
  behind the robot's front; measured clearance is sensor range minus this value.

### Recovery

The first range sample is checked before Controller queues start. Invalid readings, blocked clearance, stale
sampling and explicit `AllStop` latch the inhibit. Stop-output failures are retried and never reported as
successful. The inhibit blocks re-arming even through lifecycle or Driver initialization. Recovery requires one
second of fresh accepted readings: negative raw readings (policy-defined open road), or positive readings above the
stop threshold plus 20 mm (above 10 cm at the default 8 cm setting). Invalid readings, missed acquisition or
readings inside that margin reset the timer. An IPC-originated stop additionally requires repeated fresh `Clear`
reports; traffic sends these only with current sensor clearance. Missing traffic cannot clear an IPC stop. Camera
classification, freshness and availability do not affect stopping or recovery.

Only the owner releases the motor inhibit, after cleanup and successful zero output. A failed cleanup keeps
recovery blocked. The still-active autonomous session restarts its control loop with its last accepted power
setting, preserving its original pending response. User STOP, lifecycle stop and shutdown cancel that session.
Manual held controls renew bounded requests only while the gesture remains held; released or expired gestures do
not restart. Completed one-shot actions and timed moves are not replayed. Clearance recovery itself generates no
physical movement.

A front-proximity pause permits an explicit manual reverse escape while lifecycle is ACTIVE and prior operation
cleanup is complete. Reverse uses its own 200-1000 ms lease and calibrated steering and power; normal motor arming
and forward commands remain inhibited. Repeated front-stop samples preserve a current reverse lease.
Release, STOP or shutdown cancels it; lack of renewal or clock rollback stops it. Heartbeat cannot prolong the
reverse lease. Recovery of paused autonomous work waits until reverse ends. This is a front-obstacle exception,
not permission to bypass an explicit lifecycle stop or hardware fault.

A zero-power continuous movement STOP still acknowledges motor inhibition while latched; it never clears
cancellation or re-arms the motors. Trace controls remain available while latched so diagnostics can be adjusted
without re-enabling movement.

### Safety announcements

The publisher thread emits one typed transition for a newly detected blockage at or below the threshold confirmed
for 0.5 seconds, then one clearance update after two seconds of fresh accepted clearance. Isolated near spikes do
not announce a new incident; motor stopping remains immediate. Repeated near readings, changing stop
acknowledgement, sensor faults and Vehicle/All deactivate-reactivate cycles do not repeat the blockage
announcement. Inactive modes, missing IPC and invalid or stale readings pause evaluation; they never mean that the
blockage was removed and they reset any partial clearance confirmation.

Fresh clearance means a positive reading above the stop threshold plus 20 mm, or a fresh finite negative reading
accepted as open road by the existing policy. A new blockage after announced clearance starts a new episode. The
episode state lives in the traffic process, surviving vehicle process restarts and mode switches; restarting the
traffic process itself begins a new monitoring session.

The live runtime consumes typed blocked and cleared transitions. A blocked transition first produces local speech,
then requires fresh camera semantic evidence before any MQTT traffic advisory. Isolated obstacles have local
speech only and no MQTT clearance report. See [camera incident routing](../xWalkRuntime/xWalkRuntime.md).
Qualified traffic broadcasts reuse the same explicitly simulated Halmstad location for the session.

Without a responding Vehicle or All owner, traffic suspends `AllStop`, `Clear` and announcements. Service, Voice
and Vision modes report inactive. The Controller local sensor stop remains independent and enabled. Sensor faults
and unacknowledged stops still receive the existing stop handling but do not invent extra road-block broadcasts. A
historical acknowledged latch alone is not evidence of a current obstacle.

With MQTT enabled, the publisher sends the existing SoundReq ANNOUNCE broadcast to all nodes (`server_ip=0.0.0.0`
in both envelopes), feeding Android, Python and node speech handling. Announcement state is consumed before
sending: a failed or uncertain send is not automatically retried because delivery may already have occurred. This
is not an exactly-once broker or playback guarantee. Status reads and delivery run separately from the immediate
stop loop; announcement debounce never delays `AllStop`. The publisher reads current status instead of replaying a
queued warning when activity resumes. Offline clients do not receive non-retained broadcasts; broker delivery does
not prove that every client displayed or spoke the warning.

Camera evidence from [xWalkPathVision](../xWalkPathVision/xWalkPathVision.md) is advisory only. It produces local
open-road or caution diagnostics, never `AllStop`, `Clear` or broadcast announcements. Semantic model detections
are separately used by the runtime to qualify incident broadcasts and never change motor-stop or clearance policy.

## 7. Testing

Socket and policy tests run without OpenCV, cameras, MQTT or model assets. Run from
`xWalk-rpi5-node/xWalkTrafCtrl`:

```bash
cmake -S xWalkProximity -B /tmp/xwalk-proximity-test -G Ninja
```

```bash
cmake --build /tmp/xwalk-proximity-test && ctest --test-dir /tmp/xwalk-proximity-test --output-on-failure
```

`xWalkProximityTest` (30-second timeout, no CTest labels) compiles the Controller's `xControllerProximity.cpp` and
uses the `xWalkProximityClientTest` helper process. It covers sample freshness, threshold and inset latching,
startup and stale-sensor stops, separate-process `AllStop`, stop and clear policy for every unsafe state,
negative readings, inactive owners, sustained-clearance recovery, and typed transitions across owner activity
cycles. In the aggregate traffic build it also runs under
`ctest --preset host`. Controller's `xWalkControllerProximityOperationHostTest` also exercises forward and reverse
held movement, a blocked ordinary response, repeated rejected movement and lifecycle re-arm rejection. HAL tests
verify that the inhibit establishes zero outputs and cannot be cleared by `arm()`. No hardware-labelled test is
defined here; braking latency has not been measured by these tests.

## 8. Dependencies

- [xWalkLibrary Common](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkLibrary/common/xWalkLibrary%20Common.md) for the proximity IPC
  protocol.
- [xWalkBoot](../../../../02-xwalk-hardware/xWalk-rpi5-hw/xWalkController/xWalkBoot/xWalkBoot.md) for the owner-side proximity
  source used by the tests.
- POSIX threads; GoogleTest for host tests.

## 9. Safety and constraints

- 80 mm is a trigger threshold, not a guaranteed stopping distance.
- Traffic inference, announcements and LLM generation are never on the stopping path.
- Run the controller and traffic as the same user in the same network namespace; otherwise the IPC is refused.

## 10. Related notes

- [xWalkRuntime](../xWalkRuntime/xWalkRuntime.md)
- [xWalkPathVision](../xWalkPathVision/xWalkPathVision.md)
- [xWalkTrafCtrl](../xWalkTrafCtrl.md)

---

[Previous page](../xWalkProtocol/xWalkProtocol.md) · [Chapter index](../../../index.md) · [Next page](../xWalkPublisher/xWalkPublisher.md)
