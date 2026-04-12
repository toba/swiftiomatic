---
# fwk-0kx
title: Investigate module splitting for incremental build speed
status: completed
type: epic
priority: normal
created_at: 2026-04-11T22:03:03Z
updated_at: 2026-04-12T01:32:33Z
sync:
    github:
        issue_number: "196"
        synced_at: "2026-04-12T01:32:51Z"
---

SwiftiomaticKit is 618 files in one module. Rules (472 files) are completely independent of each other but all depend on Models/Support/Configuration.

## Analysis Summary

- Rules have zero inter-rule imports — perfect for splitting
- ~463 rules depend on Models, ~293 on Support, ~111 on Configuration
- Changing a rule recompiles all 618 files; with splitting, only the affected module
- ~60-80 types need `public`/`package` access modifiers (due to InternalImportsByDefault)
- Estimated improvement: 10-30% on incremental builds (depends on what changes)

## Proposed Structure

```
SwiftiomaticCore (72 files) — Models, Support, Configuration, Format
SwiftiomaticRules (472 files) — all rules + generated pipeline/registry
SwiftiomaticSourceKit (31 files) — TypeResolver, AsyncEnrichableRule
SwiftiomaticKit (thin facade) — re-exports everything
```

## Work Required

- [ ] Add `public`/`package` to ~60-80 types in Core
- [ ] Define new targets in Package.swift
- [ ] Add `import SwiftiomaticCore` to all rule files
- [ ] Update GeneratePipeline to emit correct imports
- [ ] Verify full test suite passes

## Tradeoffs

- Helps when changing individual rules (most common case)
- Does NOT help when changing Models/Support (everything still recompiles)
- 1-2 days effort
- Could further split Rules into category sub-modules (15 modules of ~30 files) for parallel compilation
