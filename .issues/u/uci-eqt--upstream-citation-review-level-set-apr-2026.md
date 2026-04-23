---
# uci-eqt
title: 'Upstream citation review: level-set (Apr 2026)'
status: completed
type: task
priority: normal
created_at: 2026-04-23T15:20:26Z
updated_at: 2026-04-23T15:34:24Z
sync:
    github:
        issue_number: "357"
        synced_at: "2026-04-23T16:14:37Z"
---

First thorough review of all cited upstream repos. Work through each relevant change, decide port/adapt/skip, and check off.

## swiftlang/swift-format (direct upstream)

- [x] **PORT** \`e276f58\` — Correctly format \`unsafe\` when preceding a \`for\` loop pattern (#1189). Touches \`TokenStreamCreator\`. Correctness fix we likely need.
- [x] SKIP \`467b866\` — already handled by registry-based auto-encoding — Add missing encoding for \`Configuration.multilineTrailingCommaBehavior\` (#1191). Check if our \`Configuration\` has the same gap.
- [x] **PORT** \`68efc74\` — Improve error messages on invalid configuration files (#1184). Touches \`Frontend.swift\`. Better UX for bad config.
- [x] SKIP \`8edc4d5\` — GHA dependabot grouping (CI-only, not applicable)

## nicklockwood/SwiftFormat (0.61.0 release)

### New rules to evaluate

- [x] **EVALUATE** \`54f63a3\` — \`redundantEmptyView\`. LATER — SwiftUI-specific, lower priority
- [x] **EVALUATE** \`d798a8a\` — \`wrapCaseBodies\`. SKIP — already have WrapCompoundCaseStatements

### Features to evaluate

- [x] **EVALUATE** \`3f4f61b\` — \`sortImports\` length,alpha. SKIP — SortImports already has full parity
- [x] **EVALUATE** \`357efe0\` — testSuiteAccessControl option. SKIP — our TestSuiteAccessControl already covers this

### Bug fix patterns to review

- [x] **REVIEW** \`f00ffbc\` — #if edge cases. NOT AFFECTED — our rules never modify #if conditions
- [x] **REVIEW** \`e913427\` — @MainActor paren removal. LOW RISK — NoTrailingClosureParens has theoretical gap but unlikely to trigger
- [x] **REVIEW** \`835f6f2\` — Infinite loop with trailing comments. NOT AFFECTED — clear loop termination in our rewriters
- [x] **REVIEW** \`727c044\` — Extension access on nested types. NOT AFFECTED — conservative guards in NoExtensionAccessLevel and RedundantAccessControl
- [x] **REVIEW** \`9d60158\` — nonisolated(nonsending) spacing. NOT AFFECTED — no spaceAroundParens-style rule
- [x] **REVIEW** \`b0b756d\` — @convention trailing commas. NOT AFFECTED — our rule is generic, doesn't special-case closure types
- [x] **REVIEW** \`4ace97e\` — Conditional imports with access modifiers. NOT AFFECTED — architecture doesn't apply access to imports
- [x] **REVIEW** \`05d684a\` — Raw string indentation. NOT AFFECTED — explicitly excluded from reflow processing
- [x] **REVIEW** \`e86b840\` — Test case name numbers. NOT AFFECTED — already guarded (isNumber check)
- [x] **REVIEW** \`66986ce\` — suite-name-format default. N/A — we don't have this feature
- [ ] SKIP — \`dce393f\`, \`9a00c08\`, \`ebcb440\`, \`78836b9\`, \`09fe3ee\`, \`93004fb\` — minor docs, ObjC string replacement, default changes, CI (low relevance)

## realm/SwiftLint

### New rules to evaluate

- [x] **EVALUATE** \`949cfe9\` — \`variable_shadowing\`. LATER — requires scope tracking, lower priority
- [x] **EVALUATE** \`f242859\` — \`redundant_final\` rule (#6597). **YES** — follow-up issue created
- [x] **EVALUATE** \`65f44a0\` — \`legacy_uigraphics_function\`. SKIP — iOS-specific, not relevant for macOS tool

### Bug fix patterns to review

- [x] **REVIEW** \`ceef663\` — DeclaredIdentifiersTrackingVisitor. NOT AFFECTED — no equivalent infrastructure
- [x] **REVIEW** \`9bc16b5\` — indentation_width multi-line conditions. NOT AFFECTED — only SwitchCaseIndentation exists, narrow scope
- [x] **REVIEW** \`ef026db\` — Self in static refs with shadowed nested types. LOW RISK — RedundantStaticSelf checks param/local shadowing but not nested type shadowing
- [ ] SKIP — 8 dependabot bumps (CI-only)

## swiftlang/swift-syntax

- [x] SKIP — 2 commits, both CI/dependabot. Nothing actionable.

## Summary of Changes

## Summary of Changes

**Ported:**
- `unsafe` keyword formatting in `for` loops (TokenStream+ControlFlow.swift) + 4 tests
- Config error messages with DecodingError path details (Frontend.swift)
- Fixed pre-existing `try self(data:)` bug in Configuration.swift

**Skipped (already covered):**
- multilineTrailingCommaBehavior encoding — registry auto-encodes
- sortImports length,alpha — SortImports has full parity
- testSuiteAccessControl option — TestSuiteAccessControl covers this
- wrapCaseBodies — WrapCompoundCaseStatements exists
- legacy_uigraphics_function — iOS-specific

**Deferred:**
- redundantEmptyView — LATER, SwiftUI-specific
- variable_shadowing — LATER, needs scope tracking

**Follow-up:**
- redundant_final rule — new issue created

**Bug patterns reviewed (14 items):** No issues found. Two LOW RISK items noted (NoTrailingClosureParens attribute gap, RedundantStaticSelf nested type shadowing).
