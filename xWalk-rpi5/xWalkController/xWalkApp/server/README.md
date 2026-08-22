# xWalk Controller server

The `server` component is reserved for the future Controller transport adapter.
It currently provides directory and CMake ownership only; no server runtime,
network listener, Protobuf adapter, or gRPC dependency is enabled.

## Intended boundary

A future server receives external requests, validates and converts their data,
and submits native signals through the existing `xWalkScheduler` CBB interface.
It must not invoke Controller, Agent, or HAL handlers directly or introduce a
second command-dispatch path.

## Layout

| Path | Responsibility |
| --- | --- |
| `config/` | Reserved for server configuration schemas and safe defaults |
| `include/` | Reserved for public server transport contracts |
| `src/` | Reserved for transport-adapter implementation |
| `test/` | Reserved for bounded host tests and test support |
| `CMakeLists.txt` | Owns future server build and test targets |

The tracked placeholders contain no production implementation. Add source and
test files only after the server protocol, lifecycle, scheduler routing, and
host verification plan are approved.
