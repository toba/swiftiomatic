import SwiftSyntax

struct ForceCastRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = ForceCastConfiguration()
}

extension ForceCastRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
