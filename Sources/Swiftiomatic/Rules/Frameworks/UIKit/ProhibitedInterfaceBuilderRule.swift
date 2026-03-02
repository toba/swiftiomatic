import SwiftSyntax

struct ProhibitedInterfaceBuilderRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ProhibitedInterfaceBuilderConfiguration()
}

extension ProhibitedInterfaceBuilderRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ProhibitedInterfaceBuilderRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      if node.isIBOutlet {
        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.isIBAction {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
