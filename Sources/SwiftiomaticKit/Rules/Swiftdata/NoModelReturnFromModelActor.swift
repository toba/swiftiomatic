import SwiftSyntax

/// Flag a `@ModelActor` method that returns a `@Model` object or an array of them.
///
/// A `@Model` object belongs to the `ModelContext` that fetched it, and that context runs on the
/// executor of the `@ModelActor` . A model that the actor returns to its caller leaves that
/// executor. The caller then reads the model from another thread, which is a data race. Return
/// `PersistentIdentifier` values, and fetch the models again in the context of the caller. Or return
/// `Sendable` copies of the data.
///
/// The rule checks the methods that an `@ModelActor actor` declares in its body. It reports a return
/// type `T` , `T?` , `[T]` , `[T]?` or `Array<T>` when `T` names a class with `@Model` in the same
/// file or in another file of the project. It does not report a `private` or `fileprivate` method,
/// because the caller of such a method runs on the actor.
///
/// Lint: A method of an `@ModelActor actor` returns a `@Model` type or an array of one.
final class NoModelReturnFromModelActor: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftdata }
    override class var guidance: GuidanceLevel { .mustNot }

    /// The names of the `@Model` classes in the linted file.
    private var localModelNames: Set<String> = []

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = ModelClassCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        localModelNames = collector.names
        return .visitChildren
    }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.attributes.attribute(named: "ModelActor", module: "SwiftData") != nil else {
            return .visitChildren
        }

        for item in node.memberBlock.members {
            guard let function = item.decl.as(FunctionDeclSyntax.self),
                  !function.modifiers.contains(where: {
                      $0.name.tokenKind == .keyword(.private)
                          || $0.name.tokenKind == .keyword(.fileprivate)
                  }),
                  let returnType = function.signature.returnClause?.type,
                  let name = Self.elementName(of: returnType),
                  isModel(name) else { continue }
            diagnose(.modelReturn(function.name.text, name), on: returnType)
        }
        return .visitChildren
    }

    private func isModel(_ name: String) -> Bool {
        localModelNames.contains(name)
            || context.projectLookup?.otherFileDeclaresModel(named: name) == true
    }

    /// The simple name `T` of a type `T` , `T?` , `T!` , `[T]` or `Array<T>` , or `nil`
    private static func elementName(of type: TypeSyntax) -> String? {
        var type = type

        if let optional = type.as(OptionalTypeSyntax.self) {
            type = optional.wrappedType
        } else if let unwrapped = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            type = unwrapped.wrappedType
        }
        if let array = type.as(ArrayTypeSyntax.self) {
            type = array.element
        } else if let ident = type.as(IdentifierTypeSyntax.self), ident.name.text == "Array",
                  let arguments = ident.genericArgumentClause?.arguments,
                  arguments.count == 1,
                  case let .type(element)? = arguments.first?.argument
        {
            type = element
        }
        if let ident = type.as(IdentifierTypeSyntax.self), ident.genericArgumentClause == nil {
            return ident.name.text
        }
        if let member = type.as(MemberTypeSyntax.self), member.genericArgumentClause == nil {
            return member.name.text
        }
        return nil
    }
}

/// Collects the names of the classes with `@Model` in a file.
private final class ModelClassCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributes.attribute(named: "Model", module: "SwiftData") != nil {
            names.insert(node.name.text)
        }
        return .visitChildren
    }

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension Finding.Message {
    static func modelReturn(_ method: String, _ model: String) -> Finding.Message {
        "'\(method)' returns the '@Model' type '\(model)' from a '@ModelActor'; return 'PersistentIdentifier' values or Sendable copies instead"
    }
}
