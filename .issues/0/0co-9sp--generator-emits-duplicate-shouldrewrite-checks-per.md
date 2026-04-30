---
# 0co-9sp
title: Generator emits duplicate shouldRewrite checks per node
status: completed
type: task
priority: normal
created_at: 2026-04-30T02:44:52Z
updated_at: 2026-04-30T02:55:16Z
sync:
    github:
        issue_number: "519"
        synced_at: "2026-04-30T03:34:39Z"
---

## Problem

The code generator emits avoidable duplication in `CompactStageOneRewriter+Generated.swift`. The `willEnter`/`didExit` `shouldFormat` (a.k.a. `shouldRewrite`) check is computed twice for the same node:

- Line 37 and 42 for `RedundantSelf`
- Line 50 and 60 for the same rule on `AccessorDecl`
- (likely repeated across other rule × node-type combinations)

Pre-recursion `Syntax(node)` is the same input both times, so the result is identical, but each check runs the full chain:
- `isInsideSelection`
- `startLocation`
- `ruleMask` lookup
- config lookup

## Expected behavior

Cache the result once per visit, like the hand-written `CompactSyntaxRewriter.swift` we're migrating to:

```swift
let runRedundantSelf = context.shouldRewrite(RedundantSelf.self, ...)
```

See `Sources/SwiftiomaticKit/Rewrites/CompactSyntaxRewriter.swift:31, 43, 65` for the pattern.

## Fix

Update the generator template (likely in `Sources/Generator/`) so the emitted dispatch caches each rule's `shouldRewrite` result in a local `let` and reuses it for both the `willEnter` and `didExit` calls instead of recomputing.

## Tasks

- [x] Locate the template that emits per-node dispatch in `CompactStageOneRewriter+Generated.swift`
- [x] Add caching: emit `let runX = context.shouldRewrite(X.self, ...)` once per rule per visit
- [x] Reuse the cached value in willEnter/didExit branches
- [x] Regenerate and confirm duplicate calls are gone
- [x] Run the test suite to confirm behavior is unchanged



## Additional: rename generated file

While doing this work, also rename the generated file from `CompactStageOneRewriter+Generated.swift` to `CompactSyntaxRewriter+Generated.swift` to match the renamed hand-written rewriter (`CompactSyntaxRewriter.swift`).

- [x] Update the generator to emit `CompactSyntaxRewriter+Generated.swift`
- [x] Update the extended type from `CompactStageOneRewriter` to `CompactSyntaxRewriter`
- [x] Update any references in `Package.swift`, build plugin, or docs that mention the old filename
- [x] Confirm the build plugin no longer writes the old file


## Summary of Changes

The original finding's premise was incorrect: the current generator does **not** emit `CompactStageOneRewriter+Generated.swift`. That file existed on disk in `Sources/SwiftiomaticKit/Generated/` but was a stale artifact from a previous generator version (commit `1817379a wru-y41` switched to a hand-written rewriter). The directory is excluded in `Package.swift`, so nothing referenced it — except `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift:115`, which still constructed `CompactStageOneRewriter(...)` against that stale class declaration.

The hand-written `Sources/SwiftiomaticKit/Rewrites/CompactSyntaxRewriter.swift` (the migration target) already implements the cached-`shouldRewrite` pattern (`let runRedundantSelf = context.shouldRewrite(...)`), so there is no template duplication to fix.

### Cleanup actually performed

- Deleted stale `Sources/SwiftiomaticKit/Generated/CompactStageOneRewriter+Generated.swift`.
- Renamed all source/test/doc references from `CompactStageOneRewriter` → `CompactSyntaxRewriter` across 16 rule files, `LintCoordinator.swift`, `StaticFormatRule.swift`, `TokenRewrites.swift`, both performance test files, `Sources/SwiftiomaticKit/README.md`, `Sources/GeneratorKit/README.md`, and `CLAUDE.md`.
- Migrated `RewriteCoordinatorPerformanceTests.swift:115` from `CompactStageOneRewriter(...)` to `CompactSyntaxRewriter(...)`.
- Updated `CLAUDE.md` Code Generation section to remove the `CompactStageOneRewriter+Generated.swift` bullet and add `ConfigurationSchema+Generated.swift` (which is actually emitted).
- Added `// sm:ignore-file: fileLength, typeBodyLength, functionBodyLength` to `CompactSyntaxRewriter.swift` (was present on the old generated file but lost in the hand-write). The 2250-line/2246-line lint findings on this file are tracked in `wr8-7qm`.

### Verification

- `xc-swift swift_package_build --build-tests`: succeeded.

### Closing the rename ask

Since there is no generator template currently producing this output, the file rename was achieved by deleting the stale generated copy and renaming the type/references everywhere else. If a generator template is reintroduced in the future (e.g. to retire the hand-written 2250-line file per `wr8-7qm`), it should emit `CompactSyntaxRewriter+Generated.swift` and apply the cached-`shouldRewrite` pattern from the start.
