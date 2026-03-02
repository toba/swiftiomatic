import SwiftSyntax

struct UnownedVariableCaptureRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnownedVariableCaptureConfiguration()
}

extension UnownedVariableCaptureRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnownedVariableCaptureRule {}

extension UnownedVariableCaptureRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TokenSyntax) {
      if case .keyword(.unowned) = node.tokenKind,
        node.parent?.is(ClosureCaptureSpecifierSyntax.self) == true
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
