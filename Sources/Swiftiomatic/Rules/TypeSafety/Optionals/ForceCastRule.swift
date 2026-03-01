import SwiftSyntax

struct ForceCastRule {
  var configuration = SeverityConfiguration<Self>(.error)

  static let description = RuleDescription(
    identifier: "force_cast",
    name: "Force Cast",
    description: "Force casts should be avoided",
    nonTriggeringExamples: [
      Example("NSNumber() as? Int")
    ],
    triggeringExamples: [Example("NSNumber() ↓as! Int")],
  )
}

extension ForceCastRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ForceCastRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AsExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: UnresolvedAsExprSyntax) {
      if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
        violations.append(node.asKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
