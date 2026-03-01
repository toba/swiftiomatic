import SwiftSyntax

struct TrailingSemicolonRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "trailing_semicolon",
    name: "Trailing Semicolon",
    description: "Lines should not have trailing semicolons",
    nonTriggeringExamples: [
      Example("let a = 0"),
      Example("let a = 0; let b = 0"),
    ],
    triggeringExamples: [
      Example("let a = 0↓;\n"),
      Example("let a = 0↓;\nlet b = 1"),
      Example("let a = 0↓; // a comment\n"),
    ],
    corrections: [
      Example("let a = 0↓;\n"): Example("let a = 0\n"),
      Example("let a = 0↓;\nlet b = 1"): Example("let a = 0\nlet b = 1"),
      Example("let foo = 12↓;  // comment\n"): Example("let foo = 12  // comment\n"),
    ],
  )
}

extension TrailingSemicolonRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<ConfigurationType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension TrailingSemicolonRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: TokenSyntax) {
      if node.isTrailingSemicolon {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<ConfigurationType> {
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
