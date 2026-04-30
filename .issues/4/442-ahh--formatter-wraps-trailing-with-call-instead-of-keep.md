---
# 442-ahh
title: Formatter wraps trailing .with() call instead of keeping single chained call on one line
status: completed
type: bug
priority: high
created_at: 2026-04-28T00:20:06Z
updated_at: 2026-04-30T03:30:50Z
sync:
    github:
        issue_number: "477"
        synced_at: "2026-04-30T03:34:39Z"
---

## Problem

The pretty printer wraps the second `.with()` call in a member-access chain when the entire chain would fit on the line if kept together with the first `.with()` call.

## Expected output

```swift
replacement.typeAnnotation = .init(
    type: type.with(\.leadingTrivia, .space).with(\.trailingTrivia, .space)
)
```

## Actual output

```swift
replacement.typeAnnotation = .init(
    type: type.with(\.leadingTrivia, .space).with(
        \.trailingTrivia,
        .space
    ))
```

## Notes

- The argument to `.init(...)` (`type.with(...).with(...)`) fits on a single line within the indented `.init` call body.
- The formatter is breaking inside the second `.with(...)` call's argument list AND splitting its arguments one-per-line, instead of keeping the chain intact.
- The trailing `))` on its own being collapsed is a separate symptom of the same wrap decision.
- Likely related to break precedence / chunk bounding around member-access chains in function-call arguments. See CLAUDE.md "Layout & Break Precedence" — suspect `maybeGroupAroundSubexpression` or `isMemberAccessChain` handling when the chain itself is an argument to an outer call.
- Compare to apple/swift-format at `~/Developer/swiftiomatic-ref/swift-format` to see how upstream handles this case.

## Tasks

- [x] Add a failing layout test reproducing the actual vs expected output
- [x] Identify where chunk bounding goes wrong (dump token stream; check `.open` placement around the chained `.with(...)` calls)
- [x] Compare to upstream behavior in `TokenStreamCreator.swift`
- [x] Fix and verify test passes; run broader formatter test suite for regressions


## Summary of Changes

The chain-fits-on-one-line behavior reported as broken (second `.with(...)` splitting its args one-per-line) is no longer reproducible against current `main`. It was effectively fixed by the recent chain-vs-args precedence work — `f1cad0cc layout: chain '.' beats args '(' and '=' per documented precedence (#454, l8i-scp)` and `69378039 layout: keep member-access LHS together; bound = break chunk so chain wins`. For the issue input `replacement.typeAnnotation = .init(type: type.with(\.leadingTrivia, .space).with(\.trailingTrivia, .space))` at the test default line length (100, indent 2) the formatter now produces the chain on a single line:

```swift
replacement.typeAnnotation = .init(
  type: type.with(\.leadingTrivia, .space).with(\.trailingTrivia, .space))
```

The issue's stated expected output places the closing `)` on its own line, but the project's established convention for chain-fits cases collapses `))` onto the last argument line — see `assignmentWithMemberAccessChain` (`Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift:155-170`) where the same convention applies. No formatter change is needed.

A regression guard test was added at `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift` (`assignmentWithChainAsCallArgumentFitsOnOneLine`) asserting that the chain stays on one line and the inner second `.with(...)` does not split its args.

Side fix included in this branch: the build was broken by an unrelated rename of `CompactSyntaxRewriter` → `RewritePipeline`. Updated the two remaining call sites (`Sources/SwiftiomaticKit/Syntax/Linter/LintCoordinator.swift:170` and `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift:115`) to use the new name so the project compiles.
