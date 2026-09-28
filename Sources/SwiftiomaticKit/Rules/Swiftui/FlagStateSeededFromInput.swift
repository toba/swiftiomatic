import SwiftSyntax

/// Flag a view initializer that seeds `@State` or `@StateObject` from one of its parameters.
///
/// SwiftUI creates the state storage once, for the first value of the view's identity. When the
/// parent later passes a new value for the same view, the initializer runs again but the state
/// keeps its first value. SwiftUI discards the new value or model. This applies to
/// `_name = State(initialValue:)`, to `State(wrappedValue:)`, to `StateObject(wrappedValue:)` and
/// to `self.name = input`.
///
/// Give the state a default value in its declaration, remove the seed from the initializer, and
/// keep the state in step with the input in a modifier keyed by that input:
///
/// - For a short synchronous copy, use `onChange(of:initial:)` with `initial: true`. Without
///   `initial: true`, the action does not run when the view appears, so the first value does not
///   arrive.
/// - For work that is asynchronous, such as a load for an identifier, use `task(id:)`. Skip the
///   load when the state already holds the value for the same id, so that a new run does not
///   overwrite local edits. Check `Task.isCancelled` before you write the result, so that a load
///   for an earlier id does not replace the current value.
///
/// ```swift
/// @State private var draft = ""
///
/// TextField("Title", text: $draft)
///     .onChange(of: original, initial: true) { _, newValue in draft = newValue }
/// ```
///
/// The seed is correct when each new input also gives the view a new identity, for example a sheet
/// that opens on a fresh presentation. Suppress the finding there. An input whose label or name
/// starts with `initial`, such as `initiallyExpanded`, states that the copy is initial only. The
/// rule does not flag it.
///
/// Lint: An initializer of a view type assigns `State(initialValue:)` , `State(wrappedValue:)` or
/// `StateObject(wrappedValue:)` , built from a parameter of the initializer, to a `_name` storage
/// property, or assigns a value built from a parameter directly to a `@State` property, as in
/// `name = input.value` . The rule reports the assignment, the seeded property declaration, and the
/// view type that owns it.
final class FlagStateSeededFromInput: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .shouldNot }

    /// The declarations and type names this rule already reported in the file, so that two
    /// initializers that seed the same property report it once
    private var reported: Set<SyntaxIdentifier> = []

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body, let entry = context.viewEntry(forMember: node)
        else { return .skipChildren }
        let parameters = Set(
            node.signature.parameterClause.parameters
                .filter { !Self.isInitialOnly($0) }
                .map { ($0.secondName ?? $0.firstName).text }
        )

        for statement in body.statements {
            guard let assignment = statement.item.as(ExprSyntax.self)?
                .as(InfixOperatorExprSyntax.self),
                  assignment.operator.is(AssignmentExprSyntax.self),
                  let seeded = Self.stateSeed(of: assignment, in: entry),
                  let input = Self.firstParameter(in: seeded.seed, from: parameters)
            else { continue }
            diagnose(.seededState(seeded.state, input, wrapper: seeded.wrapper), on: assignment)
            reportOwner(of: node)
            reportDeclaration(of: seeded.state, input: input, in: entry)
        }
        return .skipChildren
    }

    /// Whether the label or the name of `parameter` marks it as an initial-only value
    private static func isInitialOnly(_ parameter: FunctionParameterSyntax) -> Bool {
        [parameter.firstName, parameter.secondName].contains {
            $0?.text.hasPrefix("initial") == true
        }
    }

    /// Reports the view type that holds `initializer` , once per type
    ///
    /// An initializer in an extension reports the type declaration of the same name in the file.
    private func reportOwner(of initializer: InitializerDeclSyntax) {
        guard let owner = TypeMemberIndex.owningDeclaration(of: initializer),
              let name = TypeMemberIndex.typeNameToken(of: owner),
              reported.insert(name.id).inserted else { return }
        diagnose(.ownerSeedsState(name.text), on: name)
    }

    /// Reports the `@State` or `@StateObject` declaration of `state` , once per declaration
    private func reportDeclaration(
        of state: String,
        input: String,
        in entry: TypeMemberIndex.TypeEntry
    ) {
        for member in entry.members[state] ?? [] where member.kind == .storedProperty {
            guard let variable = member.declaration.as(VariableDeclSyntax.self),
                let wrapper = Self.stateWrappers.first(where: {
                    variable.attributes.attribute(named: $0) != nil
                }),
                reported.insert(variable.id).inserted else { continue }
            diagnose(.seededDeclaration(state, input, wrapper: wrapper), on: variable)
        }
    }

    /// The wrappers whose storage keeps its first value for the life of the view identity
    private static let stateWrappers = ["State", "StateObject"]

    /// The state name and seed expression when `assignment` initializes `@State` storage
    ///
    /// Two forms seed the state: `_name = State(initialValue: seed)` , or the same with
    /// `StateObject(wrappedValue:)` , and a plain `name = seed` or `self.name = seed` to a property
    /// that carries `@State` .
    private static func stateSeed(
        of assignment: InfixOperatorExprSyntax,
        in entry: TypeMemberIndex.TypeEntry
    ) -> (state: String, seed: ExprSyntax, wrapper: String)? {
        if let storage = storageName(assignment.leftOperand) {
            guard let call = assignment.rightOperand.as(FunctionCallExprSyntax.self),
                let wrapper = call.calledExpression.as(DeclReferenceExprSyntax.self)?
                    .baseName.text,
                stateWrappers.contains(wrapper),
                let seed = call.arguments.first(where: {
                    ["initialValue", "wrappedValue"].contains($0.label?.text)
                }) else { return nil }
            return (String(storage.dropFirst()), seed.expression, wrapper)
        }
        guard let name = assignment.leftOperand.selfMemberReference?.baseName.text,
              entry.isStateProperty(name) else { return nil }
        return (name, assignment.rightOperand, "State")
    }

    /// The `_name` a `_name` or `self._name` target names
    private static func storageName(_ target: ExprSyntax) -> String? {
        guard let name = target.selfMemberReference?.baseName.text,
              name.hasPrefix("_"),
              name.count > 1 else { return nil }
        return name
    }

    /// The first initializer parameter that `expression` reads, in source order
    private static func firstParameter(
        in expression: ExprSyntax,
        from parameters: Set<String>
    ) -> String? {
        expression.tokens(viewMode: .sourceAccurate).first {
            guard case .identifier = $0.tokenKind, parameters.contains($0.text)
            else { return false }
            // `x.seed` names a member, not the parameter `seed`
            return $0.parent?.parent?.as(MemberAccessExprSyntax.self)?.declName.baseName.id != $0.id
        }?.text
    }
}

fileprivate extension Finding.Message {
    static func seededState(_ state: String, _ input: String, wrapper: String) -> Finding.Message {
        "'\(state)' seeds '@\(wrapper)' from the input '\(input)'. The state keeps its first value when the parent passes a new one. Give each new input a new view identity, or keep the value in the parent"
    }

    static func seededDeclaration(
        _ state: String,
        _ input: String,
        wrapper: String
    ) -> Finding.Message {
        "'@\(wrapper)' property '\(state)' takes its first value from the initializer input '\(input)'. A later value of the input does not reach it. Update it in 'onChange(of:initial: true)' or 'task(id:)', or name the input as initial only"
    }

    static func ownerSeedsState(_ owner: String) -> Finding.Message {
        "'\(owner)' seeds view state from initializer inputs. That state does not follow later input values"
    }
}
