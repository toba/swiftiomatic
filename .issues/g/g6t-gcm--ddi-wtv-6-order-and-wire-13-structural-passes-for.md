---
# g6t-gcm
title: 'ddi-wtv-6: order and wire 13 structural passes for compact'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:43:08Z
updated_at: 2026-04-28T02:43:08Z
parent: ddi-wtv
blocked_by:
    - vz0-31g
    - 5r3-peg
    - r0w-l4r
sync:
    github:
        issue_number: "488"
        synced_at: "2026-04-28T02:56:06Z"
---

After the combined node-local rewriter is complete, the compact path runs a fixed list of structural passes in deterministic order.

## Order (per 2kl-d04 sec 2)

1. SortImports
2. BlankLinesAfterImports
3. FileScopedDeclarationPrivacy
4. ExtensionAccessLevel
5. PreferFinalClasses
6. ConvertRegularCommentToDocC
7. BlankLinesBetweenScopes
8. ConsistentSwitchCaseSpacing
9. SortDeclarations
10. SortSwitchCases
11. SortTypeAliases
12. FileHeader
13. ReflowComments

## Tasks

- [ ] In `RewriteCoordinator.runCompactPipeline(_:)`, after `CompactStageOneRewriter.rewrite(node)`, run each structural pass in order
- [ ] Each structural rule keeps its existing `RewriteSyntaxRule` shell (these legitimately need a settled tree per pass)
- [ ] Add a test asserting the ordering produces the same output as the legacy pipeline on the golden corpus

## Done when

Compact path runs combined rewriter + 13 ordered passes; output matches legacy on the golden corpus (or only differs in ways documented in 2kl-d04).
