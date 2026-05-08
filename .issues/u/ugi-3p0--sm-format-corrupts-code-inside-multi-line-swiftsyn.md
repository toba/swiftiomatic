---
# ugi-3p0
title: '`sm format` corrupts code inside multi-line `"""` SwiftSyntax DeclSyntax literals'
status: completed
type: bug
priority: high
created_at: 2026-05-08T16:28:26Z
updated_at: 2026-05-08T16:39:36Z
sync:
    github:
        issue_number: "662"
        synced_at: "2026-05-08T16:40:16Z"
---

\`sm format --in-place\` collapses multi-line function calls embedded inside SwiftSyntax \`\"\"\"\`-delimited DeclSyntax string literals (used in macro implementations). It strips the line breaks and surrounding whitespace, which (a) makes the generated code unreadable and (b) **produces a syntax error** when adjacent tokens collide.

## Repro

Source: \`thesis/Core/Macros/Sources/ThesisMacroPlugin/DatabaseFunctionMacro.swift\` around line 548 (HEAD).

Before formatting:

\`\`\`swift
                    \"\"\"
                    public func invoke(
                    _ decoder: inout some Core.QueryDecoder
                    ) throws -> Core.QueryBinding {
                    \\(raw: decodingBlock)\\
                    \\(raw: scalarInvocationBody(
                        representableOutputType: functionRepresentation?.returnClause.type
                            ?? outputType,
                        isVoidReturning: isVoidReturning,
                        argumentBindings: argumentBindings,
                        bodyInvocationPrefix: bodyInvocationPrefix,
                        throwsClause: declaration.signature.effectSpecifiers?.throwsClause,
                    ))
                    }
                    \"\"\" as DeclSyntax
\`\`\`

After \`sm format --in-place\`:

\`\`\`swift
                    \"\"\"
                    public func invoke(
                    _ decoder: inout some Core.QueryDecoder
                    ) throws -> Core.QueryBinding {
                    \\(raw: decodingBlock)\\
                    \\(raw: scalarInvocationBody(representableOutputType: functionRepresentation?.returnClause.type?? outputType,isVoidReturning: isVoidReturning,argumentBindings: argumentBindings,bodyInvocationPrefix: bodyInvocationPrefix,throwsClause: declaration.signature.effectSpecifiers?.throwsClause,))
                    }
                    \"\"\" as DeclSyntax
\`\`\`

Compiler error:

\`\`\`
DatabaseFunctionMacro.swift:519:118 — Expected ',' separator
\`\`\`

The collision \`type ?? outputType\` → \`type?? outputType\` is the syntax error: the optional-chain \`?\` adjacent to the nil-coalescing \`??\` is parsed as \`???\` / postfix \`??\`, breaking the call.

## Why this is wrong

Content inside a multi-line \`\"\"\"\` literal is **not Swift code that should be reformatted by sm** — it is data (a string) that happens to contain Swift code intended as input to SwiftSyntax / a macro expansion. Collapsing whitespace inside it changes the resulting string. Even when the result is still syntactically valid Swift in isolation, here it actually produces invalid Swift after token collision.

## Expected

\`sm format\` should treat the contents of multi-line string literals as opaque (no whitespace/line-break rewriting inside them). This applies generally, not just to DeclSyntax — the formatter cannot know whether a \`\"\"\"\` literal will be parsed as code, SQL, JSON, etc.

## Scope

Found while running \`sm format --in-place\` over a list of 45 files in \`thesis/\` to autofix lint issues. The macro file was the only build break, but the same rule (don't reformat inside string literals) likely applies broadly. There may be other silent corruption (e.g. SQL inside \`\"\"\"\` literals having keywords adjusted) that did not break the build but changed semantics.

## Workaround

Skip files containing macro-expansion DeclSyntax literals, or pre-protect them with \`// sm:ignore:next all\` directives before each \`\"\"\"\`. Neither is reliable.



## Summary of Changes

Fixed token-collision bug in `visitExpressionSegment` (`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift`). When collapsing pre-split interpolation content across newlines, the previous heuristic only inserted a separating space for ident-ident adjacency. Binary operators (`??`, `+`, `&&`, etc.) joined to an identifier without whitespace were reclassified by Swift's lexer as postfix/prefix, producing syntax errors in the output.

Now also inserts a space when either adjacent token is `.binaryOperator(_)`, which uniformly covers every standard binary operator (`+ - * / % < > <= >= == != && || & | ^ << >> ... ..< ??`) plus user-defined infix operators. Special tokens that aren't `.binaryOperator` (`=`, `->`, `.`, postfix `?`/`!`, prefix `&`) accept asymmetric whitespace and don't need the change.

Added regression test `StringTests.multilineStringPreSplitInterpolationOperatorBoundary`. Full suite (3275 tests) passes.

### Note on upstream divergence

Apple's swift-format `visit(ExpressionSegmentSyntax)` emits `node.description` verbatim and never collapses whitespace, so it doesn't have this bug. Swiftiomatic replaced that with a custom token walk to fix the "Insufficient indentation" issue (9yv-e8j). The bigger architectural alternative — restoring upstream behavior and solving the indentation problem in the layout pass — is left as follow-up.
