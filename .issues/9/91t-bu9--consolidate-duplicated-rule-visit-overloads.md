---
# 91t-bu9
title: Consolidate duplicated rule visit overloads
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:40Z
updated_at: 2026-04-25T21:31:32Z
parent: 0ra-lks
sync:
    github:
        issue_number: "424"
        synced_at: "2026-04-25T22:35:10Z"
---

Three rules have near-identical visit overloads. Two of the three are bound by `SyntaxRewriter`'s typed-dispatch contract (one override per concrete syntax type) — the structural duplication can't be removed without changing semantics. The third (`SortDeclarations`) was the genuine code-duplication and is now consolidated.

## Findings

- [ ] `TripleSlashDocComments.swift` — left as 11 typed one-liners. Each `visit(_ node: DeclTypeSyntax)` already delegates to the existing single-source helper `convertDocBlockCommentToDocLineComment`. To collapse further would require `visitAny`, which is called for *every* node (most aren't decls) and disrupts standard child dispatch. The current shape keeps one-line dispatchers calling a shared 30-line helper — the duplication is a Swift dispatch artefact, not logic duplication.
- [ ] `SimplifyGenericConstraints.swift` — left as 5 typed overrides. Each already delegates to the shared 70-line `simplifyConstraints<D>(_:genericParamsKeyPath:whereClauseKeyPath:)` generic helper. The override boilerplate (`super.visit(node).cast(D.self)` + `DeclSyntax(...)` wrap) is required by `SyntaxRewriter`'s typed return contract — `super.visit` cannot be called from a generic helper because it dispatches on the static type. The three lines per override are dispatch boilerplate, not duplicated logic.
- [x] `SortDeclarations.swift` — extracted `sortMarkedRegions<Element: SyntaxProtocol>(items:name:)` covering region detection, sort, name-comparison, diagnostic anchoring, and positional-trivia preservation. Both visit methods (`MemberBlockItemListSyntax`, `CodeBlockItemListSyntax`) drop from ~50 lines each to 4 lines each, with the helper consuming ~50 lines once. Net ~50 lines removed.

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 6/6 (`SortDeclarations`).
- [x] Full build of all rules (incl. `TripleSlashDocComments`, `SimplifyGenericConstraints`) clean.

## Summary of Changes

**`SortDeclarations.swift`** — extracted shared sort logic into `sortMarkedRegions<Element: SyntaxProtocol>(items:name:) -> [Element]?`. The helper:

- Walks items once to discover `swiftiomatic:sort:begin`/`end` regions.
- For each region, sorts its slice (stable on offset for equal names), checks whether sort changed the order, emits a finding on the first item, and rebuilds preserving positional leading trivia (keeps the begin marker at position 0 of the sorted region).
- Returns `nil` when no regions exist or no region needed re-sorting; otherwise returns the new items array.

The two visit methods now collapse to:

```swift
override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
    let visited = super.visit(node)
    let items = Array(visited)
    let sorted = sortMarkedRegions(items: items) { declarationName($0.decl) }
    return sorted.map(MemberBlockItemListSyntax.init) ?? visited
}
```

(and analogously for `CodeBlockItemListSyntax`). The only call-site differences (name extractor, list reconstructor) are passed in.

**Other two findings deferred** — see Findings section. The duplication is `SyntaxRewriter` typed-dispatch boilerplate, not logic duplication; the actual transform is already extracted to a single helper in each rule.
