import SwiftSyntax

/// Declare a custom `struct` initializer in an extension so the synthesized memberwise initializer
/// stays available.
///
/// An initializer in the main body of a `struct` suppresses the memberwise initializer. The same
/// initializer in an extension keeps it. The rule flags an initializer that only copies its
/// parameters into stored properties under labels that differ from the memberwise labels. Such an
/// initializer adds a second spelling and removes the first one for no reason.
///
/// The rule stays silent in these cases:
///
/// - The labels match the memberwise labels in order. `UseSynthesizedInit` owns that case.
/// - The initializer validates or normalizes its input. Any statement other than
///   `self.property = parameter` counts as validation or normalization.
/// - The initializer is failable or throws.
/// - The type is `public`, `package` or `open` and a stored property is less visible than the type.
///   The synthesized initializer cannot reach the type's access level, so the explicit initializer
///   must stay.
///
/// Lint: A plain relabeling initializer in the main body of a `struct` raises a warning.
final class UseExtensionInitToKeepMemberwise: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let properties = node.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter(\.isInstanceStoredProperty)

        let typeRank = accessRank(node.modifiers, fallback: 2)

        if typeRank > 2,
           properties.contains(where: { accessRank($0.modifiers, fallback: 2) < typeRank }) {
            return .visitChildren
        }

        let memberwiseLabels = properties.flatMap(\.memberwiseNames)

        for member in node.memberBlock.members {
            guard let initializer = member.decl.as(InitializerDeclSyntax.self),
                initializer.optionalMark == nil,
                initializer.signature.effectSpecifiers?.throwsClause == nil else { continue }

            let parameters = initializer.signature.parameterClause.parameters
            let labels = parameters.map(\.firstName.text)
            guard labels != memberwiseLabels else { continue }
            guard onlyCopiesParameters(initializer, parameters: parameters) else { continue }

            diagnose(.moveInitToExtension, on: initializer.initKeyword)
        }
        return .visitChildren
    }

    /// Reports whether each statement of the body assigns one parameter, unchanged, to one
    /// property.
    private func onlyCopiesParameters(
        _ initializer: InitializerDeclSyntax,
        parameters: FunctionParameterListSyntax
    ) -> Bool {
        guard let body = initializer.body, !body.statements.isEmpty else { return false }
        let names = Set(parameters.map { ($0.secondName ?? $0.firstName).text })

        return body.statements.allSatisfy { statement in
            guard let assignment = statement.item.as(InfixOperatorExprSyntax.self),
                assignment.operator.is(AssignmentExprSyntax.self),
                let value = assignment.rightOperand.as(DeclReferenceExprSyntax.self),
                names.contains(value.baseName.text) else { return false }

            if let member = assignment.leftOperand.as(MemberAccessExprSyntax.self) {
                return member.base?.as(DeclReferenceExprSyntax.self)?.baseName
                    .tokenKind
                    == .keyword(.self)
            }
            return assignment.leftOperand.is(DeclReferenceExprSyntax.self)
        }
    }

    /// The rank of the access level the modifiers state, from 0 for `private` to 4 for `public` and
    /// `open`, or `fallback` when they state none.
    ///
    /// A modifier with a detail, such as `private(set)`, restricts only the setter and is ignored.
    private func accessRank(_ modifiers: DeclModifierListSyntax, fallback: Int) -> Int {
        for modifier in modifiers where modifier.detail == nil {
            switch modifier.name.tokenKind {
                case .keyword(.private): return 0
                case .keyword(.fileprivate): return 1
                case .keyword(.internal): return 2
                case .keyword(.package): return 3
                case .keyword(.public), .keyword(.open): return 4
                default: continue
            }
        }
        return fallback
    }
}

fileprivate extension VariableDeclSyntax {
    /// Whether the declaration stores an instance value, which makes it a candidate for the
    /// memberwise initializer.
    var isInstanceStoredProperty: Bool {
        guard !modifiers.contains(anyOf: [.static, .class, .lazy]) else { return false }
        return bindings.allSatisfy { binding in
            switch binding.accessorBlock?.accessors {
                case nil: true
                case .getter?: false
                case let .accessors(list)?:
                    list.allSatisfy {
                        $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                            || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
                    }
            }
        }
    }

    /// The names this declaration contributes to the memberwise initializer, in order.
    ///
    /// A `let` with an initial value contributes none, because it can never change.
    var memberwiseNames: [String] {
        bindings.compactMap { binding in
            if bindingSpecifier.tokenKind == .keyword(.let), binding.initializer != nil {
                return nil
            }
            return binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
    }
}

fileprivate extension Finding.Message {
    static let moveInitToExtension: Finding.Message =
        "move this initializer to an extension to keep the synthesized memberwise initializer"
}
