---
# cu8-swk
title: 'Phase 2: Migrate organization & ordering rules to AST'
status: ready
type: task
priority: normal
created_at: 2026-03-01T00:59:45Z
updated_at: 2026-03-01T00:59:45Z
parent: aku-gm2
blocked_by:
    - yr7-zbm
sync:
    github:
        issue_number: "109"
        synced_at: "2026-03-01T01:41:13Z"
---

Migrate rules that sort, reorder, or organize declarations. These rules parse structure from tokens that swift-syntax provides as typed nodes.

## Sorting rules (6)

- [ ] sortImports
- [ ] sortedImports (merge with sortImports if redundant)
- [ ] sortDeclarations
- [ ] sortSwitchCases
- [ ] sortedSwitchCases (merge with sortSwitchCases if redundant)
- [ ] sortTypealiases

## Organization & marking rules (4)

- [ ] organizeDeclarations
- [ ] modifierOrder
- [ ] markTypes
- [ ] extensionAccessControl

## Comment & documentation rules (5)

- [ ] docComments
- [ ] docCommentsBeforeModifiers
- [ ] blockComments
- [ ] fileHeader
- [ ] headerFileName

## Declaration formatting rules (7)

- [ ] todos
- [ ] acronyms
- [ ] enumNamespaces
- [ ] emptyBraces
- [ ] emptyExtensions
- [ ] specifiers (merge with modifierOrder if overlap)
- [ ] modifiersOnSameLine

## Other structural rules (4)

- [ ] numberFormatting
- [ ] noExplicitOwnership
- [ ] singlePropertyPerLine
- [ ] environmentEntry

## Notes

- sortImports/sortedImports and sortSwitchCases/sortedSwitchCases appear to be duplicates — consolidate during migration
- organizeDeclarations is the most complex rule here; swift-syntax makes member categorization much simpler
- Comment rules work with trivia in swift-syntax, which is a natural fit
