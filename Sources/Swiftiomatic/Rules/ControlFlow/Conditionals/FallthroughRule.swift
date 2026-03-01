import SwiftSyntax

struct FallthroughRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "fallthrough",
    name: "Fallthrough",
    description: "Fallthrough should be avoided",
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
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension FallthroughRule: OptInRule {}

extension FallthroughRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: FallThroughStmtSyntax) {
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
