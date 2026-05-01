---
# 2wd-aqb
title: Strict-mirror keys + verb re-evaluation in wrap/lineBreaks/indentation groups
status: completed
type: task
priority: normal
created_at: 2026-05-01T18:27:31Z
updated_at: 2026-05-01T18:40:00Z
sync:
    github:
        issue_number: "608"
        synced_at: "2026-05-01T19:25:16Z"
---


## Summary of Changes

Removed all key-eliding `override class var key` lines and renamed types where the verb was wrong.

### Types renamed + group changed
- `WrapMultilineStatementBraces` → `BreakBeforeMultilineBrace` (`wrap` → `lineBreaks` group, file moved to `Rules/LineBreaks/`)
- `WrapConditionalAssignment` → `BreakAfterAssignToConditional` (`wrap` → `lineBreaks` group, file moved to `Rules/LineBreaks/`)

### Types renamed (group unchanged)
- `SwitchCaseIndentation` → `IndentSwitchCases` (and `SwitchCaseIndentationConfiguration` → `IndentSwitchCasesConfiguration`)
- `WrapSingleLineBodies` → `LayoutSingleLineBodies` (and `SingleLineBodiesConfiguration` → `LayoutSingleLineBodiesConfiguration`, `WrapSingleLineBodiesState` → `LayoutSingleLineBodiesState`)
- `WrapSwitchCaseBodies` → `LayoutSwitchCaseBodies` (and `SwitchCaseBodiesConfiguration` → `LayoutSwitchCaseBodiesConfiguration`)

### Just dropped the override
- `WrapMultilineFunctionChains` — key now `wrap.wrapMultilineFunctionChains`
- `WrapSingleLineComments` — key now `wrap.wrapSingleLineComments`
- `NestedCallLayout` — key now `wrap.nestedCallLayout` (unchanged in value, just removed redundant override)
- `EnsureLineBreakAtEOF` — key now `lineBreaks.ensureLineBreakAtEOF`

### Migrations
- `swiftiomatic.json` updated to new keys
- `Tests/SwiftiomaticTests/API/ConfigurationTests.swift` fixture for `atEndOfFile` updated
- All call sites in `RewritePipeline.swift`, `LayoutWriter.swift`, `TokenStream+ControlFlow.swift`, `Context.swift`, and `Configuration+Testing.swift` rewired

### Verification
- xc-swift package compile succeeds
- Full test suite passes (3155 / 3155)
