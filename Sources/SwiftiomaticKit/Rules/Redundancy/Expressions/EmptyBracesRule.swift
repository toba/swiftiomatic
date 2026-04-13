import SwiftiomaticSyntax

struct EmptyBracesRule {
  static let id = "empty_braces"
  static let name = "Empty Braces"
  static let summary = "Empty braces should follow the configured style"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("func foo() {}"),
      Example("class Bar {}"),
      // spaced style
      Example("func foo() { }", configuration: ["style": "spaced"]),
      Example("class Bar { }", configuration: ["style": "spaced"]),
      // linebreak style
      Example("func foo() {\n}", configuration: ["style": "linebreak"]),
      Example("    func foo() {\n    }", configuration: ["style": "linebreak"]),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("func foo() ↓{ }"),
      Example(
        """
        func foo() ↓{

        }
        """,
      ),
      // spaced style: no space or too much space
      Example("func foo() ↓{}", configuration: ["style": "spaced"]),
      Example(
        """
        func foo() ↓{

        }
        """,
        configuration: ["style": "spaced"],
      ),
      // linebreak style: no linebreak or extra content
      Example("func foo() ↓{}", configuration: ["style": "linebreak"]),
      Example("func foo() ↓{ }", configuration: ["style": "linebreak"]),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("func foo() ↓{ }"): Example("func foo() {}"),
      // spaced corrections
      Example("func foo() ↓{}", configuration: ["style": "spaced"]):
        Example("func foo() { }"),
      Example("func foo() ↓{  }", configuration: ["style": "spaced"]):
        Example("func foo() { }"),
      // linebreak corrections
      Example("func foo() ↓{}", configuration: ["style": "linebreak"]):
        Example("func foo() {\n}"),
      Example("func foo() ↓{ }", configuration: ["style": "linebreak"]):
        Example("func foo() {\n}"),
      Example("    func foo() ↓{}", configuration: ["style": "linebreak"]):
        Example("    func foo() {\n    }"),
    ]
  }

  var options = EmptyBracesOptions()
}

extension EmptyBracesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension EmptyBracesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: CodeBlockSyntax) {
      guard node.statements.isEmpty else { return }
      if isFollowedByElseOrCatch(node.rightBrace) { return }
      if violatesStyle(leftBrace: node.leftBrace, rightBrace: node.rightBrace) {
        violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: MemberBlockSyntax) {
      guard node.members.isEmpty else { return }
      if isFollowedByElseOrCatch(node.rightBrace) { return }
      if violatesStyle(leftBrace: node.leftBrace, rightBrace: node.rightBrace) {
        violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
      }
    }

    private func violatesStyle(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax,
    ) -> Bool {
      switch configuration.style {
      case .noSpace:
        return hasAnyInternalWhitespace(leftBrace: leftBrace, rightBrace: rightBrace)
      case .spaced:
        return !hasExactlySingleSpace(leftBrace: leftBrace, rightBrace: rightBrace)
      case .linebreak:
        return !hasLinebreakWithIndentation(leftBrace: leftBrace, rightBrace: rightBrace)
      }
    }

    private func hasAnyInternalWhitespace(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax,
    ) -> Bool {
      leftBrace.trailingTrivia.containsNewlines()
        || rightBrace.leadingTrivia.containsNewlines()
        || leftBrace.trailingTrivia.contains(where: {
          if case .spaces = $0 { return true }
          return false
        })
    }

    private func hasExactlySingleSpace(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax,
    ) -> Bool {
      leftBrace.trailingTrivia == Trivia(pieces: [.spaces(1)])
        && rightBrace.leadingTrivia == Trivia()
    }

    private func hasLinebreakWithIndentation(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax,
    ) -> Bool {
      let indent = lineIndentation(for: leftBrace, locationConverter: locationConverter, file: file)
      let expectedLeadingTrivia =
        indent.isEmpty
        ? Trivia(pieces: [.newlines(1)])
        : Trivia(pieces: [.newlines(1)] + indent.pieces)
      return leftBrace.trailingTrivia == Trivia(pieces: [.newlines(1)])
        && rightBrace.leadingTrivia == expectedLeadingTrivia
    }

