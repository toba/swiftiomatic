---
# hqp-ybw
title: Port SwiftLint UnownedVariableCaptureRule (unowned capture linting)
status: completed
type: feature
priority: normal
created_at: 2026-08-01T03:08:57Z
updated_at: 2026-08-01T03:23:55Z
sync:
    github:
        issue_number: "759"
        synced_at: "2026-08-01T03:46:13Z"
---

Port SwiftLint's `unowned_variable_capture` rule to Swiftiomatic as a LintSyntaxRule.

## Background
Surfaced by /cite review of realm/SwiftLint. Commit 50d40a9 ("Ignore `unowned(unsafe)` captures optionally", #6824, 2026-07-31) reworked the rule. Swiftiomatic has no equivalent today (closest memory rules: UseWeakSelfInClosures, RequireWeakDelegates, NoMutableInCaptureList — none flag `unowned`).

## What the rule does
Flags `unowned` captures in closure capture lists, pushing toward `weak`. Rationale: `unowned` is a non-owning reference; if the referent deallocates before the closure runs, access is a crash/UB, whereas `weak` degrades to nil.

## The three flavors (must handle)
- `unowned` == `unowned(safe)`: traps deterministically after dealloc.
- `unowned(safe)`: side-table bookkeeping, clean trap.
- `unowned(unsafe)`: raw pointer, no trap, genuine UB — an intentional hot-path escape hatch.

## Design decisions to carry over from SwiftLint
- Visit `ClosureCaptureSpecifierSyntax` (NOT raw `.unowned` token). The specifier node carries both `node.specifier` (keyword) and `node.detail` (safe/unsafe). The old token-matcher blind spot missed both parenthesized forms — this rewrite fixes coverage.
- Flag bare `unowned` AND `unowned(safe)` always.
- Add config `allowExplicitUnsafeUnowned` (nested config struct on Configuration). When true, `unowned(unsafe)` is treated as an acknowledged escape hatch and not flagged. Default false (repo philosophy: false positives over misses).

## Reference visitor (SwiftLint, post-change)
    override func visitPost(_ node: ClosureCaptureSpecifierSyntax) {
        guard case .keyword(.unowned) = node.specifier.tokenKind else { return }
        let isUnsafe = node.detail?.tokenKind == .keyword(.unsafe)
        if !isUnsafe || !configuration.allowExplicitUnsafeUnowned {
            violations.append(node.specifier.positionAfterSkippingLeadingTrivia)
        }
    }

## Todo
- [ ] Test first: reproduce triggering (`[unowned self]`, `[unowned(safe) self]`, `[unowned(unsafe) self]`) and non-triggering (`[weak self]`, and `[unowned(unsafe) self]` with flag on)
- [ ] Implement LintSyntaxRule visiting ClosureCaptureSpecifierSyntax
- [ ] Add allowExplicitUnsafeUnowned nested config struct
- [ ] Decide default severity (SwiftLint marks it opt-in)
- [ ] Full suite passes
