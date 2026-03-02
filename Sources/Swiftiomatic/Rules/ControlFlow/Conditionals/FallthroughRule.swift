import SwiftSyntax

struct FallthroughRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = FallthroughConfiguration()
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