    private func isFollowedByElseOrCatch(_ rightBrace: TokenSyntax) -> Bool {
      if let nextToken = rightBrace.nextToken(viewMode: .sourceAccurate),
        nextToken.tokenKind == .keyword(.else) || nextToken.tokenKind == .keyword(.catch)
      {
        return true
      }
      return false
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
      guard node.statements.isEmpty else { return super.visit(node) }
      if isFollowedByElseOrCatch(node.rightBrace) { return super.visit(node) }
      guard needsCorrection(leftBrace: node.leftBrace, rightBrace: node.rightBrace) else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      return super.visit(applyStyle(node))
    }

    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
      guard node.members.isEmpty else { return super.visit(node) }
      if isFollowedByElseOrCatch(node.rightBrace) { return super.visit(node) }
      guard needsCorrection(leftBrace: node.leftBrace, rightBrace: node.rightBrace) else {
        return super.visit(node)
      }

      numberOfCorrections += 1
      return super.visit(applyStyle(node))
    }

    private func needsCorrection(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax,
    ) -> Bool {
      switch configuration.style {
      case .noSpace:
        return leftBrace.trailingTrivia.containsNewlines()
          || rightBrace.leadingTrivia.containsNewlines()
          || leftBrace.trailingTrivia.contains(where: {
            if case .spaces = $0 { return true }
            return false
          })
      case .spaced:
        return leftBrace.trailingTrivia != Trivia(pieces: [.spaces(1)])
          || rightBrace.leadingTrivia != Trivia()
      case .linebreak:
        let indent = lineIndentation(for: leftBrace, locationConverter: locationConverter, file: file)
        let expectedLeading =
          indent.isEmpty
          ? Trivia(pieces: [.newlines(1)])
          : Trivia(pieces: [.newlines(1)] + indent.pieces)
        return leftBrace.trailingTrivia != Trivia(pieces: [.newlines(1)])
          || rightBrace.leadingTrivia != expectedLeading
      }
    }

    private func applyStyle(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
      let (leftTrivia, rightTrivia) = targetTrivia(for: node.leftBrace)
      return node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, leftTrivia))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, rightTrivia))
    }

    private func applyStyle(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
      let (leftTrivia, rightTrivia) = targetTrivia(for: node.leftBrace)
      return node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, leftTrivia))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, rightTrivia))
    }

    private func targetTrivia(for leftBrace: TokenSyntax) -> (Trivia, Trivia) {
      switch configuration.style {
      case .noSpace: return ([], [])
      case .spaced: return (Trivia(pieces: [.spaces(1)]), [])
      case .linebreak:
        let indent = lineIndentation(
          for: leftBrace, locationConverter: locationConverter, file: file)
        let rightTrivia =
          indent.isEmpty
          ? Trivia(pieces: [.newlines(1)])
          : Trivia(pieces: [.newlines(1)] + indent.pieces)
        return (Trivia(pieces: [.newlines(1)]), rightTrivia)
      }
    }

    private func isFollowedByElseOrCatch(_ rightBrace: TokenSyntax) -> Bool {
      if let nextToken = rightBrace.nextToken(viewMode: .sourceAccurate),
        nextToken.tokenKind == .keyword(.else) || nextToken.tokenKind == .keyword(.catch)
      {
        return true
      }
      return false
    }
  }
}

/// Returns the leading whitespace trivia for the line containing the given token.
private func lineIndentation(
  for token: TokenSyntax,
  locationConverter: SourceLocationConverter,
  file: SwiftSource,
) -> Trivia {
  let line = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
  guard line > 0, line <= file.lines.count else { return [] }
  let content = file.lines[line - 1].content
  let whitespace = content.prefix(while: { $0 == " " || $0 == "\t" })
  guard !whitespace.isEmpty else { return [] }
  // Build trivia from the leading whitespace
  if whitespace.allSatisfy({ $0 == "\t" }) {
    return Trivia(pieces: [.tabs(whitespace.count)])
  }
  return Trivia(pieces: [.spaces(whitespace.count)])
}
