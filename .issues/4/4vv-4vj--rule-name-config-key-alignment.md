---
# 4vv-4vj
title: Rule name & config key alignment
status: completed
type: task
priority: normal
created_at: 2026-04-26T00:23:14Z
updated_at: 2026-04-26T00:43:23Z
---

Align rule type names with config keys per /Users/jason/.claude/plans/i-want-a-careful-tingly-rabin.md. Batches:

- [x] naming group (5 rules)
- [x] hoist group (4 rules)
- [x] comments group (7 rules)
- [x] blankLines (2 rules)
- [x] lineBreaks (2 rules)
- [x] wrap (WrapTernary already in lineBreaks; no changes)
- [x] unsafety group rename + TypedCatchError move (was already done)
- [x] misc: EnumNamespaces, EmptyCollectionLiteral, NoSemicolons
- [x] regenerate schema + tests pass (2940/2940)


## Summary of Changes

Aligned rule type names with config keys per plan.

Type renames:
- CapitalizeAcronyms → UppercaseAcronyms
- CapitalizedTypeNames → CapitalizeTypeNames
- LowerCamelCase → CamelCaseIdentifiers
- FullyIndirectEnum → IndirectEnum
- PatternLetPlacement → CaseLet
- DocComments → ConvertRegularCommentToDocC
- DocCommentsBeforeModifiers → DocCommentsPrecedeModifiers
- DocCommentSummary → RequireDocCommentSummary
- ValidateDocumentationComments → RequireParameterDocumentation
- BlankLinesBeforeControlFlow → BlankLinesBeforeControlFlowBlocks
- LinebreakAtEndOfFile → EnsureLineBreakAtEOF
- RespectsExistingLineBreaks → RespectExistingLineBreaks
- EnumNamespaces → StaticStructShouldBeEnum

Key overrides removed (key now matches camelCased type name):
- ASCIIIdentifiers, NoBlockComments, TripleSlashDocComments, FormatSpecialComments, BlankLinesAroundMark (override changed to `aroundMark`), EmptyCollectionLiteral, NoSemicolons, plus all the renamed-type overrides above.

Key overrides kept for in-group prefix removal:
- HoistAwait → `hoist.await`, HoistTry → `hoist.try`, plus existing Sort* / Wrap* / BlankLines* prefix-strips.

schema.json regenerated. swiftiomatic.json updated to match new keys.
