---
# brm-7t3
title: Color(red:green:blue:) splits across lines when chain fits with inline args
status: completed
type: bug
priority: normal
created_at: 2026-06-02T00:47:22Z
updated_at: 2026-06-02T01:13:16Z
sync:
    github:
        issue_number: "716"
        synced_at: "2026-06-02T01:51:58Z"
---

## Repro

Two near-identical previews format differently. The first keeps the `Color(...)` call inline; the second explodes it across 5 lines even though the inline form fits.

### Input / current output

```swift
#Preview("Empty", traits: .fixedLayout(width: 900, height: 500)) {
    ContentView()
        .withTint(Color(red: 0.45, green: 0.6, blue: 0.45))
        .withNoContent()
}

#Preview("Loaded") {
    ContentView()
        .frame(width: 800, height: 500)
        .withTint(Color(
            red: 0.45,
            green: 0.6,
            blue: 0.45
        ))
        .withPreviewFile()
}
```

### Expected

The second `.withTint(Color(red: 0.45, green: 0.6, blue: 0.45))` should stay on one line, matching the first preview. The full chain line

```
        .withTint(Color(red: 0.45, green: 0.6, blue: 0.45))
```

is well under the column limit, so there is no reason to break the `Color` argument list.

## Notes

- Both previews use the same call shape (`Color(red:green:blue:)` inside `.withTint(...)` inside a `.`-chain).
- The first preview's chain has only two members (`.withTint`, `.withNoContent`); the second has three (`.frame`, `.withTint`, `.withPreviewFile`). The presence of an extra `.frame(...)` member earlier in the chain appears to flip the decision to break the inner `Color(...)` call rather than just breaking between chain members.
- Likely related to chain-break precedence / `maybeGroupAroundSubexpression` over-extending a break's chunk across the nested call arguments. See CLAUDE.md §"Layout & Break Precedence".

## Tasks

- [x] Add a failing pretty-print test reproducing the second preview shape
- [x] Identify which break/group is causing the inner `Color(...)` to split when the chain has 3+ members
- [x] Fix so the inner call stays inline when it fits, and chain members break instead
- [x] Confirm no regressions in chain/Color-related tests

## Summary of Changes

Root cause: when a function call is nested inside another call as its sole argument (e.g. `.withTint(Color(...))`), the inner call's argument-list parens and inter-argument commas weren't marked `ignoresDiscretionary`, so user-supplied newlines stuck even when the entire line fit.

Fix:
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift`: new `isSoleCallArgumentOfOuterCall(_:arguments:)` helper that walks `leftDelimiter -> FunctionCallExpr -> LabeledExpr -> LabeledExprList(count==1) -> outer FunctionCallExpr` and excludes calls whose arguments contain closures.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift`: extended the `ignoreDiscretionary` condition in `arrangeFunctionCallArgumentList` to OR in the new helper; threaded the flag into `arrangeAsFunctionCallArgument` via new `ignoreDiscretionaryCommaBreaks` parameter so the post-comma `.break(.same)` uses `.elective(ignoresDiscretionary: true)` when set.
- Test: `Tests/SwiftiomaticTests/Layout/MemberAccessExprTests.swift` adds `nestedMultiArgCallCollapsesWhenFits` covering the `Color(red:green:blue:)` repro; updated `baselessMemberAccess` expected output to reflect the new collapse-when-fits behavior.

Verified: 3414/3414 tests pass; real-world fix confirmed on `thesis/App/Sources/Views/ContentView.swift` (Color call now collapses inline in the 'Loaded' preview).
