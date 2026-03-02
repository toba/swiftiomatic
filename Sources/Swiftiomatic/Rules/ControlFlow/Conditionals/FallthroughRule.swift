import SwiftSyntax

struct FallthroughRule {
    static let id = "fallthrough"
    static let name = "Fallthrough"
    static let summary = "Fallthrough should be avoided"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                switch foo {
                case .bar, .bar2, .bar3:
                  something()
                }
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
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
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
