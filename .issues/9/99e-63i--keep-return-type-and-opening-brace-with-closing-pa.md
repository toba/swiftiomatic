---
# 99e-63i
title: Keep return type and opening brace with closing paren in multiline function signatures
status: scrapped
type: feature
priority: normal
created_at: 2026-04-24T18:15:09Z
updated_at: 2026-04-24T18:20:25Z
sync:
    github:
        issue_number: "371"
        synced_at: "2026-04-24T18:20:28Z"
---

## Problem

When a function signature is too long and parameters wrap, the current layout produces:

```swift
private func replaceAcronym(_ titlecased: String, with uppercased: String, in text: String)
        -> String
    {
```

The return type and opening brace are orphaned on separate lines from the closing paren.

## Desired Behavior

Parameters should wrap one-per-line, with `) -> ReturnType {` kept together on the closing line:

```swift
private func replaceAcronym(
    _ titlecased: String,
    with uppercased: String,
    in text: String
) -> String {
```

## Scope

Applies to all function-like declarations: `func`, `init`, subscripts. Should handle:
- `throws`/`async` effect specifiers: `) async throws -> String {`
- No return type: `) {`
- Generic where clauses (these go before the brace)

## Approach

Likely a **syntax rewriter** (`SyntaxFormatRule`) since this needs to restructure trivia across multiple tokens. Key considerations:

- [ ] Determine if this should be a standalone rule or an enhancement to `WrapMultilineStatementBraces`
- [ ] Check interaction with `PrioritizeKeepingFunctionOutputTogether` layout config
- [ ] The rule should trigger when: params are on the same line as `func name(` but the signature wraps mid-parameter-list, putting `) -> ReturnType` and/or `{` on orphaned lines
- [ ] The rule should reformat to: each param on its own line, `) -> ReturnType {` on the closing line
- [ ] Add tests covering: multiple params, single param, throws/async, no return type, generic where clause
- [ ] Verify `WrapMultilineStatementBraces` doesn't conflict (it currently moves `{` to its own line for multiline sigs — may need to exclude func decls when this rule is active, or this rule should run after and correct)

## Related Code

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Functions.swift` — layout engine for function decls
- `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/WrapMultilineStatementBraces.swift` — existing brace wrapping (potential conflict)
- `PrioritizeKeepingFunctionOutputTogether` config key

## Reasons for Scrapping

Already handled by `PrioritizeKeepingFunctionOutputTogether` layout rule (defaulted to false). Renaming to `keepFunctionOutputTogether` instead.
