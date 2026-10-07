<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [4. xWalk software](../../index.md) / GNOME login keyboard on small
displays

**4. xWalk software &middot; Module 07**

<!-- xwalk-page-header:end -->

# GNOME login keyboard on small displays

The Pi's MPI5001 display reports 800 × 480. Its GNOME login keyboard was visibly missing the
bottom row containing the symbol switch and spacebar. The xWalk Android-style C++ keyboard
runs inside the signed-in app; GNOME owns login and lock-screen input.

`gnome-small-screen-keyboard.sh` is an optional, version-specific deployment workaround.
It extracts the installed GNOME 46 keyboard resource, checks its SHA-256, and changes the
landscape height from one-third to one-half of the monitor height on screens up to 600 pixels high.
Other sizes retain the original geometry. Authentication and key handling are unchanged.
The upstream resource remains installed unchanged. The generated copy is root-owned.

The override uses GLib's [resource overlay mechanism](https://docs.gtk.org/gio/struct.Resource.html).
It installs a GDM service environment override and a user environment-generator configuration.
It is not part of the C++ application and is not installed automatically by CMake.

```bash
sudo ./xWalkDeploy/gnome-small-screen-keyboard.sh
```

A GDM restart closes the current graphical session. User session environment changes require a
fresh user manager/session. Check that the GNOME Shell process inherits `G_RESOURCE_OVERLAYS`
before attributing a successful layout to this workaround. Visual confirmation of all four rows
is required; a successful restart alone does not verify the fix.

Remove this version-specific override before upgrading GNOME. Regenerate only after reviewing the
new upstream resource; the installer refuses a different source hash. To roll back, remove only
these two xWalk configuration files, reload systemd, and restart the graphical session when ready:

```bash
sudo rm -- /etc/systemd/system/gdm.service.d/90-xwalk-small-screen-keyboard.conf /etc/environment.d/90-xwalk-small-screen-keyboard.conf
sudo systemctl daemon-reload
```

The unused resource copy under `/usr/local/share/xwalk/gnome-small-screen` may remain after rollback.
Enabling GNOME's screen keyboard is a separate accessibility setting; rollback does not disable it.

The initial Pi override was retired after its visual fix could not be confirmed.
The operator selected automatic desktop access instead. Do not treat the
height override as a verified deployment default.

---

[Previous page](xWalkDeploy.md) · [Chapter index](../../index.md) · [Next page](../xWalkDesktop/xWalkDesktop.md)
