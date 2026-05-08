---
# hfh-zsn
title: 'requireSuiteAccessControl: diagnostic location reports leading trivia start, producing confusing line/col'
status: completed
type: bug
priority: high
created_at: 2026-05-08T21:29:12Z
updated_at: 2026-05-08T21:40:51Z
sync:
    github:
        issue_number: "670"
        synced_at: "2026-05-08T21:42:02Z"
---

## Summary

`RequireSuiteAccessControl` emits findings via `Self.diagnose(.makePrivate, on: decl[keyPath: keyword], context: context)` where `keyword` is `\.funcKeyword` / `\.bindingSpecifier` / `\.initKeyword`. Token positions in SwiftSyntax include **leading trivia**, so the reported source location is the byte immediately after the previous sibling — which usually lands on the wrong line entirely (an `import` statement, a doc comment, a previous test's trailing `"""`, or a box-drawing glyph). Column counts are also UTF-8 byte offsets, so multi-byte characters (`│`, em dashes) inflate them past EOL.

## Repro

In a Thesis test suite file like `Core/Tests/Storage/CustomFunctionTests.swift`:

\`\`\`swift
@testable import Core
import GRDB
import Testing
import Foundation

struct CustomFunctionTests {
    @SQLFunction func customDate() -> Date {
        Date(timeIntervalSinceReferenceDate: 0)
    }

    @Test func basics() throws { … }
}
\`\`\`

`sm lint .` reports:

\`\`\`
Core/Tests/Storage/CustomFunctionTests.swift:3:15: warning: [requireSuiteAccessControl] make test helper 'private'
\`\`\`

The actual offending declaration is `@SQLFunction func customDate()` on **line 7**, not the `import Testing` on line 3. Column 15 lands at the end of `import Testing`.

Other live examples from `thesis@develop`:

| Reported | Actual decl |
|---|---|
| `Core/Tests/Storage/DatabaseFunctionTests.swift:26:28` | `@SQLFunction func dateTime(...)` on line 34 (col 28 lands on a `│` glyph in line 26's `┌──────┐ │ true │` snapshot literal) |
| `Core/Tests/Snapshots/AssertSnapshotSwiftTests.swift:19:11` and `:20:20` | `struct AssertSnapshotTests` / its members on lines 23+; reported locations land on `#if canImport(WebKit)` / `@preconcurrency import WebKit` |
| `Core/Tests/Dependency/DependencyUUIDTests.swift:4:23` | `@Dependency(\.uuid) var uuid` on line 7; reported location is inside `@testable import TestSupport` |
| `Integrations/Zotero/Tests/ZoteroMockAPITests.swift:8:19` | `let transport = MockHTTPTransport()` on line 16; reported location is mid-doc-comment |

## Expected

Diagnostic should point at a token a human can map to the offending declaration without counting bytes through unrelated code. Two reasonable options:

1. Emit on \`decl.name\` (the identifier token) — always lands on the declaration itself.
2. Emit on the first non-trivia byte of \`decl[keyPath: keyword]\` (i.e. \`positionAfterSkippingLeadingTrivia\` instead of \`position\`).

Option 2 is the minimal change.

## Suggested fix

In \`RequireSuiteAccessControl.swift\` (and audit other rules using the same pattern), wrap the diagnose targets:

\`\`\`swift
// before
Self.diagnose(.makePrivate, on: decl[keyPath: keyword], context: context)

// after — pin to the keyword's own start, not its trivia
let token = decl[keyPath: keyword]
let pinned = token.with(\.leadingTrivia, [])  // or use positionAfterSkippingLeadingTrivia at the diagnose site
Self.diagnose(.makePrivate, on: pinned, context: context)
\`\`\`

Or, cleaner, change the diagnose helper to use \`node.positionAfterSkippingLeadingTrivia\` when computing line/column.

## Impact

Low-severity (cosmetic, doesn't affect rewrites — \`rewrite: false\` is the default and the project disables rewrite) but it makes \`sm lint\` output for this rule essentially un-auditable: 105 findings in thesis@develop and not one of the reported line/col pairs corresponds to the real decl. Originally surfaced while triaging \`thesis ws3-op1\`; user was rightly skeptical the rule was correct because the locations made no sense.



## Summary of Changes

- `RequireSuiteAccessControl.transform(...)` now threads the `original` parameter through `rewriteMembers` → `rewriteFunction` / `rewriteProperty` → `removePublicModifier` / `removeExplicitACL` / `ensurePrivate`. All `Self.diagnose(...)` calls anchor on the corresponding token from `original` rather than the (potentially detached) rewritten `node`.
- Root cause: when a sibling rule rewrote a child of the struct/class, `super.visit` rebuilt the subtree; `concrete` arrived detached, so `funcKeyword.startLocation(converter:)` mapped tiny in-subtree offsets onto the original source — landing inside `import` lines or even mid-doc-comment. Single-rule unit tests didn't expose this because nothing rebuilt the subtree.
- Added `diagnosticLocationSurvivesDetachment` test in `RequireSuiteAccessControlTests` that calls `transform` directly with a `detached` struct against the still-attached `original`, and asserts the finding lands on `func helper()`'s actual line/col.
- Full suite: 3288 passed.
