<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / xWalkKeyboard

**4. xWalk software &middot; Module 11**

<!-- xwalk-page-header:end -->

# xWalkKeyboard

`xWalkKeyboard` implements the native C++ Android-style touch keyboard, the shared holographic HUD style for touch
dialogs, and touch-sized message prompts through Qt Widgets.

## 1. Overview

Keyboard behavior:

- Staggered QWERTY rows and a wide English spacebar.
- `?123` switches to numbers and punctuation; the shift position selects additional symbols.
- Shift uppercases one letter; two quick Shift taps enable Caps Lock. Tap again to release it.
- Holding Backspace repeats deletion. Done and the downward key hide the keyboard.
- Text-field taps reopen the keyboard, including when the field already has focus. Tapping a text field opens
  it automatically when enabled; there is no Keyboard button.
- Password previews preserve the field's echo mode and clear on dismissal. Physical input works too.
- The keyboard docks at the screen bottom, up to 1000 pixels wide, without taking focus from its input field.
- Dialogs shrink their scroll viewport to the remaining display height; layout minimums cannot overlap the keys.
- Below 600 pixels of height (the Pi's 800 × 480 panel) the keys shorten to 38 pixels, so the keyboard uses at
  most half the display and the edited field stays visible. Key heights are otherwise fixed at 48 pixels.
- Keys are painted as holographic glass keys by `XWalkHudButtonStyle`, with an orange pressed state and a bright
  cyan Done and active-Shift key.

HUD style (`XWalkHudStyle`):

- The painted `XWalkHudFrame` background is a chamfered cyan panel with a radial glow, faint hexagon grid,
  scanlines, tick-marked targeting rings and glowing corner brackets, cached once per size. Its header has an
  uppercase title with icon, an orange accent rule and a CLOSE key.
- `XWalkHudButtonStyle` (installed by the desktop theme over Fusion) paints every dialog and keyboard key as a
  translucent glass key with cut corners, edge glow and corner ticks; pressing flashes orange.
- Shared helpers provide line icons (`hudIcon`), panel titles, the sliding `XWalkHudSwitch`, settings rows,
  navigation-rail items and the application style sheet.
- Every dialog that `fitDialog` wraps, and every `showTouchMessage` prompt, uses this style. A dialog picks its
  title icon with the `hudIcon` property. Dialogs fade in over 160 ms where the compositor supports window
  opacity.

This is Android-style interaction implemented for the Linux desktop; it does not load an Android IME or Gboard.
Predictive text, swipe input and voice input are not implemented. No text is sent to an external service.

## 2. Source location

`xWalk-rpi5-os/xWalkKeyboard` - source directory

## 3. Directory layout

```text
xWalkKeyboard/
    CMakeLists.txt                          Static library xWalkOsKeyboard and its Google Test
    include/XWalkKeyboard.h                 Touch keyboard and dialog fitting
    include/XWalkHudStyle.h                 HUD frame, key style, switch and helper factories
    include/XWalkTouchMessage.h             Touch-sized message and confirmation prompt
    src/XWalkKeyboard.cpp                   Layouts, Shift/Caps, repeat, compact mode and docking
    src/XWalkHudStyle.cpp                   HUD painting, icons and style sheet
    src/XWalkTouchMessage.cpp               Prompt implementation
    test/src/xWalkKeyboardGoogleTest.cpp    Input, Android-behavior and prompt-fit tests
```

## 4. Public interface

Namespace `xwalk::hal`:

- `XWalkKeyboard`: `setAutomatic(bool)`,
  `openFor(QLineEdit*)` and `fitDialog(QDialog*)`. It edits only the currently focused text field and borrows the
  dialogs it fits.
- `XWalkHudStyle.h`: `XWalkHudFrame`,
  `XWalkHudButtonStyle`, `XWalkHudSwitch`, `hudIcon`, `createHudTitle`, `createHudRow`, navigation-rail item
  factory and `hudStyleSheet`.
- `XWalkTouchMessage.h`:
  `bool showTouchMessage(QWidget* parent, const QString& titleText, const QString& text, bool question = false)`.

## 5. Build

CMake target `xWalkOsKeyboard` (static, C++17) links `Qt5::Widgets` and `xWalkOsBuild`, and compiles with
`-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion`. Build through the [desktop root](../xWalk-rpi5-os.md).

## 6. Testing

```bash
ctest --test-dir build-host -L xWalkKeyboard --output-on-failure
```

`TouchMessagesFitAndRetainLongText`, `KeyboardInput` and `KeyboardAndroidBehavior` drive Qt Test input
offscreen. Desktop-level symbol keyboard checks also run in `xWalkDesktopGoogleTest`.

## 7. Related notes

- [xWalk-rpi5-os](../xWalk-rpi5-os.md)
- [xWalkSettings](../xWalkSettings/xWalkSettings.md)
- [xWalkDesktop](../xWalkDesktop/xWalkDesktop.md)

---

[Previous page](../xWalkDesktop/xWalkDesktop.md) · [Chapter index](../../index.md) · [Next page](../xWalkMain/xWalkMain.md)
