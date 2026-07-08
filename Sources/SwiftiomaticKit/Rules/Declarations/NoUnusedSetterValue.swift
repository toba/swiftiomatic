import SwiftSyntax

/// A computed-property or subscript setter that never reads its parameter ( `newValue` by default,
/// or the bound name in `set(custom)` ) is almost always wrong — the assignment to the underlying
/// storage uses some other expression, leaving the actual incoming value silently dropped.
///
/// Exception: empty setters, e.g. `set {}` , are intentional no-ops — an `override` suppressing the
/// parent class's setter, or a protocol-extension default that must supply a settable requirement
/// for conformers to override. Nothing is assigned, so there is nothing to get wrong.
///
/// Lint: When a `set` accessor's body never references its parameter name, a warning is raised.
final class NoUnusedSetterValue: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var defaultValue: LintOnlyValue { .init(lint: .error) }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.accessorSpecifier.tokenKind == .keyword(.set) else { return .visitChildren }
        guard let body = node.body else { return .visitChildren }

        let parameterName = node.parameters?.name.text ?? "newValue"
        let visitor = NewValueUsageVisitor(name: parameterName, viewMode: .sourceAccurate)
        visitor.walk(body)
        guard !visitor.wasUsed else { return .visitChildren }

        // An empty setter body is an explicit no-op, not a value silently dropped into the wrong
        // storage. This covers `override` setters that suppress a parent's, and protocol-extension
        // default implementations that must provide a settable requirement for conformers to
        // override. Nothing is being assigned, so there is nothing to get wrong.
        if body.statements.isEmpty {
            return .visitChildren
        }

        diagnose(.unusedSetterValue(parameterName), on: node)
        return .visitChildren
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
