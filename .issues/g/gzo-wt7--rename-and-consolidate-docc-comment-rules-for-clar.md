---
# gzo-wt7
title: Rename and consolidate DocC comment rules for clarity
status: completed
type: task
priority: normal
created_at: 2026-05-01T19:12:19Z
updated_at: 2026-05-01T19:18:12Z
sync:
    github:
        issue_number: "606"
        synced_at: "2026-05-01T19:25:16Z"
---

Rename DocC-related rules in Sources/SwiftiomaticKit/Rules/Comments/ for self-documenting names and remove overlap.

## Tasks
- [ ] Split `ConvertRegularCommentToDocC` into `UseDocCommentsOnAPI` (// -> ///), drop the body-half (let `NoDocCommentsInFunctionBodies` own it)
- [ ] Rename `UseTripleSlashForDocComments` -> `UseTripleSlashOverDocBlock`
- [ ] Rename `RequireDocCommentSummary` -> `RequireDocSummaryStructure`
- [ ] Rename `RequireParameterDocs` -> `RequireParameterAndReturnDocs`
- [ ] Rename `NoDocCommentsInsideFunctions` -> `NoDocCommentsInFunctionBodies`
- [ ] Rename `FlagOrphanedDocComment` -> `NoOrphanedDocComment`
- [ ] Update tests and configuration references
- [ ] Run xc-swift diagnostics + filtered tests



## Summary of Changes

Renamed 6 DocC-related rules for self-documenting names:

- `ConvertRegularCommentToDocC` → `UseDocCommentsOnAPI`
- `UseTripleSlashForDocComments` → `UseTripleSlashOverDocBlock`
- `RequireDocCommentSummary` → `RequireDocSummaryStructure`
- `RequireParameterDocs` → `RequireParameterAndReturnDocs`
- `NoDocCommentsInsideFunctions` → `NoDocCommentsInFunctionBodies`
- `FlagOrphanedDocComment` → `NoOrphanedDocComment`

Updated rule, test files, and `RewritePipeline.swift` call sites. Updated `UseDocCommentsOnAPI` docstring to make its corner-case demote-to-regular behavior explicit and cross-reference `NoDocCommentsInFunctionBodies` and `NoOrphanedDocComment`.

Did **not** structurally split `UseDocCommentsOnAPI` (originally `ConvertRegularCommentToDocC`) — its corner cases (directive prefixes, blank-line orphans, consecutive-member preservation) only partially overlap with the lint-only rules, and clean splitting would require reimplementing them or losing functionality. The cross-reference in the docstring resolves the discoverability concern.

Verified: `xc-swift swift_diagnostics` clean build, all 61 tests in the affected suites pass.
