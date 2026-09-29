import SwiftSyntax

/// Flag a stored `ModelContext` property in an actor or in a `Sendable` type.
///
/// `ModelContext` is not `Sendable` . A context belongs to one thread or one actor. An actor or a
/// `Sendable` type that stores a context lets other threads reach it, which is a data race.
/// `@unchecked Sendable` hides the error but not the race. Store the `ModelContainer` , which is
/// `Sendable` , and create a `ModelContext` in the code that uses it. Use `@ModelActor` for an
/// actor that works with SwiftData.
///
/// The rule checks an `actor` , and a struct or class that declares `Sendable` or
/// `@unchecked Sendable` in its declaration or in an extension in the same file. It reports a
/// stored property whose type is `ModelContext` , `ModelContext?` or `ModelContext!` , or whose
/// initial value is a `ModelContext(...)` call. It does not report a computed property.
///
/// Lint: An actor or a `Sendable` type has a stored `ModelContext` property.
final class NoModelContextInSendable: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .mustNot }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        check(node.memberBlock, typeName: node.name.text)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if isSendable(node.name.text, around: node) {
            check(node.memberBlock, typeName: node.name.text)
        }
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if isSendable(node.name.text, around: node) {
            check(node.memberBlock, typeName: node.name.text)
        }
        return .visitChildren
    }

    /// Whether the type `name` or a same-file extension of it declares `Sendable` , with or
    /// without `@unchecked`
    private func isSendable(_ name: String, around node: some SyntaxProtocol) -> Bool {
        context.typeMembers(around: node).types[name]?.conformances.contains("Sendable") == true
    }

    private func check(_ members: MemberBlockSyntax, typeName: String) {
        for item in members.members {
            guard let variable = item.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in variable.bindings where Self.isStoredContext(binding) {
                let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    ?? binding.pattern.trimmedDescription
                diagnose(.contextInSendable(name, typeName), on: binding.pattern)
            }
        }
    }

    /// Whether `binding` is a stored property of type `ModelContext` or with a `ModelContext(...)`
    /// initial value
    private static func isStoredContext(_ binding: PatternBindingSyntax) -> Bool {
        if let accessors = binding.accessorBlock {
            guard case let .accessors(list) = accessors.accessors,
                  list.allSatisfy({
                      $0.accessorSpecifier.tokenKind == .keyword(.willSet)
                          || $0.accessorSpecifier.tokenKind == .keyword(.didSet)
                  }) else { return false }
        }
        if let type = binding.typeAnnotation?.type { return isModelContext(type) }

        guard let call = binding.initializer?.value.as(FunctionCallExprSyntax.self),
              let callee = call.calledExpression.as(DeclReferenceExprSyntax.self) else {
            return false
        }
        return callee.baseName.text == "ModelContext"
    }

    private static func isModelContext(_ type: TypeSyntax) -> Bool {
        var type = type

        if let optional = type.as(OptionalTypeSyntax.self) {
            type = optional.wrappedType
        } else if let unwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            type = unwrapped.wrappedType
        }
        if let ident = type.as(IdentifierTypeSyntax.self) {
            return ident.name.text == "ModelContext"
        }
        if let member = type.as(MemberTypeSyntax.self) {
            return member.name.text == "ModelContext"
                && member.baseType.as(IdentifierTypeSyntax.self)?.name.text == "SwiftData"
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static func contextInSendable(_ property: String, _ type: String) -> Finding.Message {
        "'\(property)' stores a 'ModelContext' in the Sendable type '\(type)'; store the 'ModelContainer' and create a context where you use it"
    }
}
