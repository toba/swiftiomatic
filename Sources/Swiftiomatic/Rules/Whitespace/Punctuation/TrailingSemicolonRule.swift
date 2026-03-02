import SwiftSyntax

struct TrailingSemicolonRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = TrailingSemicolonConfiguration()
}

extension TrailingSemicolonRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension TrailingSemicolonRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      if node.isTrailingSemicolon {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: TokenSyntax) -> TokenSyntax {
      guard node.isTrailingSemicolon else {
        return super.visit(node)
      }
      numberOfCorrections += 1
      return .unknown("").with(\.trailingTrivia, node.trailingTrivia)
    }
  }
}

extension TokenSyntax {
  fileprivate var isTrailingSemicolon: Bool {
    tokenKind == .semicolon
      && (trailingTrivia.containsNewlines()
        || (nextToken(viewMode: .sourceAccurate)?.leadingTrivia.containsNewlines() == true))
  }
}
