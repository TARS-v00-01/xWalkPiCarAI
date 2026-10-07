<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [2. xWalk hardware](../../index.md) / xWalkAudioResources

**2. xWalk hardware &middot; Module 02**

<!-- xwalk-page-header:end -->

# xWalkAudioResources

`xWalkAudioResources` owns the sound-effect and background-music assets distributed with the SunFounder PiCar-X
examples. It is a data-only component with no build target; its provenance, rights, and integrity records are
maintained in this note.

## 1. Overview

Consumers use the explicit `sounds/` and `music/` child directories so an asset's role remains visible while
provenance, installation, and maintenance stay under one resource boundary. The component is an independent
repository pinned by `xWalk-rpi5-hw`; hardware integration CI validates the packaged assets.

## 2. Source location

`xWalk-rpi5-hw/xWalkAudioResources` (source directory)

## 3. Directory layout

```text
xWalkAudioResources/
    sounds/
        car-double-horn.wav             Vehicle horn effect
        car-start-engine.wav            Vehicle engine-start effect
    music/
        slow-trail-Ahjay_Stelino.mp3    Background music
    .project                            Eclipse resource project description
```

| Path | Purpose |
| --- | --- |
| `sounds/car-double-horn.wav` | Vehicle horn effect |
| `sounds/car-start-engine.wav` | Vehicle engine-start effect |
| `music/slow-trail-Ahjay_Stelino.mp3` | Background music |

## 4. Provenance and rights

The files were copied without modification from the SunFounder `picar-x` repository at commit
`d912972d3a209685a3e575dcf0dff4c49bae300e`. The upstream project declares GNU GPL version 2 or any later version.
This repository distributes the imported files under the GPL version 3 terms in
`xWalk-rpi5-hw/LICENSE`.

Copyright and any asset-specific rights remain with their respective owners. This provenance record does not
replace an asset-specific licence or attribution supplied by an upstream rights holder. The MP3 filename contains
the name `Ahjay_Stelino`; no separate asset-specific licence was found in the source directory. Confirm the
applicable rights before commercial redistribution.

## 5. Integrity

| File | SHA-256 |
| --- | --- |
| `sounds/car-double-horn.wav` | `15c3836597e2b820a9543a1fa671d4b2691bca46ef98f7d4ca767936b5109ed0` |
| `sounds/car-start-engine.wav` | `1b95adaa9f773d67ffb6cec8343cfa4a8ccba4e5ba38dd79a1781b66ac84aa9b` |
| `music/slow-trail-Ahjay_Stelino.mp3` | `f0d5795d7f2e0baa99b947aaaa2e009388f27e0c0300899b0dba26f9166ad51a` |

Verify the checksums from the repository root:

```bash
sha256sum xWalk-rpi5-hw/xWalkAudioResources/sounds/*.wav xWalk-rpi5-hw/xWalkAudioResources/music/*.mp3
```

## 6. Testing

`ci/check-audio.py` checks that both WAV files open, report at
least one channel, a positive frame rate, and at least one frame with readable samples, and that the MP3 starts
with an ID3 tag or an MPEG frame-sync header. It runs at the end of the complete hardware regression and can be
run alone from `xWalk-rpi5-hw`:

```bash
python3 ci/check-audio.py
```

The check validates presence and media headers only; it does not compare checksums or play audio.

## 7. Safety and constraints

- Do not modify, transcode, or rename the imported files without updating the provenance and integrity records.
- Asset-specific rights are unconfirmed; confirm them before commercial redistribution.

## 8. Related notes

- [xWalk-rpi5-hw](../xWalk-rpi5-hw.md)
- [xWalkTest](../xWalkTest/xWalkTest.md)

---

[Previous page](../xWalk-rpi5-hw.md) · [Chapter index](../../index.md) · [Next page](../xWalkController/xWalkController.md)
