---
# 5nn-red
title: Vendor SwiftLint into Swiftiomatic
status: completed
type: feature
priority: normal
created_at: 2026-02-27T21:51:52Z
updated_at: 2026-02-27T23:33:03Z
sync:
    github:
        issue_number: "18"
        synced_at: "2026-03-01T01:01:31Z"
---

Evaluate incorporating SwiftLint https://github.com/realm/SwiftLint. If so, /cite it and update license and readme per /readme skill.



## Status

SwiftFormat was incorporated (jjv-3ri). Swiftiomatic's Analysis target already covers AST-based checks that overlap with SwiftLint. SwiftLint has heavy dependencies (swift-syntax, SourceKitten) that would duplicate what we already have. Recommend evaluating whether specific SwiftLint rules are needed beyond what Analysis + Formatting already provide.


## Summary of Changes

All work completed under duplicate epic 7ls-zus (phases 1–4 all done):
- Dependencies upgraded (swift-syntax 604, Yams 6, SourceKitten 0.37)
- SwiftLint 0.63.2 source vendored into Sources/Lint/ (Core, BuiltInRules, Framework, Macros, ExtraRules, DyldWarningWorkaround)
- Bridge layer + `lint` subcommand created (LintCommand.swift)
- License (LICENSES/SwiftLint-MIT.txt) and citation (.jig.yaml) added

Child tasks dl2-1pu, bpt-2qz, 797-849, r79-knq are stale duplicates of 7ls-zus's children — scrapping.
