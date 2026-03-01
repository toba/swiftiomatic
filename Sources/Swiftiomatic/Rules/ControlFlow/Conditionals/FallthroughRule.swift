import SwiftSyntax

struct FallthroughRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = FallthroughConfiguration()

  static let description = RuleDescription(
    identifier: "fallthrough",
    name: "Fallthrough",
    description: "Fallthrough should be avoided",
    isOptIn: true,
    nonTriggeringExamples: [
      Example(
        """
        switch foo {
        case .bar, .bar2, .bar3:
          something()
        }
        """,
      )
    ],
    triggeringExamples: [
      Example(
        """
        switch foo {
        case .bar:
          ↓fallthrough
        case .bar2:
          something()
        }
        """,
      )
    ],
  )
}

extension FallthroughRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FallthroughRule {}

extension FallthroughRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FallThroughStmtSyntax) {
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
