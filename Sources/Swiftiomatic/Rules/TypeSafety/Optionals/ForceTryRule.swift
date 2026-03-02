import SwiftSyntax

struct ForceTryRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = ForceTryConfiguration()
}

extension ForceTryRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
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
