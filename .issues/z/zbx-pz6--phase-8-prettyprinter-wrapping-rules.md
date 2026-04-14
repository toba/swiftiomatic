---
# zbx-pz6
title: 'Phase 8: PrettyPrinter wrapping rules'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:37:37Z
updated_at: 2026-04-14T20:03:39Z
parent: c7r-77o
sync:
    github:
        issue_number: "296"
        synced_at: "2026-04-14T18:45:53Z"
---

Wrapping rules that require PrettyPrinter enhancements rather than SyntaxFormatRule. From xuy-4wl.

- [x] `wrapMultilineStatementBraces` — Move `{` to its own line when statement signature spans multiple lines. Requires modifying the token preceding `{` (outside the code block node), handling 10+ statement types, and coordinating with indent. Parent: xuy-4wl.
- [x] `wrapMultilineFunctionChains` — All-or-nothing chain wrapping. 150+ lines of bidirectional chain traversal in SwiftFormat; fundamentally token-stream-based, awkward with AST nodes. Parent: xuy-4wl.
- [x] `wrapMultilineConditionalAssignment` — Wrap after `=` for multiline if/switch expressions. Requires re-indenting the entire RHS expression (SwiftFormat pairs this with its `indent` rule). Parent: xuy-4wl.
- [x] `wrapSingleLineComments` — Word-wrap `//` comments exceeding max line width. Column-based word splitting in comment trivia. Parent: xuy-4wl.

## Implementation Plan

### Architecture analysis

The PrettyPrinter pipeline works in two phases:

1. **FormatPipeline** — `SyntaxFormatRule` rules rewrite the AST sequentially (each rule visits the full tree).
2. **PrettyPrinter** — `TokenStreamCreator` converts the (rewritten) AST into a flat `[Token]` stream, then `PrettyPrinter.prettyPrint()` lays it out respecting `maxLineLength`.

The key architectural question for each rule: **can it be a `SyntaxFormatRule` (AST rewrite) or does it require changes to the token stream / printer?**

### Rule-by-rule analysis

#### 1. `wrapMultilineStatementBraces` — SyntaxFormatRule ✅

**Why AST works here**: The rule's logic is: "if the signature from the statement keyword to `{` spans multiple lines, move `{` to its own line." This is a local AST check + trivia manipulation, not a line-length calculation.

**swift-format already handles this** via `BreakKind.reset` breaks before `{`. The `arrangeBracesAndContents` method at `TokenStreamCreator.swift:3299` inserts `.break(.reset, size: 1)` before every `leftBrace`. When the preceding lines are continuation lines, the `reset` break fires automatically, moving `{` to a new line. This means **much of this behavior already works via the PrettyPrinter**.

**What's missing**: The PrettyPrinter's `reset` only fires when the current line is a continuation line. It doesn't detect the broader case where the *signature* (not just the current line) is multiline. For example:

