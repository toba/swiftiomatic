---
# 38h-ogh
title: 'P11: Verify preparedAcronyms is not accessed when UppercaseAcronyms is disabled'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:58:19Z
updated_at: 2026-04-30T19:47:07Z
parent: 6xi-be2
sync:
    github:
        issue_number: "545"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/Context.swift:80`

`preparedAcronyms` is `lazy` — it's only computed when first accessed. The intent is that disabled `UppercaseAcronyms` never accesses it, so the computation never runs. Need to verify the generated dispatcher / rule code doesn't touch it for a disabled rule (e.g. via `willEnter` defaults).

## Potential performance benefit

If currently violated: each lint run on a config with `UppercaseAcronyms` disabled still pays an `uppercased() + sorted + map` over the configured acronym list. Small but pure waste.

## Reason deferred

Requires inspection / instrumentation rather than code change. Track here so it's not lost. Could become a unit test once we have a test that asserts `preparedAcronyms` is never realized for a config where `UppercaseAcronyms` is off.



## Summary of Changes

Verified by inspection at `Sources/SwiftiomaticKit/Layout/LayoutWriter.swift:71-76`:

```swift
if context.shouldRewrite(UppercaseAcronyms.self, at: Syntax(result)) {
    result = applyUppercaseAcronyms(result, context: context)
}
```

`applyUppercaseAcronyms` is the only call site that touches `context.preparedAcronyms` (LayoutWriter.swift:211). `shouldRewrite` short-circuits via `enabledRules.contains` (P1), so when `UppercaseAcronyms` is off the lazy var is never realized — the `uppercased() + sorted + map` chain never runs.

Added a doc comment to `Context.preparedAcronyms` recording the invariant so a future call site has the gating spelled out.
