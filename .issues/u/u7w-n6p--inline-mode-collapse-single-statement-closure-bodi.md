---
# u7w-n6p
title: 'Inline mode: collapse single-statement closure bodies'
status: completed
type: feature
priority: normal
created_at: 2026-05-08T04:52:11Z
updated_at: 2026-05-08T04:54:34Z
sync:
    github:
        issue_number: "652"
        synced_at: "2026-05-08T05:22:45Z"
---

LayoutSingleLineBodies inline mode does not transform ClosureExprSyntax, so trailing closures with a single statement spanning multiple lines stay wrapped.\n\nExample (currently unchanged in inline mode):\n\n    prepareDependencies {\n        $0.defaultDatabase = try! AppDatabase.actual.connection\n    }\n\nExpected:\n\n    prepareDependencies { $0.defaultDatabase = try! AppDatabase.actual.connection }\n\nAdd a transform(_:original:parent:context:) overload for ClosureExprSyntax that mirrors inlineFunction.



## Summary of Changes

- Added `transform(_: ClosureExprSyntax, ...)` overload to `LayoutSingleLineBodies` that dispatches to a new `inlineClosure` helper in inline mode (`Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift`).
- `inlineClosure` mirrors `inlineFunction`: requires single statement, multiline shape, no comments anywhere inside the closure, and that the collapsed line fits `LineLength`. Preserves any signature (`{ x in ... }`) by trimming its trivia and inserting a single space.
- Added a new `inlineClosureBody` finding message.
- Tests in `Tests/SwiftiomaticTests/Rules/Wrap/LayoutSingleLineBodiesTests.swift`: covers trailing-closure inlining (the user's `prepareDependencies` case), closures with signatures, already-inline no-op, multi-statement bail, length-limit bail, comment bail, and interaction with a preceding `// sm:ignore:next` comment.
- Build deferred at user request (other agents working).
