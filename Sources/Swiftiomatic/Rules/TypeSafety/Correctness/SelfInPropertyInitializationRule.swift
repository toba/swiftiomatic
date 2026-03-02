import SwiftSyntax

struct SelfInPropertyInitializationRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SelfInPropertyInitializationConfiguration()
}

extension SelfInPropertyInitializationRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SelfInPropertyInitializationRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard !node.modifiers.contains(keyword: .lazy),
        !node.modifiers.containsStaticOrClass,
        let closestDecl = node.closestDecl(),
        closestDecl.is(ClassDeclSyntax.self)
      else {
        return
      }

      let visitor = IdentifierUsageVisitor(viewMode: .sourceAccurate)
      for binding in node.bindings {
        guard let initializer = binding.initializer,
          visitor.walk(tree: initializer.value, handler: \.isTokenUsed)
        else {
          continue
        }

        violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

private final class IdentifierUsageVisitor: SyntaxVisitor {
  private(set) var isTokenUsed = false

  override func visitPost(_ node: DeclReferenceExprSyntax) {
    if node.baseName.tokenKind == .keyword(.self),
      node.keyPathInParent != \MemberAccessExprSyntax.declName,
      node.keyPathInParent != \KeyPathPropertyComponentSyntax.declName
    {
      isTokenUsed = true
    }
  }
}

extension SyntaxProtocol {
  fileprivate func closestDecl() -> DeclSyntax? {
    if let decl = parent?.as(DeclSyntax.self) {
      return decl
    }

    return parent?.closestDecl()
  }
}
