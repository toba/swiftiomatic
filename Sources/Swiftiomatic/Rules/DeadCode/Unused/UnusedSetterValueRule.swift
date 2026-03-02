import SwiftSyntax

struct UnusedSetterValueRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = UnusedSetterValueConfiguration()
}

extension UnusedSetterValueRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnusedSetterValueRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      [ProtocolDeclSyntax.self]
    }

    override func visitPost(_ node: AccessorDeclSyntax) {
      guard node.accessorSpecifier.tokenKind == .keyword(.set) else {
        return
      }

      let variableName = node.parameters?.name.text ?? "newValue"
      let visitor = NewValueUsageVisitor(variableName: variableName)
      if !visitor.walk(tree: node, handler: \.isVariableUsed) {
        if Syntax(node).closestVariableOrSubscript()?.modifiers
          .contains(keyword: .override)
          == true,
          let body = node.body, body.statements.isEmpty
        {
          return
        }

        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

private final class NewValueUsageVisitor: SyntaxVisitor {
  let variableName: String
  private(set) var isVariableUsed = false

  init(variableName: String) {
    self.variableName = variableName
    super.init(viewMode: .sourceAccurate)
  }

  override func visitPost(_ node: DeclReferenceExprSyntax) {
    if node.baseName.text == variableName {
      isVariableUsed = true
    }
  }
}

extension Syntax {
  fileprivate func closestVariableOrSubscript() -> (any WithModifiersSyntax)? {
    if let subscriptDecl = `as`(SubscriptDeclSyntax.self) {
      return subscriptDecl
    }
    if let variableDecl = `as`(VariableDeclSyntax.self) {
      return variableDecl
    }

    return parent?.closestVariableOrSubscript()
  }
}
