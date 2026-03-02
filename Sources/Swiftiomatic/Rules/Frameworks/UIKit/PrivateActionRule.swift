import SwiftSyntax

struct PrivateActionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PrivateActionConfiguration()
}

extension PrivateActionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PrivateActionRule {}

extension PrivateActionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
      node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
      guard node.isIBAction, !node.modifiers.containsPrivateOrFileprivate() else {
        return
      }

      violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
