---
# 6uk-rqg
title: 'Phase 3: Migrate simple formatting rules to AST trivia'
status: completed
type: task
priority: normal
created_at: 2026-03-01T00:59:59Z
updated_at: 2026-03-01T06:01:22Z
parent: aku-gm2
blocked_by:
    - cu8-swk
sync:
    github:
        issue_number: "84"
        synced_at: "2026-03-01T06:13:20Z"
---

Migrate whitespace, spacing, and blank line rules to swift-syntax trivia manipulation. These rules operate on horizontal/vertical whitespace — they map to leading/trailing trivia on TokenSyntax nodes.

## Spacing rules (13)

- [x] consecutiveSpaces — ConsecutiveSpacesRule (new AST)
- [x] spaceAroundOperators — OperatorUsageWhitespaceRule (existing AST)
- [x] spaceAroundBraces — OpeningBraceRule + ClosureSpacingRule (existing AST)
- [x] spaceAroundBrackets — SpaceAroundBracketsRule (new AST)
- [x] spaceAroundGenerics — SpaceAroundGenericsRule (new AST)
- [x] spaceAroundParens — SpaceAroundParensRule (new AST)
- [x] spaceAroundComments — SpaceAroundCommentsRule (new AST)
- [x] spaceInsideBraces — ClosureSpacingRule (existing AST)
- [x] spaceInsideBrackets — SpaceInsideBracketsRule (new AST)
- [x] spaceInsideComments — CommentSpacingRule (existing AST)
- [x] spaceInsideGenerics — SpaceInsideGenericsRule (new AST)
- [x] spaceInsideParens — SpaceInsideParensRule (new AST)
- [x] leadingDelimiters — LeadingDelimitersRule (new AST)

## Blank line rules (11)

- [x] consecutiveBlankLines — VerticalWhitespaceRule (existing AST)
- [x] blankLineAfterImports — BlankLineAfterImportsRule (new AST)
- [x] blankLineAfterSwitchCase — VerticalWhitespaceBetweenCasesRule (existing AST)
- [x] blankLinesAfterGuardStatements — BlankLinesAfterGuardStatementsRule (new AST)
- [x] blankLinesAroundMark — BlankLinesAroundMarkRule (new AST)
- [x] blankLinesAtStartOfScope — VerticalWhitespaceOpeningBracesRule (existing AST)
- [x] blankLinesAtEndOfScope — VerticalWhitespaceClosingBracesRule (existing AST)
- [x] blankLinesBetweenChainedFunctions — BlankLinesBetweenChainedFunctionsRule (new AST)
- [x] blankLinesBetweenImports — BlankLinesBetweenImportsRule (new AST)
- [x] blankLinesBetweenScopes — BlankLinesBetweenScopesRule (new AST)
- [x] consistentSwitchCaseSpacing — VerticalWhitespaceBetweenCasesRule (existing AST)

## Line ending & delimiter rules (7)

- [x] trailingSpace — TrailingWhitespaceRule (existing AST)
- [x] trailingCommas — TrailingCommaRule (existing AST)
- [x] linebreakAtEndOfFile — TrailingNewlineRule (existing AST)
- [x] linebreaks — LinebreaksRule (new AST)
- [x] semicolons — TrailingSemicolonRule (existing AST)
- [x] elseOnSameLine — StatementPositionRule (existing AST)
- [x] braces — OpeningBraceRule (existing AST)

## Notes

- swift-syntax trivia types: spaces, tabs, newlines, carriageReturns, lineComment, blockComment, docLineComment, docBlockComment
- Trivia is attached to tokens as leading/trailing — rewriting means building new Trivia arrays
- Start with the simplest (trailingSpace, consecutiveSpaces, semicolons) to prove out the trivia manipulation pattern
- braces (K&R vs Allman) is moderately complex — needs to move trivia between tokens


## Summary of Changes

All 31 formatting rules migrated to AST. 16 new AST rules created, 15 covered by existing AST rules.

New rules: ConsecutiveSpacesRule, SpaceAroundBracketsRule, SpaceAroundGenericsRule, SpaceAroundParensRule, SpaceAroundCommentsRule, SpaceInsideBracketsRule, SpaceInsideGenericsRule, SpaceInsideParensRule, LeadingDelimitersRule, BlankLineAfterImportsRule, BlankLinesBetweenImportsRule, BlankLinesAroundMarkRule, BlankLinesBetweenScopesRule, BlankLinesAfterGuardStatementsRule, BlankLinesBetweenChainedFunctionsRule, LinebreaksRule

Existing AST equivalents: OperatorUsageWhitespaceRule, OpeningBraceRule, ClosureSpacingRule, CommentSpacingRule, VerticalWhitespaceRule, VerticalWhitespaceBetweenCasesRule, VerticalWhitespaceOpeningBracesRule, VerticalWhitespaceClosingBracesRule, TrailingWhitespaceRule, TrailingCommaRule, TrailingNewlineRule, TrailingSemicolonRule, StatementPositionRule
