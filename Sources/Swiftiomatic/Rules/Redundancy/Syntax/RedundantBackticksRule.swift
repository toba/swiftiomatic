import SwiftSyntax

struct RedundantBackticksRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "redundant_backticks",
    name: "Redundant Backticks",
    description:
      "Backtick-escaped identifiers that are not keywords in their context are redundant",
    scope: .format,
    nonTriggeringExamples: [
      Example("let `class` = \"value\""),
      Example("func `init`() {}"),
      Example("let `self` = this"),
    ],
    triggeringExamples: [
      Example("let ↓`foo` = bar"),
      Example("func ↓`myFunc`() {}"),
    ],
    corrections: [
      Example("let ↓`foo` = bar"): Example("let foo = bar")
    ],
  )
}

extension RedundantBackticksRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension RedundantBackticksRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      guard node.hasRedundantBackticks else { return }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visitAny(_ node: Syntax) -> Syntax? {
      if let result = super.visitAny(node) { return result }
      guard let token = node.as(TokenSyntax.self), token.hasRedundantBackticks else {
        return nil
      }
      numberOfCorrections += 1
      return Syntax(
        token.with(\.tokenKind, .identifier(token.identifier?.name ?? token.text)),
      )
    }
  }
}

extension TokenSyntax {
  fileprivate var hasRedundantBackticks: Bool {
    // Only applies to backtick-escaped identifiers
    guard case .identifier(let name) = tokenKind,
      text.hasPrefix("`"), text.hasSuffix("`")
    else {
      return false
    }
    // If the unescaped name is a keyword, backticks are needed
    return !name.isSwiftKeyword
  }
}
