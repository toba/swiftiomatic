---
# 6uk-rqg
title: 'Phase 3: Migrate simple formatting rules to AST trivia'
status: ready
type: task
created_at: 2026-03-01T00:59:59Z
updated_at: 2026-03-01T00:59:59Z
parent: aku-gm2
blocked_by:
    - cu8-swk
---

Migrate whitespace, spacing, and blank line rules to swift-syntax trivia manipulation. These rules operate on horizontal/vertical whitespace — they map to leading/trailing trivia on TokenSyntax nodes.

## Spacing rules (13)

- [ ] consecutiveSpaces
- [ ] spaceAroundOperators
- [ ] spaceAroundBraces
- [ ] spaceAroundBrackets
- [ ] spaceAroundGenerics
- [ ] spaceAroundParens
- [ ] spaceAroundComments
- [ ] spaceInsideBraces
- [ ] spaceInsideBrackets
- [ ] spaceInsideComments
- [ ] spaceInsideGenerics
- [ ] spaceInsideParens
- [ ] leadingDelimiters

## Blank line rules (11)

- [ ] consecutiveBlankLines
- [ ] blankLineAfterImports
- [ ] blankLineAfterSwitchCase
- [ ] blankLinesAfterGuardStatements
- [ ] blankLinesAroundMark
- [ ] blankLinesAtStartOfScope
- [ ] blankLinesAtEndOfScope
- [ ] blankLinesBetweenChainedFunctions
- [ ] blankLinesBetweenImports
- [ ] blankLinesBetweenScopes
- [ ] consistentSwitchCaseSpacing

## Line ending & delimiter rules (7)

- [ ] trailingSpace
- [ ] trailingCommas
- [ ] linebreakAtEndOfFile
- [ ] linebreaks
- [ ] semicolons
- [ ] elseOnSameLine
- [ ] braces

## Notes

- swift-syntax trivia types: spaces, tabs, newlines, carriageReturns, lineComment, blockComment, docLineComment, docBlockComment
- Trivia is attached to tokens as leading/trailing — rewriting means building new Trivia arrays
- Start with the simplest (trailingSpace, consecutiveSpaces, semicolons) to prove out the trivia manipulation pattern
- braces (K&R vs Allman) is moderately complex — needs to move trivia between tokens
