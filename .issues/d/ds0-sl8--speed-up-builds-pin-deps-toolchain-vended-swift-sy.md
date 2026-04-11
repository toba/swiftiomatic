---
# ds0-sl8
title: 'Speed up builds: pin deps + toolchain-vended swift-syntax'
status: completed
type: task
priority: normal
created_at: 2026-04-11T22:03:12Z
updated_at: 2026-04-11T22:15:46Z
sync:
    github:
        issue_number: "197"
        synced_at: "2026-04-11T22:52:31Z"
---

Builds are slow every time because swift-syntax and swift-format track `branch: "main"`.

## Phase 1: Pin to exact version tags
- [x] Pin swift-syntax to `exact: "603.0.0-prerelease-2026-02-23"`
- [x] Pin swift-format to `exact: "603.0.0-prerelease-2026-02-09"`
- [x] Resolve + clean build, verify second build is fast

## Phase 2: Toolchain-vended swift-syntax
- [x] Replace SwiftLexicalLookup usage in EmptyCountRule with manual scope walk
- [x] Replace SwiftLexicalLookup usage in RedundantEscapingRule with manual scope walk
- [ ] Switch to `apple.swift-syntax` in Package.swift
- [x] Remove SwiftLexicalLookup from dependency list
- [ ] Verify full test suite passes


## Notes

- Toolchain-vended swift-syntax (`apple.swift-syntax` registry) requires a package registry, which isn't set up. The prebuilt mechanism (`--enable-experimental-prebuilts`) only works for macro targets, not regular libraries. Pinning to exact versions is the practical solution.
- RuleExampleTests failure (1 of 3) is pre-existing — same failure on unmodified code.
