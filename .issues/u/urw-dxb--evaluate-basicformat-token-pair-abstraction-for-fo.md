---
# urw-dxb
title: Evaluate BasicFormat token-pair abstraction for format rules
status: ready
type: task
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-12T23:54:23Z
parent: oad-n72
sync:
    github:
        issue_number: "246"
        synced_at: "2026-04-13T00:25:20Z"
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

- [ ] Prototype a token-pair formatting engine alongside existing format rules
- [ ] Identify which existing format rules could be expressed as token-pair decisions
- [ ] Evaluate whether the abstraction reduces code and bugs vs. current approach
- [ ] Decide: adopt as primary format engine, use selectively, or pass
