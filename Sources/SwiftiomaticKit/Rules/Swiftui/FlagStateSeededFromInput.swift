import SwiftSyntax

/// Flag a view initializer that seeds `@State` from one of its parameters.
///
/// SwiftUI creates the state storage once, for the first value of the view's identity. When the
/// parent later passes a new value for the same view, the initializer runs again but the state
/// keeps its first value. The seed is correct only when each new input also gives the view a new
/// identity, for example a sheet that opens on a fresh presentation.
///
/// Lint: An initializer of a view type assigns `State(initialValue:)` or `State(wrappedValue:)` ,
/// built from a parameter of the initializer, to a `_name` storage property.
final class FlagStateSeededFromInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body, context.viewEntry(forMember: node) != nil else {
            return .skipChildren
        }
        let parameters = Set(
            node.signature.parameterClause.parameters.map { ($0.secondName ?? $0.firstName).text }
        )

        for statement in body.statements {
            guard let assignment = statement.item.as(ExprSyntax.self)?
                .as(InfixOperatorExprSyntax.self),
                assignment.operator.is(AssignmentExprSyntax.self),
                let storage = Self.storageName(assignment.leftOperand),
                let call = assignment.rightOperand.as(FunctionCallExprSyntax.self),
                call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "State",
                let seed = call.arguments.first(where: {
                    ["initialValue", "wrappedValue"].contains($0.label?.text)
                }),
                let input = Self.firstParameter(in: seed.expression, from: parameters)
            else { continue }
            diagnose(.seededState(String(storage.dropFirst()), input), on: assignment)
        }
        return .skipChildren
    }

    /// The `_name` a `_name` or `self._name` target names
    private static func storageName(_ target: ExprSyntax) -> String? {
        guard let name = target.selfMemberReference?.baseName.text, name.hasPrefix("_"),
              name.count > 1 else {
            return nil
        }
        return name
    }

    /// The first initializer parameter that `expression` reads, in source order
    private static func firstParameter(in expression: ExprSyntax, from parameters: Set<String>)
        -> String?
    {
        expression.tokens(viewMode: .sourceAccurate).first {
            guard case .identifier = $0.tokenKind, parameters.contains($0.text) else { return false }
            // `x.seed` names a member, not the parameter `seed`
            return $0.parent?.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.id != $0.id
        }?.text
    }
}

fileprivate extension Finding.Message {
    static func seededState(_ state: String, _ input: String) -> Finding.Message {
        "'\(state)' seeds '@State' from the input '\(input)'. The state keeps its first value when the parent passes a new one. Give each new input a new view identity, or keep the value in the parent"
    }
}
