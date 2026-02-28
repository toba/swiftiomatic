---
# 2ys-iip
title: Rebalance rule folders into ~13 themed directories
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:56Z
updated_at: 2026-02-28T17:53:21Z
parent: dz8-axs
blocked_by:
    - x76-2r9
---

Reorganize ~320 rule files from 8 uneven folders (1–110 files) into ~13 themed folders targeting 20–30 files each.

## Keep as-is
- `Format/` (138 files) — separate SwiftFormat engine
- `RuleConfigurations/` (82 files) — config structs

## Proposed folders

| Folder | ~Files | Theme |
|--------|-------:|-------|
| Naming | 22 | Identifiers, types, files, generics, naming conventions |
| AccessControl | 22 | Visibility, ACL, private/fileprivate, modifier order |
| TypeSafety | 26 | Force ops, casting, type annotations, conversions, duplication |
| Redundancy | 28 | Unnecessary code, redundant modifiers, implicit/explicit |
| ControlFlow | 25 | Switch, conditions, returns, closures, pattern matching |
| Modernization | 25 | Legacy APIs, concurrency, async/await, Swift 6.2, observation |
| DeadCode | 22 | Unused symbols, imports, params, overrides, duplication |
| Whitespace | 28 | Spacing, indentation, braces, punctuation |
| Multiline | 25 | Multi-line formatting, alignment, brackets |
| Ordering | 20 | Declaration order, sorting, file organization |
| Testing | 22 | XCTest, Quick, Nimble, test lifecycle |
| Frameworks | 22 | UIKit/IB, SwiftUI, delegates, notifications, localization |
| Documentation | 15 | Doc comments, marks, TODOs, lint commands |
| Metrics | 12 | Lengths, complexity, nesting |
| Performance | 20 | Collection optimizations, perf anti-patterns |

## Steps

- [ ] Create new folder structure
- [ ] Map each rule + its *Examples.swift companion to the target folder
- [ ] Move files (git handles renames)
- [ ] Delete empty old folders (Idiomatic/, Lint/, Style/, Concurrency/, Observation/, Suggest/)
- [ ] Verify AllRules.swift needs no changes (no path dependencies)
- [ ] Build and test

## Notes
- Single target = no import changes needed
- AllRules.swift references types, not paths — should work without changes
- Each rule's *Examples.swift file moves with it
