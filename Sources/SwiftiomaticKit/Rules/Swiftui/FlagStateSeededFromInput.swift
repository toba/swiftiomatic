import SwiftSyntax

/// Flag a view initializer that seeds `@State` from one of its parameters.
///
/// SwiftUI creates the state storage once, for the first value of the view's identity. When the
/// parent later passes a new value for the same view, the initializer runs again but the state
/// keeps its first value. The seed is correct only when each new input also gives the view a new
/// identity, for example a sheet that opens on a fresh presentation.
///
/// Lint: An initializer of a view type assigns `State(initialValue:)` or `State(wrappedValue:)` ,
/// built from a parameter of the initializer, to a `_name` storage property, or assigns a value
/// built from a parameter directly to a `@State` property, as in `name = input.value` .
final class FlagStateSeededFromInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body, let entry = context.viewEntry(forMember: node) else {
            return .skipChildren
        }
        let parameters = Set(
            node.signature.parameterClause.parameters.map { ($0.secondName ?? $0.firstName).text }
        )

        for statement in body.statements {
            guard let assignment = statement.item.as(ExprSyntax.self)?
                .as(InfixOperatorExprSyntax.self),
                assignment.operator.is(AssignmentExprSyntax.self),
                let seeded = Self.stateSeed(of: assignment, in: entry),
                let input = Self.firstParameter(in: seeded.seed, from: parameters)
            else { continue }
            diagnose(.seededState(seeded.state, input), on: assignment)
        }
        return .skipChildren
    }

    /// The state name and seed expression when `assignment` initializes `@State` storage
    ///
    /// Two forms seed the state: `_name = State(initialValue: seed)` and a plain `name = seed`
    /// or `self.name = seed` to a property that carries `@State` .
    private static func stateSeed(
        of assignment: InfixOperatorExprSyntax,
        in entry: TypeMemberIndex.TypeEntry
    ) -> (state: String, seed: ExprSyntax)? {
        if let storage = storageName(assignment.leftOperand) {
            guard let call = assignment.rightOperand.as(FunctionCallExprSyntax.self),
                  call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "State",
                  let seed = call.arguments.first(where: {
                      ["initialValue", "wrappedValue"].contains($0.label?.text)
                  }) else { return nil }
            return (String(storage.dropFirst()), seed.expression)
        }
        guard let name = assignment.leftOperand.selfMemberReference?.baseName.text,
              entry.isStateProperty(name) else { return nil }
        return (name, assignment.rightOperand)
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
