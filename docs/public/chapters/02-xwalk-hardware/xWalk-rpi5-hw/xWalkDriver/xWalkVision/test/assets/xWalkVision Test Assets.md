<!-- xwalk-page-header:start -->

[xWalk documentation](../../../../../../index.md) / [2. xWalk hardware](../../../../../index.md) / xWalkVision Test
Assets

**2. xWalk hardware &middot; Module 35**

<!-- xwalk-page-header:end -->

# xWalkVision Test Assets

This directory contains small, reviewed media fixtures for deterministic x86 tests. The clips are test inputs,
not a model-accuracy dataset. Detection and classification expectations use explicit deterministic doubles
unless a test says otherwise.

## 1. Overview

`recorded_scenarios` contains five-frame, 320-by-240 MJPEG AVI clips. Most are transformed excerpts from
OpenCV `vtest.avi`; the bicycle clip is derived from Visitor7's Wikimedia Commons photograph. The manifest
records immutable source revisions, source checksums, licenses, transformations and checksums for every
committed result. Expected behavior is stored separately in `manifests/annotations.json`.

`camera_interruption` represents a transport failure injected after valid frames; `end_of_video` represents
clean decoder exhaustion. The clips labeled poor-lighting, motion-blur and partial-occlusion are deterministic
test transformations, not natural-condition accuracy samples.

## 2. Source location

`xWalk-rpi5-hw/xWalkDriver/xWalkVision/test/assets`
(source directory)

## 3. Directory layout

```text
assets/
    fetch-assets.sh                 Reproducibly fetches sources and derives every fixture
    verify-assets.sh                Offline checksum and manifest verification wrapper
    validate-assets.py              Manifest, annotation, and committed-checksum validator
    manifests/
        manifest.json               Sources, pinned revisions, licenses, transformations, and checksums
        annotations.json            Expected behavior per scenario
    recorded_scenarios/             Twelve <scenario>/scenario.avi clips
    malformed_images/               truncated.jpg and text-as-image.jpg negative inputs
    model_metadata/                 valid-model.json and malformed-model.json metadata fixtures
```

The twelve required scenarios are `pedestrian_entering_crosswalk`, `pedestrian_standing_safely`,
`vehicle_approaching_pedestrian`, `bicycle_crossing`, `multiple_road_users`, `partial_occlusion`,
`poor_lighting`, `motion_blur`, `empty_road`, `false_positive_challenge`, `camera_interruption`, and
`end_of_video`.

## 4. Configuration

`fetch-assets.sh` caches downloaded sources in `XWALK_ASSET_CACHE`, which defaults to
`${TMPDIR:-/tmp}/xwalk-vision-asset-cache`.

## 5. Testing

Verify committed files without network access with:

```bash
xWalk-rpi5-hw/xWalkDriver/xWalkVision/test/assets/verify-assets.sh
```

Fetch and regenerate the fixtures with:

```bash
xWalk-rpi5-hw/xWalkDriver/xWalkVision/test/assets/fetch-assets.sh
```

When `XWALK_ROAD_USER_SAFETY_BUILD_HOST_TESTS` is on, the
[xWalkRoadUserSafety](../../xWalkRoadUserSafety/xWalkRoadUserSafety.md) build registers
`xWalkVisionAssetManifestTest` (labels `host`, `vision`, `recorded-media`, `fixture-validation`), which runs
`validate-assets.py` on this directory, and passes the directory to `xWalkRoadUserSafetyTest` as
`XWALK_RECORDED_ASSET_DIRECTORY`.

```bash
ctest --test-dir build-host/cmake --output-on-failure -R xWalkVisionAssetManifestTest
```

## 6. Dependencies

- Python 3 for validation.
- `curl`, `sha256sum`, and FFmpeg for regeneration only.

## 7. Safety and constraints

All downloaded files are treated as untrusted data. The script verifies source SHA-256 values before invoking
FFmpeg and never executes source content. Regeneration requires network access; verification does not.

OpenCV `vtest.avi` is distributed under Apache-2.0. `Bicyclist_Crossing_the_Street.jpg` is Copyright Visitor7
and licensed CC BY-SA 3.0; the derived bicycle clip retains that license and attribution.

## 8. Related notes

- [xWalkVision](../../xWalkVision.md)
- [xWalkRoadUserSafety](../../xWalkRoadUserSafety/xWalkRoadUserSafety.md)

---

[Previous page](../../xWalkVideoStreaming/xWalkVideoStreaming.md) · [Chapter index](../../../../../index.md) · [Next page](../../../xWalkVoice/xWalkVoice.md)
