---
# cu8-swk
title: 'Phase 2: Migrate organization & ordering rules to AST'
status: completed
type: task
priority: normal
created_at: 2026-03-01T00:59:45Z
updated_at: 2026-03-01T05:45:53Z
parent: aku-gm2
blocked_by:
    - yr7-zbm
sync:
    github:
        issue_number: "109"
        synced_at: "2026-03-01T06:13:21Z"
---

Migrate rules that sort, reorder, or organize declarations. These rules parse structure from tokens that swift-syntax provides as typed nodes.

## Sorting rules (6)

- [x] sortImports — SortImportsRule (AST correctable)
- [x] sortedImports — existing SortedImportsRule (AST)
- [x] sortDeclarations — SortDeclarationsRule (AST)
- [x] sortSwitchCases — SortSwitchCasesRule (AST)
- [x] sortedSwitchCases — merged into SortSwitchCasesRule
- [x] sortTypealiases — SortTypealiasesRule (AST)

## Organization & marking rules (4)

- [x] organizeDeclarations — OrganizeDeclarationsRule (AST)
- [x] modifierOrder — existing ModifierOrderRule (AST)
- [x] markTypes — MarkTypesRule (AST)
- [x] extensionAccessControl — ExtensionAccessControlRule (AST)

## Comment & documentation rules (5)

- [x] docComments — DocCommentsRule (AST)
- [x] docCommentsBeforeModifiers — DocCommentsBeforeModifiersRule (AST)
- [x] blockComments — BlockCommentsRule (AST)
- [x] fileHeader — existing FileHeaderRule (AST)
- [x] headerFileName — HeaderFileNameRule (AST)

## Declaration formatting rules (7)

- [x] todos — existing TodoRule (AST)
- [x] acronyms — AcronymsRule (AST)
- [x] enumNamespaces — EnumNamespacesRule (AST)
- [x] emptyBraces — EmptyBracesRule (AST correctable)
- [x] emptyExtensions — EmptyExtensionsRule (AST)
- [x] specifiers — merged with existing ModifierOrderRule
- [x] modifiersOnSameLine — ModifiersOnSameLineRule (AST correctable)

## Other structural rules (4)

- [x] numberFormatting — NumberFormattingRule (AST)
- [x] noExplicitOwnership — NoExplicitOwnershipRule (AST correctable)
- [x] singlePropertyPerLine — SinglePropertyPerLineRule (AST)
- [x] environmentEntry — EnvironmentEntryRule (AST)

## Notes

- sortImports/sortedImports and sortSwitchCases/sortedSwitchCases appear to be duplicates — consolidate during migration
- organizeDeclarations is the most complex rule here; swift-syntax makes member categorization much simpler
- Comment rules work with trivia in swift-syntax, which is a natural fit


## Summary of Changes

All 26 organization & ordering rules migrated to AST. 20 new implementations, 5 pre-existing, 1 deprecated alias merged. All tests pass.
