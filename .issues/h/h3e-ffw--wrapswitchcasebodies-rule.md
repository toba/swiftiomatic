---
# h3e-ffw
title: WrapSwitchCaseBodies rule
status: completed
type: feature
priority: normal
created_at: 2026-04-24T22:31:12Z
updated_at: 2026-04-24T22:43:43Z
sync:
    github:
        issue_number: "384"
        synced_at: "2026-04-24T22:54:05Z"
---

Create a new SyntaxFormatRule that controls whether switch case bodies are wrapped (multiline) or inlined.

## Modes
- `wrap` — always multiline (body on its own line)
- `adaptive` — inline each case independently if it's a single statement fitting within print width; leave others wrapped

## Tasks
- [x] Study existing rule patterns (WrapCompoundCaseItems, SingleLineBodies)
- [x] Add configuration option with mode enum
- [x] Create the rule implementation
- [x] Create tests
- [x] Register the rule in generated code


## Summary of Changes

Created `WrapSwitchCaseBodies` rule with two modes:
- **wrap** (default, off): expands inline case bodies onto new lines
- **adaptive**: inlines single-statement case bodies that fit within line length

Files:
- `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/WrapSwitchCaseBodies.swift` — rule + config
- `Tests/SwiftiomaticTests/Rules/Wrap/WrapSwitchCaseBodiesTests.swift` — 11 tests
- `Tests/SwiftiomaticTestSupport/Configuration+Testing.swift` — registered config
- `schema.json` — regenerated
