---
# su3-lef
title: Break GeneratorKit → SwiftiomaticKit circular dependency
status: ready
type: task
created_at: 2026-04-19T17:31:45Z
updated_at: 2026-04-19T17:31:45Z
parent: rcc-z52
---

`ConfigurationSchemaGenerator` imports `SwiftiomaticKit` for `LayoutRegistry.rootRules`, `LayoutRegistry.rules(in:)`, and `IndentationSetting`. This creates a circular dependency that blocks the build tool plugin.

Options:
- Move `LayoutRegistry` enumeration to AST-based scanning (like rules already work)
- Or extract the needed types (`LayoutRegistry`, `IndentationSetting`) to `ConfigurationKit`

- [ ] Remove `import SwiftiomaticKit` from `ConfigurationSchemaGenerator.swift`
- [ ] Replace runtime `LayoutRegistry` access with AST-scanned data from `ConfigurableCollector`
- [ ] Remove `SwiftiomaticKit` from `GeneratorKit`'s dependency list in Package.swift
- [ ] Verify build passes
