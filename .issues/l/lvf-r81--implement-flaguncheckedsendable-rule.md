---
# lvf-r81
title: Implement FlagUncheckedSendable rule
status: completed
type: feature
priority: normal
created_at: 2026-05-09T16:42:49Z
updated_at: 2026-05-09T16:46:20Z
parent: z75-gax
sync:
    github:
        issue_number: "678"
        synced_at: "2026-05-09T17:07:17Z"
---

Item 5 from z75-gax. Review-only warning on `@unchecked Sendable` conformance — fix needs type info (e.g. SE-0470 metatype storage).

- [x] Write tests
- [x] Implement rule
- [x] Verify build/test passes



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Unsafety/FlagUncheckedSendable.swift` — visits each `InheritedTypeSyntax`; if its type is an `AttributedTypeSyntax` with `@unchecked` and base `Sendable` (or `Swift.Sendable`), emits a review-only warning. Group: `unsafety`.
- Added `Tests/SwiftiomaticTests/Rules/FlagUncheckedSendableTests.swift` — 6 tests covering class/extension forms, mixed inheritance, qualified `Swift.Sendable`, and negatives (`Sendable` without `@unchecked`, `@unchecked` on a non-Sendable protocol).
- Note: existing rule classes in this codebase use `@unchecked Sendable` (NSObject ancestry); this rule will flag them as expected — disable per-rule or rely on `// sm:ignore` if running on the Swiftiomatic source.
- Full test suite: 3331 passed, 0 failed.
