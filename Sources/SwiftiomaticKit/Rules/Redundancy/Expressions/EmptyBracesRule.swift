import SwiftSyntax

struct EmptyBracesRule {
  static let id = "empty_braces"
  static let name = "Empty Braces"
  static let summary = "Empty braces should not contain whitespace"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("func foo() {}"),
      Example("class Bar {}"),
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
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("func foo() ↓{ }"): Example("func foo() {}")
    ]
  }

  var options = SeverityOption<Self>(.warning)
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
      guard hasInternalWhitespace(leftBrace: node.leftBrace, rightBrace: node.rightBrace)
      else {
        return
      }
      if isFollowedByElseOrCatch(node.rightBrace) { return }
      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: MemberBlockSyntax) {
      guard node.members.isEmpty else { return }
      guard hasInternalWhitespace(leftBrace: node.leftBrace, rightBrace: node.rightBrace)
      else {
        return
      }
      if isFollowedByElseOrCatch(node.rightBrace) { return }
      violations.append(node.leftBrace.positionAfterSkippingLeadingTrivia)
    }

    private func hasInternalWhitespace(
      leftBrace: TokenSyntax,
      rightBrace: TokenSyntax
    ) -> Bool {
      leftBrace.trailingTrivia.containsNewlines()
        || rightBrace.leadingTrivia.containsNewlines()
        || leftBrace.trailingTrivia.contains(where: {
          if case .spaces = $0 { return true }
          return false
        })
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

      if let nextToken = node.rightBrace.nextToken(viewMode: .sourceAccurate),
        nextToken.tokenKind == .keyword(.else) || nextToken.tokenKind == .keyword(.catch)
      {
        return super.visit(node)
      }

      let hasWhitespace =
        node.leftBrace.trailingTrivia.containsNewlines()
        || node.rightBrace.leadingTrivia.containsNewlines()
        || node.leftBrace.trailingTrivia.contains(where: {
          if case .spaces = $0 { return true }
          return false
        })
      guard hasWhitespace else { return super.visit(node) }

      numberOfCorrections += 1
      let newNode =
        node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, []))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, []))
      return super.visit(newNode)
    }

    override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
      guard node.members.isEmpty else { return super.visit(node) }

      if let nextToken = node.rightBrace.nextToken(viewMode: .sourceAccurate),
        nextToken.tokenKind == .keyword(.else) || nextToken.tokenKind == .keyword(.catch)
      {
        return super.visit(node)
      }

      let hasWhitespace =
        node.leftBrace.trailingTrivia.containsNewlines()
        || node.rightBrace.leadingTrivia.containsNewlines()
        || node.leftBrace.trailingTrivia.contains(where: {
          if case .spaces = $0 { return true }
          return false
        })
      guard hasWhitespace else { return super.visit(node) }

      numberOfCorrections += 1
      let newNode =
        node
        .with(\.leftBrace, node.leftBrace.with(\.trailingTrivia, []))
        .with(\.rightBrace, node.rightBrace.with(\.leadingTrivia, []))
      return super.visit(newNode)
    }
  }
}
