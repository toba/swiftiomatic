import SwiftSyntax

/// Flag `weak var` stored properties on classes/actors that are never
/// reassigned (SE-0481). Such properties should be `weak let`.
///
/// A property is considered "never reassigned" when no descendant of the
/// enclosing type's body contains an assignment to its name (either bare or
/// via `self.`). Initial values and assignments inside an initializer of the
/// same type are allowed because `let` permits init-time assignment.
///
/// Lint-only: emitting the finding does not rewrite the declaration.
final class WeakLetForUnreassignedWeakVar: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        check(memberBlock: node.memberBlock)
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        check(memberBlock: node.memberBlock)
        return .visitChildren
    }

    private func check(memberBlock: MemberBlockSyntax) {
        for member in memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var),
                  varDecl.modifiers.contains(.weak),
                  varDecl.bindings.count == 1,
                  let binding = varDecl.bindings.first,
                  binding.accessorBlock == nil,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else {
                continue
            }

            let collector = AssignmentCollector(name: name, viewMode: .sourceAccurate)
            for inner in memberBlock.members {
                if inner.decl.is(InitializerDeclSyntax.self) { continue }
                collector.walk(inner)
            }
            if !collector.found {
                diagnose(.preferWeakLet(name), on: varDecl.bindingSpecifier)
            }
        }
    }
}

private final class AssignmentCollector: SyntaxVisitor {
    let name: String
    var found = false

    init(name: String, viewMode: SyntaxTreeViewMode) {
        self.name = name
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.as(AssignmentExprSyntax.self) != nil else {
            return .visitChildren
        }
        if matches(node.leftOperand) {
            found = true
        }
        return .visitChildren
    }

    private func matches(_ expr: ExprSyntax) -> Bool {
        if let ident = expr.as(DeclReferenceExprSyntax.self) {
            return ident.baseName.text == name
        }
        if let member = expr.as(MemberAccessExprSyntax.self),
           let base = member.base?.as(DeclReferenceExprSyntax.self),
           base.baseName.tokenKind == .keyword(.self),
           member.declName.baseName.text == name
        {
            return true
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static func preferWeakLet(_ name: String) -> Finding.Message {
        "'\(name)' is declared 'weak var' but never reassigned — prefer 'weak let' (SE-0481)"
    }
}
