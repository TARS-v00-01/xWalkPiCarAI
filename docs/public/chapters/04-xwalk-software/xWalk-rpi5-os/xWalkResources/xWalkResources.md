<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkResources

**4. xWalk software &middot; Module 14**

<!-- xwalk-page-header:end -->

# xWalkResources

`xWalkResources` holds the original HUD, boot and shutdown artwork, the Pi 5 mesh with its provenance and
license, the boot animation and the Qt resource manifest template. The images remain unchanged and are embedded
in the executable.

## 1. Overview

- `cmake/XWalkBuildMode.cmake` configures
  `resources.qrc.in` into `<build>/generated/resources.qrc`, which every executable and Google Test embeds.
- Resource aliases: `:/hud.png` (`xWALK Robot Command HUD.png`), `:/boot-artwork.png`
  (`xwalk-boot-artwork.png`), `:/shutdown-artwork.png` (`xwalk-shutdown-artwork.png`), `:/pi5.mesh`,
  `:/desktop.cfg` (generated profile) and `:/robot.cfg` (from `xWalkConfig`).
- `pi5.mesh` is derived from Raspberry Pi Ltd's official Pi 5 CAD model and is embedded in all three builds.
  Its format is magic `XWM1`, a little-endian uint32 triangle count, then one uint8 material and nine
  little-endian float32 coordinates per triangle. Provenance, tessellation settings and the Robot HAT V4
  reference sources are recorded in
  `MODEL_SOURCES.md`;
  the full supplied disclaimer and MIT license are retained in
  `PI5_MODEL_LICENSE.txt`. Both files are
  installed under `share/xwalk-pi5car`. FreeCAD and Python are asset-preparation tools only; the application is
  entirely C++/Qt.
- `xwalk-hardware-boot.mp4` is the car's boot animation. It is not embedded in the HUD: the Raspberry Pi 5 Yocto
  image (`xWalk-rpi5-yocto`, recipe `xwalk-boot-splash`) reads it from here and turns it into the Plymouth boot
  splash shown before the HUD starts. Replace the file here to change the animation; the next image build picks
  it up.

## 2. Source location

`xWalk-rpi5-os/xWalkResources` - source directory

## 3. Directory layout

```text
xWalkResources/
    xWALK Robot Command HUD.png               Original HUD background artwork
    xwalk-boot-artwork.png                    Boot-readiness overlay artwork
    xwalk-shutdown-artwork.png                Shutdown and restart display artwork
    xwalk-hardware-boot.mp4                   Boot animation consumed by the Yocto image
    pi5.mesh                                  Binary Pi 5 triangle mesh (XWM1)
    MODEL_SOURCES.md                          Mesh and HAT geometry provenance (installed, tool-read)
    PI5_MODEL_LICENSE.txt                     Retained disclaimer and MIT license (installed)
    resources.qrc.in                          Qt resource manifest template
    test/src/xWalkResourcesGoogleTest.cpp     Embedded artwork and demo configuration contract
```

## 4. Build

The module has no CMake target of its own; the root project configures the manifest and registers
`xWalkResourcesGoogleTest` with `xwalk_os_add_test(xWalkResources Qt5::Widgets)`.

## 5. Testing

```bash
ctest --test-dir build-standalone -L xWalkResources --output-on-failure
```

`OriginalArtworkAndDemoConfigurationAreBundled` checks that `:/hud.png` is larger than 1000 × 700 and that the
embedded `:/robot.cfg` is the simulated demo configuration.

## 6. Safety and constraints

- Keep the artwork unchanged; the HUD geometry depends on the original image proportions.
- The Robot HAT V4 geometry is an illustrative estimate, not a dimensioned vendor CAD model; no manufacturing fit
  is guaranteed. The reference photograph is not redistributed.
- Retain `PI5_MODEL_LICENSE.txt` with any redistribution of the mesh.

## 7. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkDesktop](../xWalkDesktop/xWalkDesktop.md)
- [xWalkConfig](../xWalkConfig/xWalkConfig.md)

---

[Previous page](../xWalkNetwork/xWalkNetwork.md) · [Chapter index](../../index.md) · [Next page](../xWalkRuntime/xWalkRuntime.md)
