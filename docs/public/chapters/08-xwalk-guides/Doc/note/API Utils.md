<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / C++ utility interfaces

**8. xWalk guides &middot; Module 20**

<!-- xwalk-page-header:end -->

# C++ utility interfaces

The `xWalkUtils` module contains:

- `XWalkUtils` for injected platform utility and output operations;
- `XWalkLazyReader<ValueType>` for bounded-rate callback value caching;
- `XWalkStderrGuard` for scope-bound stderr suppression and restoration.

Generic utilities do not create hardware or platform services. Callers provide
callbacks and contexts explicitly. Common non-member functions remain in the
`xwalk::hal::common` namespace under `xWalkLibraryCommon`.

---

[Previous page](API%20TTS.md) · [Chapter index](../../index.md) · [Next page](Clean%20Build%20Script%20Guide.md)
