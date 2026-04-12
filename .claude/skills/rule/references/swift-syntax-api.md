# swift-syntax API Quick Reference

Key APIs used in Visitor/Rewriter implementations.

## Position & Location

```swift
// SourceLocationConverter — available as `locationConverter` in Visitor/Rewriter
let loc = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
loc.line    // Int (1-based, NON-optional)
loc.column  // Int (1-based, NON-optional)

// Key position properties on syntax nodes:
node.position                          // AbsolutePosition — start including leading trivia
node.positionAfterSkippingLeadingTrivia // AbsolutePosition — start of actual text
node.endPosition                       // AbsolutePosition — end including trailing trivia
node.endPositionBeforeTrailingTrivia    // AbsolutePosition — end of actual text
```

## Trivia Manipulation

```swift
// Read trivia
token.leadingTrivia     // Trivia before the token text
token.trailingTrivia    // Trivia after the token text
trivia.pieces           // [TriviaPiece] — individual pieces (spaces, newlines, comments)
trivia.containsNewlines()  // helper extension
trivia.containsComments    // helper extension

// Modify trivia (returns new node — SwiftSyntax is immutable)
token.with(\.leadingTrivia, .space)          // single space
token.with(\.leadingTrivia, Trivia(pieces: newPieces))
token.with(\.trailingTrivia, [])             // remove all

// Common trivia values
Trivia.space                     // single space
Trivia.newline                   // single newline
Trivia(pieces: [.spaces(4)])     // 4 spaces
```

## Token Navigation

```swift
node.lastToken(viewMode: .sourceAccurate)    // last token in a syntax node
token.nextToken(viewMode: .sourceAccurate)    // next token in the source
token.previousToken(viewMode: .sourceAccurate)
```

## File Access

```swift
// In Visitor/Rewriter, `file` is the SwiftSource instance
file.contents         // String — full source text
file.lines            // [Line] — parsed lines (0-based array, but Line.index is 1-based)
file.lines[n - 1].content  // String — text of line n (no newline terminator)
file.stringView       // StringView — optimized string operations
```

## Common Patterns

**Replace trivia between two tokens** (e.g., collapse newline+indent to space):
```swift
let lastToken = node.lastToken(viewMode: .sourceAccurate)!
let nextToken = lastToken.nextToken(viewMode: .sourceAccurate)!
let correction = SyntaxViolation.Correction(
  start: lastToken.endPositionBeforeTrailingTrivia,
  end: nextToken.positionAfterSkippingLeadingTrivia,
  replacement: " ",
)
```

**Compute line width** (for max_width checks):
```swift
let loc = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
let indent = loc.column - 1  // 0-based column
let lineContent = file.lines[loc.line - 1].content
let strippedLength = lineContent.drop(while: { $0 == " " || $0 == "\t" }).count
```

**Check attribute properties**:
```swift
// AttributeSyntax
attribute.attributeNameText     // String, e.g. "Test" (extension in SwiftSyntax+Declarations.swift)
attribute.arguments             // nil if no arguments, non-nil for @Test(.tags(...))
attribute.trimmedDescription    // "@Test" — text without surrounding trivia

// AttributeListSyntax
node.children(viewMode: .sourceAccurate).compactMap { $0.as(AttributeSyntax.self) }
```
