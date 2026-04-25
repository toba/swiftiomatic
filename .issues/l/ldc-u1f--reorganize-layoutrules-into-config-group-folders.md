---
# ldc-u1f
title: Reorganize Layout/Rules into config-group folders
status: completed
type: task
priority: normal
created_at: 2026-04-25T16:58:41Z
updated_at: 2026-04-25T17:00:46Z
sync:
    github:
        issue_number: "403"
        synced_at: "2026-04-25T17:04:23Z"
---

Move Sources/SwiftiomaticKit/Layout/Rules/*.swift into subfolders that match their ConfigurationGroup, following the existing convention used in Sources/SwiftiomaticKit/Syntax/Rules/.

## Tasks

- [x] Create LineBreaks/ and move 9 files
- [x] Create BlankLines/ and move 3 files
- [x] Create Indentation/ and move 4 files
- [x] Create Spaces/ and move 2 files
- [x] Create Literals/ and move 3 files
- [x] Create Wrap/ and move 1 file
- [x] Verify ExtensionAccessLevel.swift placement (group .access -> Access folder)
- [x] Build to confirm no breakage



## Summary of Changes

Moved 22 files from `Sources/SwiftiomaticKit/Layout/Rules/` into 6 group subfolders matching their `ConfigurationGroup`:

- `LineBreaks/` (9): AlignWrappedConditions, AroundMultilineExpressionChainComponents, BeforeEachArgument, BeforeEachGenericRequirement, BeforeGuardConditions, BetweenDeclarationAttributes, ElseCatchOnNewLine, LineLength, RespectsExistingLineBreaks
- `BlankLines/` (3): ClosingBraceAsBlankLine, CommentAsBlankLine, MaximumBlankLines
- `Indentation/` (4): Indentation, IndentBlankLines, IndentConditionalCompilationBlocks, TabWidth
- `Spaces/` (2): SpacesAroundRangeFormationOperators, SpacesBeforeEndOfLineComments
- `Literals/` (3): MultiElementCollectionTrailingCommas, MultilineTrailingCommaBehavior, ReflowMultilineStringLiterals
- `Wrap/` (1): KeepFunctionOutputTogether

`ExtensionAccessLevel.swift` (group `.access`) is already correctly placed in `Sources/SwiftiomaticKit/Syntax/Rules/Access/` — no move needed.

Used `git mv` to preserve history. Build succeeds in debug configuration.
