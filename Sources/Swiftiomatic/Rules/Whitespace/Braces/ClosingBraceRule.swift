import SwiftSyntax

struct ClosingBraceRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "closing_brace",
    name: "Closing Brace Spacing",
    description:
      "Closing brace with closing parenthesis should not have any whitespaces in the middle",
    kind: .style,
    nonTriggeringExamples: [
      Example("[].map({ })"),
      Example("[].map(\n  { }\n)"),
    ],
    triggeringExamples: [
      Example("[].map({ ↓} )"),
      Example("[].map({ ↓}\t)"),
    ],
    corrections: [
      Example("[].map({ ↓} )"): Example("[].map({ })")
    ],
  )
}

extension ClosingBraceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension ClosingBraceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: TokenSyntax) {
      if node.hasClosingBraceViolation {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
    override func visit(_ node: TokenSyntax) -> TokenSyntax {
      guard node.hasClosingBraceViolation else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return super.visit(node.with(\.trailingTrivia, Trivia()))
    }
  }
}

extension TokenSyntax {
  fileprivate var hasClosingBraceViolation: Bool {
    guard
      tokenKind == .rightBrace,
      let nextToken = nextToken(viewMode: .sourceAccurate),
      nextToken.tokenKind == .rightParen
    else {
      return false
    }

    let isImmediatelyNext =
      positionAfterSkippingLeadingTrivia
      == nextToken.positionAfterSkippingLeadingTrivia - SourceLength(utf8Length: 1)
    if isImmediatelyNext || nextToken.hasLeadingNewline {
      return false
    }
    return true
  }

  private var hasLeadingNewline: Bool {
    leadingTrivia.contains { piece in
      if case .newlines = piece {
        return true
      }
      return false
    }
  }
}
