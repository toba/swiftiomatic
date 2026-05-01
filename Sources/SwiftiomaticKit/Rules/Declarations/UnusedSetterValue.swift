import SwiftSyntax

/// A computed-property or subscript setter that never reads its parameter ( `newValue` by default,
/// or the bound name in `set(custom)` ) is almost always wrong — the assignment to the underlying
/// storage uses some other expression, leaving the actual incoming value silently dropped.
///
/// Exception: empty `override` setters, e.g. `override var x: T { get { ... } set {} }` , are
/// intentional no-ops to suppress the parent class's setter.
///
/// Lint: When a `set` accessor's body never references its parameter name, a warning is raised.
final class UnusedSetterValue: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.accessorSpecifier.tokenKind == .keyword(.set) else { return .visitChildren }
        guard let body = node.body else { return .visitChildren }

        let parameterName = node.parameters?.name.text ?? "newValue"
        let visitor = NewValueUsageVisitor(name: parameterName, viewMode: .sourceAccurate)
        visitor.walk(body)
        guard !visitor.wasUsed else { return .visitChildren }

        // Empty body in an `override` setter is intentional.
        if body.statements.isEmpty,
           isEnclosingDeclOverride(node)
        {
            return .visitChildren
        }

        diagnose(.unusedSetterValue(parameterName), on: node)
        return .visitChildren
    }

    private func isEnclosingDeclOverride(_ node: AccessorDeclSyntax) -> Bool {
        var current: Syntax? = Syntax(node).parent

        while let curr = current {
            if let varDecl = curr.as(VariableDeclSyntax.self) {
                return varDecl.modifiers.contains(where: {
                    $0.name.tokenKind == .keyword(.override)
                })
            }
            if let subscriptDecl = curr.as(SubscriptDeclSyntax.self) {
                return subscriptDecl.modifiers.contains(where: {
                    $0.name.tokenKind == .keyword(.override)
                })
            }
            current = curr.parent
        }
        return false
    }
}

private final class NewValueUsageVisitor: SyntaxVisitor {
    let name: String
    var wasUsed = false

    init(name: String, viewMode: SyntaxTreeViewMode) {
        self.name = name
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if node.baseName.text == name {
            wasUsed = true
            return .skipChildren
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func unusedSetterValue(_ name: String) -> Finding.Message {
        "the setter parameter (\(name)) is never used"
    }
}
