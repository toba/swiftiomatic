import SwiftSyntax

struct ClosingBraceRule {
    static let id = "closing_brace"
    static let name = "Closing Brace Spacing"
    static let summary = "Closing brace with closing parenthesis should not have any whitespaces in the middle"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("[].map({ })"),
              Example("[].map(\n  { }\n)"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("[].map({ ↓} )"),
              Example("[].map({ ↓}\t)"),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("[].map({ ↓} )"): Example("[].map({ })")
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension ClosingBraceRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension ClosingBraceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      if node.hasClosingBraceViolation {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
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
