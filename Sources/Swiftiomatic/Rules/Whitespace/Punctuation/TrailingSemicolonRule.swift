import SwiftSyntax

struct TrailingSemicolonRule {
    static let id = "trailing_semicolon"
    static let name = "Trailing Semicolon"
    static let summary = "Lines should not have trailing semicolons"
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let a = 0"),
              Example("let a = 0; let b = 0"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("let a = 0↓;\n"),
              Example("let a = 0↓;\nlet b = 1"),
              Example("let a = 0↓; // a comment\n"),
            ]
    }
    static var corrections: [Example: Example] {
        [
              Example("let a = 0↓;\n"): Example("let a = 0\n"),
              Example("let a = 0↓;\nlet b = 1"): Example("let a = 0\nlet b = 1"),
              Example("let foo = 12↓;  // comment\n"): Example("let foo = 12  // comment\n"),
            ]
    }
  var options = SeverityOption<Self>(.warning)

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
