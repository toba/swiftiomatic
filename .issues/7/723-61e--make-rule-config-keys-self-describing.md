---
# 723-61e
title: Make rule config keys self-describing
status: completed
type: task
priority: normal
created_at: 2026-05-01T18:57:10Z
updated_at: 2026-05-01T19:46:03Z
sync:
    github:
        issue_number: "607"
        synced_at: "2026-05-01T19:54:41Z"
---

Drop short keys that depend on group prefix (BlankLines/Indentation/Wrap rules) and remove redundant explicit key overrides where they match the type-derived default. See ~/.claude/plans/adaptive-whistling-cascade.md.

## Tasks

- [x] BlankLines: drop key overrides on 5 rules
- [x] Indentation: drop key overrides on IndentBlankLines, IndentConditionalCompilationBlocks
- [x] Wrap: drop key override on WrapCompoundCaseItems
- [x] Cleanup: drop redundant explicit `key` on 13 rules (MultilineTrailingCommaBehaviorSetting kept its explicit key, like IndentationSetting)
- [x] Update test fixtures referencing old keys (ConfigurationTests.swift)
- [x] Schema regenerated automatically via build plugin
- [ ] Test suite blocked by unrelated WIP in OrderGetSetAccessorsTests/OrderModifiersTests



## Summary of Changes

Renamed 8 rule config keys to be self-describing standalone:

`blankLines.afterGuardStatements` → `blankLines.blankLinesAfterGuardStatements`
`blankLines.afterImports` → `blankLines.blankLinesAfterImports`
`blankLines.afterSwitchCase` → `blankLines.blankLinesAfterSwitchCase`
`blankLines.aroundMark` → `blankLines.blankLinesAroundMark`
`blankLines.betweenScopes` → `blankLines.blankLinesBetweenScopes`
`indentation.blankLines` → `indentation.indentBlankLines`
`indentation.conditionalCompilationBlocks` → `indentation.indentConditionalCompilationBlocks`
`wrap.compoundCaseItems` → `wrap.wrapCompoundCaseItems`

Mechanism: dropped `override static var key` (or `static let key`) so `Configurable`'s default derivation (type name → lowerCamelCase) takes over. Type names already encode the group concept, giving self-describing keys.

Cleanup: dropped redundant explicit `key` on 13 rules where the override already matched the type-derived default (single source of truth).

Exceptions kept: `IndentationSetting` (`unit`) and `MultilineTrailingCommaBehaviorSetting` (`multilineTrailingCommaBehavior`) — type names end in `Setting` to disambiguate from the value enum, so explicit keys remain necessary.

## Review Needed

- Test suite cannot be run because Tests/SwiftiomaticTests/Rules/OrderGetSetAccessorsTests.swift and OrderModifiersTests.swift reference types that don't exist (unrelated WIP from another agent). Library builds clean.



## Follow-up rename (imperative naming)

Renamed 6 `BlankLines*` types to imperative `Insert*` form (matches house style: Use/Drop/Sort/Wrap/Indent/Hoist/Break/...):

- `BlankLinesAfterGuardStatements` → `InsertBlankLineAfterGuard`
- `BlankLinesAfterImports` → `InsertBlankLineAfterImports`
- `BlankLinesAfterSwitchCase` → `InsertBlankLineAfterSwitchCase`
- `BlankLinesAroundMark` → `InsertBlankLinesAroundMark`
- `BlankLinesBetweenScopes` → `InsertBlankLineBetweenScopes`
- `BlankLinesBeforeControlFlowBlocks` → `InsertBlankLineBeforeControlFlowBlocks`

Each rename: `git mv` source file + `git mv` test file + sed-replaced symbol references across Sources/ and Tests/. Updated JSON keys in `ConfigurationTests.swift` fixture. Generated files regenerate automatically. Library builds clean.
