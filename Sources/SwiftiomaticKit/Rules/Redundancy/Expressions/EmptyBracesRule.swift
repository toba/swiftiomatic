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
      }
    }

    private func applyStyle(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
      let (leftTrivia, rightTrivia) = targetTrivia
      return node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, leftTrivia))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, rightTrivia))
    }

    private func applyStyle(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
      let (leftTrivia, rightTrivia) = targetTrivia
      return node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, leftTrivia))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, rightTrivia))
    }

    private var targetTrivia: (Trivia, Trivia) {
      switch configuration.style {
      case .noSpace: ([], [])
      case .spaced: (Trivia(pieces: [.spaces(1)]), [])
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
