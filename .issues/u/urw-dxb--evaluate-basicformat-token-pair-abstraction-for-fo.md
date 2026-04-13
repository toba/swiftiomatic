---
# urw-dxb
title: Evaluate BasicFormat token-pair abstraction for format rules
status: completed
type: task
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:49:59Z
parent: oad-n72
sync:
    github:
        issue_number: "246"
        synced_at: "2026-04-13T00:55:42Z"
---

swift-syntax's `BasicFormat` models formatting as decisions between adjacent tokens rather than visiting specific node types. This is a more declarative approach that could simplify format-scope rules.

## Reference

`SwiftBasicFormat/BasicFormat.swift` — `SyntaxRewriter` subclass with:
- `requiresNewline(between first: TokenSyntax?, and second: TokenSyntax?) -> Bool`
- `requiresWhitespace(between first: TokenSyntax?, and second: TokenSyntax?) -> Bool`
- `isMutable(_ token: TokenSyntax) -> Bool`
- Indentation stack tracking (user-defined vs inferred)
- Anchor points for indentation relationships

## Applicability

Would benefit rules like brace spacing, operator spacing, comma placement, and colon spacing. Not a wholesale replacement of the current visitor approach — more of a complementary pattern for whitespace/newline rules.

## Tasks

- [x] Prototype a token-pair formatting engine alongside existing format rules — evaluated, not needed
- [x] Identify which existing format rules could be expressed as token-pair decisions
- [x] Evaluate whether the abstraction reduces code and bugs vs. current approach
- [x] Decide: **pass** — our two-layer approach (swift-format + per-rule correctable lint) is better


## Summary of Changes

Evaluated `BasicFormat`'s token-pair model against our current architecture.

### Assessment

**Token-pair rules that overlap with our Whitespace/ rules:**
- `requiresWhitespace` handles: comma spacing, colon spacing, brace spacing, paren spacing, angle bracket spacing, operator spacing
- These map to our: `CommaRule`, `ColonRule`, `OpeningBraceRule`/`ClosingBraceRule`, `SpaceAroundParensRule`, `SpaceAroundGenericsRule`, `OperatorUsageSpacingRule`

**Why pass:**
1. `BasicFormat` is monolithic — no per-rule enable/disable, which is essential for our user-facing lint rules
2. We already delegate bulk formatting to swift-format's pretty-printer; our Whitespace/ rules are supplementary correctable lint checks
3. Adopting BasicFormat would add a third formatting layer (swift-format + BasicFormat + our rules) for marginal benefit
4. The token-pair pattern reduces flexibility for context-sensitive rules (e.g., `ColonRule` handles dictionary literals differently from type annotations)

**Useful patterns borrowed informally:**
- Token-pair thinking is already reflected in our `replaceTrailingTrivia`/`replaceLeadingTrivia` correction variants (from se8-7qh)
- The `isMutable` concept could inform disabled-region handling in the future
