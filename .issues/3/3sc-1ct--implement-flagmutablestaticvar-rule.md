---
# 3sc-1ct
title: Implement FlagMutableStaticVar rule
status: completed
type: feature
priority: normal
created_at: 2026-05-09T16:42:44Z
updated_at: 2026-05-09T16:46:20Z
parent: z75-gax
sync:
    github:
        issue_number: "683"
        synced_at: "2026-05-09T17:07:17Z"
---

Item 4 from z75-gax. Flag `static var` with mutable storage outside test files (`Tests/`, `*Tests.swift`). Flag-only — fix is contextual (actor, Mutex, @TaskLocal).

- [x] Write tests
- [x] Implement rule
- [x] Verify build/test passes



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Unsafety/FlagMutableStaticVar.swift` — flags `static var` with stored mutable storage. Skips computed (`{ get }` / `{ get set }`) properties; flags stored vars even with `willSet`/`didSet`. Skips files under `Tests/` directories or named `*Tests.swift`. Group: `unsafety`.
- Added `Tests/SwiftiomaticTests/Rules/FlagMutableStaticVarTests.swift` — 8 tests covering stored, observed, computed, get/set, instance, and explicit-typed forms.
- Full test suite: 3331 passed, 0 failed.
