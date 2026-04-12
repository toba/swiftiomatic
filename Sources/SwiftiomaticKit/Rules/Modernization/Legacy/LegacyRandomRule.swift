import SwiftiomaticSyntax

struct LegacyRandomRule {
  static let id = "legacy_random"
  static let name = "Legacy Random"
  static let summary = "Prefer using `type.random(in:)` over legacy functions"
  static var nonTriggeringExamples: [Example] {
    [
      Example("Int.random(in: 0..<10)"),
      Example("Double.random(in: 8.6...111.34)"),
      Example("Float.random(in: 0 ..< 1)"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("↓arc4random()"),
      Example("↓arc4random_uniform(83)"),
      Example("↓drand48()"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension LegacyRandomRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LegacyRandomRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private static let legacyRandomFunctions: Set<String> = [
      "arc4random",
      "arc4random_uniform",
      "drand48",
    ]

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let function = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
        Self.legacyRandomFunctions.contains(function)
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
