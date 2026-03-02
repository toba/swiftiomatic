import SwiftSyntax

struct UnusedSetterValueRule {
    static let id = "unused_setter_value"
    static let name = "Unused Setter Value"
    static let summary = "Setter value is not used"
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    set {
                        Persister.shared.aValue = newValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    set {
                        Persister.shared.aValue = newValue
                    }
                    get {
                        return Persister.shared.aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    set(value) {
                        Persister.shared.aValue = value
                    }
                }
                """,
              ),
              Example(
                """
                override var aValue: String {
                 get {
                     return Persister.shared.aValue
                 }
                 set { }
                }
                """,
              ),
              Example(
                """
                protocol Foo {
                    var bar: Bool { get set }
                """, isExcludedFromDocumentation: true,
              ),
              Example(
                """
                override var accessibilityValue: String? {
                    get {
                        let index = Int(self.value)
                        guard steps.indices.contains(index) else { return "" }
                        return ""
                    }
                    set {}
                }
                """, isExcludedFromDocumentation: true,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                    get {
                        return Persister.shared.aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        let newValue = Persister.shared.aValue
                        return newValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set(value) {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
              Example(
                """
                override var aValue: String {
                    get {
                        return Persister.shared.aValue
                    }
                    ↓set {
                        Persister.shared.aValue = aValue
                    }
                }
                """,
              ),
            ]
    }
  var options = SeverityOption<Self>(.warning)

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
