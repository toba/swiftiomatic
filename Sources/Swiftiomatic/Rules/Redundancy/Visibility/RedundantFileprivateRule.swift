import SwiftSyntax

struct RedundantFileprivateRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = RedundantFileprivateConfiguration()
}

extension RedundantFileprivateRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension RedundantFileprivateRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: DeclModifierSyntax) {
      guard node.name.tokenKind == .keyword(.fileprivate), node.detail == nil else { return }

      // If this is a top-level (file-scope) declaration, fileprivate == private
      guard let parentDecl = node.parent?.parent else { return }

      // Check if the declaration is at file scope
      if parentDecl.parent?.is(CodeBlockItemListSyntax.self) == true,
        parentDecl.parent?.parent?.is(SourceFileSyntax.self) == true
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
