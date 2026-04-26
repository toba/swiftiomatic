import SwiftSyntax

/// Prefer `Self` over `type(of: self)`.
///
/// Inside a class/struct/enum/actor, `Self` refers to the current type and is fully equivalent to
/// `type(of: self)` for any non-polymorphic dispatch. The shorthand is more concise and avoids
/// the runtime call.
///
/// This rule does not fire at the top level of a file (where `self` does not refer to an enclosing
/// type) or for non-`self` arguments (`type(of: param)` is preserved).
///
/// Lint: A warning is raised for `type(of: self)` (also `Swift.type(of: self)`) inside a type.
///
/// Rewrite: The call is replaced with `Self`.
final class PreferSelfType: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: true, lint: .warn) }

    private var typeContextDepth = 0

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        typeContextDepth += 1
        defer { typeContextDepth -= 1 }
        return super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        typeContextDepth += 1
        defer { typeContextDepth -= 1 }
        return super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        typeContextDepth += 1
        defer { typeContextDepth -= 1 }
        return super.visit(node)
    }

    override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
        typeContextDepth += 1
        defer { typeContextDepth -= 1 }
        return super.visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        typeContextDepth += 1
        defer { typeContextDepth -= 1 }
        return super.visit(node)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard typeContextDepth > 0,
            let memberAccess = visited.as(MemberAccessExprSyntax.self),
            let baseCall = memberAccess.base?.as(FunctionCallExprSyntax.self),
            isTypeOfSelfCall(baseCall)
        else { return visited }

        diagnose(.preferSelfType, on: baseCall)

        let selfRef = DeclReferenceExprSyntax(baseName: .keyword(.Self))
            .with(\.leadingTrivia, baseCall.leadingTrivia)
            .with(\.trailingTrivia, baseCall.trailingTrivia)
        return ExprSyntax(memberAccess.with(\.base, ExprSyntax(selfRef)))
    }

    private func isTypeOfSelfCall(_ call: FunctionCallExprSyntax) -> Bool {
        guard call.arguments.count == 1,
            let firstArg = call.arguments.first,
            firstArg.label?.text == "of",
            firstArg.expression.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
                == .keyword(.self)
        else { return false }

        if let identifier = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            return identifier.baseName.text == "type"
        }
        if let memberAccess = call.calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text == "type"
                && memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Swift"
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let preferSelfType: Finding.Message =
        "prefer 'Self' over 'type(of: self)'"
}
