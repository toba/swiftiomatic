---
# 4ey-fg8
title: Standardize rule config naming verbs (use*/no*/flag*/require*)
status: review
type: task
priority: normal
created_at: 2026-05-01T18:40:33Z
updated_at: 2026-05-01T18:57:31Z
sync:
    github:
        issue_number: "605"
        synced_at: "2026-05-01T19:25:15Z"
---

Apply naming-verb consistency cleanup per agreed evaluation:

## Renames

### A. `flag*` → `no*` (always-a-bug; default lint to `error`)
- flagSwapThenRemoveAll → noSwapThenRemoveAll
- flagMutableCapture → noMutableCapture
- flagDuplicateDictionaryKeys → noDuplicateDictionaryKeys
- flagDuplicateConditions → noDuplicateConditions (already error)
- flagIdenticalOperands → noIdenticalOperands
- flagUnusedSetterValue → noUnusedSetterValue

### B. `no*` → `flag*` (diagnostic only — no rewrite)
- noForceTry → flagForceTry
- noForceCast → flagForceCast
- noForceUnwrap → flagForceUnwrap
- noMutationDuringIteration → flagMutationDuringIteration

### C. `enforce*` → `use*`
- enforceSwiftTestingNames → useSwiftTestingNames

### D. `prefer*` → `use*` (commit fully to use* form)
All prefer* rules

## Tasks
- [ ] Inventory all references (class, file, key, schema, tests)
- [ ] Rename A (flag→no) + set default lint=error
- [ ] Rename B (no→flag)
- [ ] Rename C (enforce→use)
- [ ] Rename D (prefer→use)
- [ ] Update swiftiomatic.json
- [ ] Build clean + full test suite passes

## Summary of Changes

### Files renamed (Sources + Tests)
**Group A (flag→no, default lint=error):**
- FlagSwapThenRemoveAll → NoSwapThenRemoveAll
- FlagMutableCapture → NoMutableCapture
- FlagDuplicateDictionaryKeys → NoDuplicateDictionaryKeys
- FlagDuplicateConditions → NoDuplicateConditions
- FlagIdenticalOperands → NoIdenticalOperands
- FlagUnusedSetterValue → NoUnusedSetterValue

**Group B (no→flag, lint-only with no rewrite):**
- NoMutationDuringIteration → FlagMutationDuringIteration

**Note:** NoForce{Try,Cast,Unwrap} were NOT renamed — they ARE StaticFormatRule with rewrite logic (currently disabled in config). My initial `worth doing` table was wrong about those.

**Group C:** EnforceSwiftTestingNames → UseSwiftTestingNames

**Group D (prefer→use):** All 17 prefer* rules renamed to use*

### Cross-file updates
- `Context.swift`: state vars (`useFinalClassesState`, `swiftTestingTestCaseNamesState`)
- `RewritePipeline.swift`: all dispatch references
- `RewriteCoordinator.swift`: comment
- `CollapseSimpleIfElse.swift`: doc comment ref to UseTernary
- `Configuration+Update.swift`: docstring examples
- `LintSyntaxRule.swift`, `StructuralFormatRule.swift`: `// sm:ignore useFinalClasses`
- `swiftiomatic.json`: all keys renamed; values for "always-a-bug" rules set to `error`

### Build status
- Library build: PASS
- Test suite: blocked by concurrent-agent renames (SortGetSetAccessors/SortModifiers test files lag behind source) — out of scope per CLAUDE.md

### Defaults set to `.error` for always-a-bug rules
NoSwapThenRemoveAll, NoMutableCapture, NoDuplicateDictionaryKeys, NoIdenticalOperands, NoUnusedSetterValue (NoDuplicateConditions already was)

### Incidental fix
swiftiomatic.json had `"lint": "4no"` typo on flagEmptyCollectionLiteral — corrected to `"no"` since it blocked the prebuild lint.
