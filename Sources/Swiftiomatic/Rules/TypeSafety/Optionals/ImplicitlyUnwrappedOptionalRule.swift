import SwiftSyntax

struct ImplicitlyUnwrappedOptionalRule {
  var options = ImplicitlyUnwrappedOptionalOptions()

  static let configuration = ImplicitlyUnwrappedOptionalConfiguration()
}

extension ImplicitlyUnwrappedOptionalRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ImplicitlyUnwrappedOptionalRule {}

extension ImplicitlyUnwrappedOptionalRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
      switch configuration.mode {
      case .all:
        return .visitChildren
      case .allExceptIBOutlets:
        return node.isIBOutlet ? .skipChildren : .visitChildren
      case .weakExceptIBOutlets:
        return (node.isIBOutlet || node.weakOrUnownedModifier == nil)
          ? .skipChildren : .visitChildren
      }
    }
  }
}
