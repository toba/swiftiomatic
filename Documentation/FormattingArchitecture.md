# Formatting Architecture: Pretty-Printer vs Format Rules

Swiftiomatic uses a two-stage formatting pipeline. Understanding when to use each stage is key to writing effective formatting logic.

## Pipeline Overview

```
Source Code
    |
  [Parse] -> SourceFileSyntax
    |
  [Format Rules]  -- stage 1: rewrite the AST
    |
  [Pretty-Printer] -- stage 2: lay out the rewritten AST
    |
  Formatted Output
```

Format rules run first, sequentially, each rewriting the entire syntax tree. The pretty-printer then takes the final rewritten tree, converts it to a token stream, and applies layout decisions in a single pass.

## Pretty-Printer: Layout Engine

The pretty-printer controls whitespace -- line breaks, indentation, spacing -- based on line length. It implements the [Oppen algorithm](http://i.stanford.edu/pub/cstr/reports/cs/tr/79/770/CS-TR-79-770.pdf): `TokenStreamCreator` walks the (already-rewritten) syntax tree and emits a linear stream of tokens (`.break`, `.open`/`.close` groups, `.space`, `.syntax`), then `PrettyPrinter` decides where to break lines to fit the configured line length.

See [PrettyPrinter.md](PrettyPrinter.md) for details on the algorithm and token types.

### Capabilities

- Line-length-aware decisions ("does this fit on one line? if not, break here")
- Indentation (block, continuation, base)
- Trailing comma insertion based on whether something spans multiple lines
- Preserving discretionary newlines
- Comment positioning

### Limitations

- Cannot change the structure of code -- only controls whitespace between existing tokens
- Cannot reason about semantics -- doesn't know what a node *means*, just how wide it is
- Cannot add, remove, or move code

**Example**: The pretty-printer decides whether a function call's arguments go on one line or wrap, but it can't move a closure from inside parentheses to trailing position.

### Key Files

| File | Role |
|------|------|
| `Layout/LayoutCoordinator.swift` | Layout engine (scan + print phases) |
| `Layout/Tokens/Token.swift` | Token types encoding layout instructions |
| `Layout/Tokens/TokenStreamBase.swift` | `SyntaxVisitor` that converts AST to token stream |
| `Layout/Verbatim.swift` | Multiline string literal handling |

## Format Rules: AST Rewriters

Format rules (`SyntaxFormatRule` subclasses) receive the full syntax tree, visit specific node types, and return modified nodes. They have full read-write access to the AST via `SyntaxRewriter`.

### Capabilities

- Structural transformations (e.g., `PreferTrailingClosures` moves closures out of argument lists)
- Adding/removing code (e.g., `EmptyBraces` strips whitespace from `{ }` to `{}`)
- Trivia manipulation (e.g., `BlankLinesAfterImports` injects newlines)
- Complex semantic decisions based on parent/sibling context

### Limitations

- Cannot reason about line length -- a rule has no idea if its output will fit on one line
- Cannot control indentation or line-breaking -- its output is raw `node.description`
- No fine-grained layout control -- anything whitespace-related is better handled by the pretty-printer

### Key Files

| File | Role |
|------|------|
| `Syntax/Rewriter/RewriteSyntaxRule.swift` | Base class for format rules |
| `Syntax/Rewriter/RewriteCoordinator.swift` | Pipeline orchestration |
| `Generated/Pipelines+Generated.swift` | Generated rule dispatch (do not edit) |

## Decision Framework

When deciding where to implement a formatting behavior:

| Question | Pretty-Printer | Format Rule |
|----------|:--------------:|:-----------:|
| Involves line length or fitting? | Yes | -- |
| Purely about spacing or indentation? | Yes | -- |
| Moves, adds, or removes code? | -- | Yes |
| Restructures syntax (changes tree shape)? | -- | Yes |
| Depends on semantic context (parent nodes, types)? | -- | Yes |
| Blank lines between declarations? | Either | Simpler as rule |

### Rules of Thumb

- Changing *what* the code says -> **format rule**
- Changing *how it looks* on the page -> **pretty-printer** (via `TokenStreamCreator`)
- Need both? The **format rule does the restructuring**, then the pretty-printer handles layout automatically in the second stage

The key insight: rules don't need to worry about layout because the pretty-printer runs *after* them. A rule can make a messy structural change and the pretty-printer will clean up the formatting.