```swift
// reset break fires here (continuation line):
func foo(
  _ x: Int
) {     // ← already works, reset fires

// reset break does NOT fire here (not a continuation):
if foo,
   bar {     // ← `bar {` is same indent level, not continuation
   // ...
}
```

**Approach**: Implement as a `SyntaxFormatRule` that:
1. Visits all statement types with braces: `IfExprSyntax`, `GuardStmtSyntax`, `ForStmtSyntax`, `WhileStmtSyntax`, `RepeatStmtSyntax`, `SwitchExprSyntax`, `DoStmtSyntax`, `FunctionDeclSyntax`, `InitializerDeclSyntax`, `DeinitializerDeclSyntax`, `ClassDeclSyntax`, `StructDeclSyntax`, `EnumDeclSyntax`, `ActorDeclSyntax`, `ProtocolDeclSyntax`, `ExtensionDeclSyntax`, `ClosureExprSyntax`.
2. For each: check if the span from the first significant token to the `leftBrace` crosses a newline (via `SourceLocationConverter` or trivia scanning).
3. If multiline AND the token before `{` is not already a newline: insert a newline + indent trivia before `{`, and strip trailing whitespace from the preceding token.
4. Align the `{` indent with the closing `}` indent (read from `}` leading trivia).

**Complexity**: Moderate. The 10+ statement types can be handled with a single helper that takes `leftBrace: TokenSyntax` and checks the signature-to-brace span. The rule should run `orderAfter` any rules that affect brace placement.

**Config**: `isOptIn = true` (matches SwiftFormat's default).

**Key files**:
- New: `Sources/Swiftiomatic/Rules/WrapMultilineStatementBraces.swift`
- New: `Tests/SwiftiomaticTests/Rules/WrapMultilineStatementBracesTests.swift`
- Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/WrapMultilineStatementBraces.swift`
- Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/FormattingHelpers.swift` (`shouldWrapMultilineStatementBrace`)

#### 2. `wrapMultilineFunctionChains` — PrettyPrinter enhancement required ⚠️

**Why PrettyPrinter**: This rule needs "all-or-nothing" semantics: if *any* chain component is on a different line, *all* dots must break. This is a line-fitting decision, not a static AST property. The PrettyPrinter already supports `contextual` breaks and `contextualBreakingStart/End` scopes for chains (`TokenStreamCreator.swift:4247-4339`), and it has the `lineBreakAroundMultilineExpressionChainComponents` config option that controls whether multiline chain components force surrounding breaks.

**What exists**: `insertContextualBreaks` already walks `MemberAccessExprSyntax` → `CallingExprSyntax` chains and inserts `.break(.contextual, size: 0)` before each `.period`. The `contextual` break kind in `PrettyPrint.swift:390-424` decides whether to break based on the previous context's line span. The config `lineBreakAroundMultilineExpressionChainComponents` (default: false) controls whether breaks fire when the previous component was multiline.

**What's missing**: The current `contextual` break behavior is "indent following chain components if the previous one was multiline." SwiftFormat's `wrapMultilineFunctionChains` is different: "if any dot is on a different line from the chain start, ensure ALL dots are on separate lines" — i.e., consistent all-or-nothing wrapping of the dot positions themselves.

**Approach**: Extend the PrettyPrinter with a new break behavior or modify the contextual break logic:

Option A — **Consistent group around chain**: Wrap the entire chain in a `.open(.consistent)` group so that if any `contextual` break fires, all fire. This would require:
- In `TokenStreamCreator.insertContextualBreaks`: when building a chain, wrap the full chain (from base through last call) in `.open(.consistent)` / `.close`.
- Guard this behind a new config flag `wrapMultilineFunctionChains: Bool`.
- The `contextual` breaks between chain components would fire consistently.

Option B — **Post-scan pass**: After `TokenStreamCreator` builds the token stream, scan for contextual break regions and promote them to consistent groups when the config is enabled.

**Recommendation**: Option A is cleaner. The consistent group approach aligns with how the PrettyPrinter already handles `consistent` vs `inconsistent` groups. The main change is in `insertContextualBreaks` — wrap the outermost chain expression in a consistent group, and make the `.contextual` breaks act as `.same` breaks within that group.

**Key challenge**: Distinguishing property access chains (`.foo.bar.baz`) from function call chains (`.map {}.filter {}.reduce()`). SwiftFormat checks for at least one function call in the chain and at least two dots. The existing `insertContextualBreaks` already tracks `CallingExprSyntax` vs `MemberAccessExprSyntax`, so this data is available.

**Config**: New `wrapMultilineFunctionChains: Bool` (default: false, opt-in). Add to `Configuration.swift` 4-file checklist.

**Key files**:
- Modify: `Sources/Swiftiomatic/PrettyPrint/TokenStreamCreator.swift` (`insertContextualBreaks`)
- Modify: `Sources/Swiftiomatic/PrettyPrint/PrettyPrint.swift` (possibly, if consistent group alone isn't enough)
- Modify: `Sources/Swiftiomatic/API/Configuration.swift` + `Configuration+Default.swift` + `Configuration+Testing.swift`
- New: `Tests/SwiftiomaticTests/PrettyPrint/WrapMultilineFunctionChainsTests.swift`
- Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/WrapMultilineFunctionChains.swift`

#### 3. `wrapMultilineConditionalAssignment` — SyntaxFormatRule ✅

**Why AST works here**: The rule checks: "is the RHS of `=` an `if`/`switch` expression that spans multiple lines? If so, put a line break between `=` and the keyword." This is a static AST property — we can check if the `if`/`switch` body spans lines by examining trivia.

**Approach**: Implement as a `SyntaxFormatRule` visiting `InfixOperatorExprSyntax` (or `SequenceExprSyntax` after folding) where the operator is `=` and the RHS is an `IfExprSyntax` or `SwitchExprSyntax`:
1. Check if the entire expression is single-line → skip.
2. Check if the `=` and the property name are on different lines → move `=` to end of property line.
3. Check if there's no line break between `=` and `if`/`switch` → insert one.
4. The PrettyPrinter's existing indent behavior handles re-indentation of the RHS body automatically (the `=` operator already gets continuation breaks in `TokenStreamCreator`).

**Key insight**: Unlike SwiftFormat, we don't need to manually re-indent the RHS because the PrettyPrinter runs after `SyntaxFormatRule` rules and handles indentation. We just need to ensure the line break exists; the PrettyPrinter will indent correctly.

**Complexity**: Low-moderate. The tricky part is correctly identifying the assignment operator in the folded expression tree. After operator folding, `let x = if ...` becomes a pattern binding where the initializer is an `IfExprSyntax` — we should visit `PatternBindingSyntax` where `initializer?.value` is `IfExprSyntax` or `SwitchExprSyntax`. Also handle `InfixOperatorExprSyntax` for `x = if ...` reassignments.

**Config**: `isOptIn = true` (matches SwiftFormat).

**Key files**:
- New: `Sources/Swiftiomatic/Rules/WrapMultilineConditionalAssignment.swift`
- New: `Tests/SwiftiomaticTests/Rules/WrapMultilineConditionalAssignmentTests.swift`
- Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/WrapMultilineConditionalAssignment.swift`

#### 4. `wrapSingleLineComments` — PrettyPrinter enhancement required ⚠️

**Why PrettyPrinter**: Comment wrapping depends on column position, which is only known at print time. The PrettyPrinter already handles `Token.comment` and tracks `outputBuffer.column`. Comments are extracted from trivia in `TokenStreamCreator` and emitted as `Token.comment` with computed `.length`.

**What exists**: `PrettyPrint.swift:479-493` prints comments and diagnoses end-of-line comments that exceed line length (`.moveEndOfLineComment`). The `Comment` type (need to check) already parses and prints comments with indent awareness.

**Approach**: Extend the PrettyPrinter's comment handling to split long `//` comments:

1. In `printToken` for `.comment` case: after computing the comment's print output, check if the line exceeds `maxLineLength`.
2. If it does and the comment is a line comment (`comment.kind == .line` or `.docLine`):
   - Word-split the comment body.
   - Emit the first line up to `maxLineLength`.
   - Emit remaining words as a new line with the same indent and comment prefix (`//` or `///`).
   - Handle doc comment prefixes (`/// `) vs regular (`// `).
   - Don't split if the next word alone wouldn't fit on a line by itself (avoid infinite loops).
   - Don't split comment directives (`// swiftiomatic-ignore`, `// swift-format-ignore`, `// MARK:`, etc.).

**Alternative**: Handle this in `TokenStreamCreator` when creating `Comment` tokens — split long comments into multiple `Comment` tokens separated by breaks. This would be cleaner since the PrettyPrinter already handles multiple sequential comments. However, the column position isn't known at tokenization time, so this won't work for indented code.

**Recommendation**: Handle in `PrettyPrinter.printToken` or in a new method called from it. The `outputBuffer.column` gives the current indent level, and `maxLineLength - column` gives available width. This is the most accurate approach since it accounts for actual indentation.

**Config**: Controlled by existing `lineLength` config. No new config needed (or optionally gate behind `isOptIn` if we want users to opt in). Could also add a minimum width threshold to avoid excessive wrapping.

**Key files**:
- Modify: `Sources/Swiftiomatic/PrettyPrint/PrettyPrint.swift` (comment printing)
- Possibly modify: `Sources/Swiftiomatic/PrettyPrint/Comment.swift` (if it exists) for word-splitting logic
- New: `Tests/SwiftiomaticTests/PrettyPrint/WrapSingleLineCommentsTests.swift`
- Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/WrapSingleLineComments.swift`

### Implementation order

1. **`wrapMultilineConditionalAssignment`** — Simplest. Pure `SyntaxFormatRule`, no PrettyPrinter changes. Good warm-up.
2. **`wrapMultilineStatementBraces`** — `SyntaxFormatRule` with many statement types but straightforward logic. Tests should adapt the SwiftFormat examples.
3. **`wrapSingleLineComments`** — First PrettyPrinter modification. Localized change in comment printing, no token stream restructuring.
4. **`wrapMultilineFunctionChains`** — Most complex. Requires understanding and extending the contextual break system. Should be done last since it touches the most sensitive code.

### Risk areas

- **`wrapMultilineFunctionChains`**: The contextual break system is the most intricate part of the PrettyPrinter. Changes here can cause cascading formatting differences across the entire codebase. Extensive testing with real-world Swift code is essential. The existing `lineBreakAroundMultilineExpressionChainComponents` config partially overlaps — need to decide if the new rule replaces it, complements it, or is gated separately.
- **`wrapSingleLineComments`**: Word-splitting inside the PrettyPrinter's `printToken` means the printer is no longer just laying out pre-computed tokens — it's generating new output. This is a conceptual shift. Need to ensure `outputBuffer` state (line number, column) stays consistent after the split.
- **`wrapMultilineStatementBraces`**: The PrettyPrinter's existing `reset` break handles many cases already. The `SyntaxFormatRule` may produce trivia that conflicts with the PrettyPrinter's own formatting. Need to verify that `assertFormatting`'s two-pass test (single rule + full pipeline) doesn't produce conflicts.



## Summary of Changes

Implemented 3 of 4 wrapping rules as SyntaxFormatRule format rules (not PrettyPrinter changes):

1. **wrapMultilineConditionalAssignment** — Wraps `=` onto its own line when RHS is a multiline `if`/`switch` expression. Handles both `let/var` declarations (`PatternBindingSyntax`) and reassignments (`InfixOperatorExprSyntax`). Also moves `=` from a separate line back to the property line when needed. 11 tests.

2. **wrapMultilineStatementBraces** — Moves `{` to its own line when the statement signature spans multiple lines. Uses indentation comparison (prevToken line indent > closing brace indent) rather than naive newline scanning (which catches nested scopes). Handles 15 node types via a shared `wrappedBrace` helper. Uses `TokenStripper` rewriter to clean trailing whitespace from the preceding token. 18 tests.

3. **wrapSingleLineComments** — Word-wraps `//` and `///` comments exceeding `lineLength`. Implemented as a token visitor that modifies leading trivia. Uses `.leadingTrivia(triviaIndex)` anchor for accurate finding position. Skips comment directives (MARK, TODO, etc.) and words that won't fit on their own line. 10 tests.

All 4 rules completed as SyntaxFormatRules. `wrapMultilineFunctionChains` was initially misclassified as requiring PrettyPrinter changes — deep analysis of SwiftFormat reference revealed it's a source-trivia consistency rule (not a layout rule), making it implementable as a SyntaxFormatRule. 52 tests total.
