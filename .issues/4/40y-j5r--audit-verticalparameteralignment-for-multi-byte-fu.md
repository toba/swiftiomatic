---
# 40y-j5r
title: 'Audit: VerticalParameterAlignment for multi-byte function names'
status: completed
type: bug
priority: normal
created_at: 2026-06-08T19:41:55Z
updated_at: 2026-06-08T19:52:42Z
sync:
    github:
        issue_number: "723"
        synced_at: "2026-06-08T19:59:33Z"
---

Upstream SwiftLint fix (realm/SwiftLint #6747 0f2b4f68, 2026-06-06) fixes vertical_parameter_alignment for multi-byte function names.

Reference: ~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Style/VerticalParameterAlignmentRule.swift

If Swiftiomatic has a vertical-parameter-alignment rule, audit column/offset math for byte-vs-character handling with multi-byte identifiers.



## Summary of Changes

Rewrote `NestedCallLayout.columnOffset(of:)` to count grapheme clusters consistently for both tokens and trivia. The previous implementation mixed `String.count` (graphemes) on token text with `TriviaPiece.sourceLength.utf8Length` (UTF-8 bytes) on trivia, which over-counted columns when preceding tokens or trivia contained multi-byte characters (e.g. comments or identifiers with non-ASCII letters) and could trigger spurious wrap decisions.

The new implementation builds the line fragment preceding the node as a single string (walking backwards through tokens and stopping at the most recent newline), then returns its `.count`. This matches the unit used to measure the call body (`text.count` graphemes) when comparing against `LineLength`.

- Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift: rewrote `columnOffset(of:)` to count graphemes uniformly.

Verified via filtered `NestedCallLayoutTests` run (26 passed).
