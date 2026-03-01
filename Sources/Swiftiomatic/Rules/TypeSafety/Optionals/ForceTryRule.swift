import SwiftSyntax

struct ForceTryRule {
  var configuration = SeverityConfiguration<Self>(.error)

  static let description = RuleDescription(
    identifier: "force_try",
    name: "Force Try",
    description: "Force tries should be avoided",
    nonTriggeringExamples: [
      Example(
        """
        func a() throws {}
        do {
          try a()
        } catch {}
        """,
      )
    ],
    triggeringExamples: [
      Example(
        """
        func a() throws {}
        ↓try! a()
        """,
      )
    ],
  )
}

extension ForceTryRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ForceTryRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TryExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
