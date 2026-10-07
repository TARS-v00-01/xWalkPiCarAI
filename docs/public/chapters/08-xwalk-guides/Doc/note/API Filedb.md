<!-- xwalk-page-header:start -->

[xWalk documentation](../../../index.md) / [8. xWalk guides](../../index.md) / `XWalkConfigStore` and `XWalkConfig`

**8. xWalk guides &middot; Module 03**

<!-- xwalk-page-header:end -->

# `XWalkConfigStore` and `XWalkConfig`

`XWalkConfigStore` provides flat key-value persistence. `XWalkConfig` provides
section-aware configuration persistence. Both are defined by the
`xWalkConfig` module.

Configuration objects own their paths and in-memory values. Filesystem access
passes through common file wrappers. Deployment owns directory creation,
permissions, and recovery policy.

Applications should load and validate configuration before constructing motor,
servo, or robot components. Hardware classes do not open configuration files.

---

[Previous page](API%20ADC.md) · [Chapter index](../../index.md) · [Next page](API%20Pin.md)
