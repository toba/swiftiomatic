import SwiftSyntax

/// Flag a stored property that holds an `Unsafe*Pointer` into memory the type does not own.
///
/// A pointer in a parameter lives for the call. A pointer in a property lives for the whole
/// instance, so the type can outlive the memory it points at and nothing in the signature says
/// otherwise. `Span` and `RawSpan` carry that dependency in the type system: store a span, mark the
/// type `~Escapable`, and annotate `init` with `@_lifetime(borrow source)`, and the compiler
/// rejects the escape it cannot see today.
///
/// The rule stays quiet on a type that owns its memory, which it reads as a `deinit` that calls
/// `deallocate()`. It also stays quiet on a computed property, a parameter and a local variable,
/// because none of them outlives the call that made the pointer.
///
/// Lint: A stored property whose type is one of the eight `Unsafe*Pointer` types raises a warning,
/// unless the enclosing type deallocates in `deinit`.
final class UseSpanForStoredPointer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    /// The safe replacement for each unsafe pointer type. Mutability and rawness both carry over.
    private static let replacements: [String: String] = [
        "UnsafePointer": "Span",
        "UnsafeBufferPointer": "Span",
        "UnsafeMutablePointer": "MutableSpan",
        "UnsafeMutableBufferPointer": "MutableSpan",
        "UnsafeRawPointer": "RawSpan",
        "UnsafeRawBufferPointer": "RawSpan",
        "UnsafeMutableRawPointer": "MutableRawSpan",
        "UnsafeMutableRawBufferPointer": "MutableRawSpan",
    ]

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let members = enclosingMemberBlock(of: node) else { return .visitChildren }
        guard !deallocatesInDeinit(members) else { return .visitChildren }

        for binding in node.bindings where isStoredBinding(binding) {
            guard let annotation = binding.typeAnnotation else { continue }
            let type = unwrap(annotation.type)
            guard let name = type.as(IdentifierTypeSyntax.self)?.name.text,
                  let span = Self.replacements[name] else { continue }

            diagnose(.useSpanForStoredPointer(pointer: name, span: span), on: type)
        }
        return .visitChildren
    }

    /// The member block this declaration belongs to, or `nil` when it is not a type member.
    ///
    /// A local variable sits under a code block and a parameter is a different node, so both miss
    /// this check. Matching on the member block rather than on the parent type declaration keeps a
    /// nested declaration out of the result.
    private func enclosingMemberBlock(of node: VariableDeclSyntax) -> MemberBlockSyntax? {
        node.parent?.as(MemberBlockItemSyntax.self)?
            .parent?.as(MemberBlockItemListSyntax.self)?
            .parent?.as(MemberBlockSyntax.self)
    }

    /// Whether the type frees its own memory, which makes the stored pointer an owned allocation.
    private func deallocatesInDeinit(_ members: MemberBlockSyntax) -> Bool {
        for member in members.members {
            guard let deinitializer = member.decl.as(DeinitializerDeclSyntax.self),
                let body = deinitializer.body else { continue }

            let finder = DeallocateCallFinder()
            finder.walk(body)
            if finder.found { return true }
        }
        return false
    }

    /// The type under any optional or attributed wrapper. A stored optional pointer carries the
    /// same hazard as a stored pointer.
    private func unwrap(_ type: TypeSyntax) -> TypeSyntax {
        if let optional = type.as(OptionalTypeSyntax.self) { return unwrap(optional.wrappedType) }
        if let implicit = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return unwrap(implicit.wrappedType)
        }
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return unwrap(attributed.baseType)
        }
        return type
    }

    private func isStoredBinding(_ binding: PatternBindingSyntax) -> Bool {
        guard let accessorBlock = binding.accessorBlock else { return true }

        switch accessorBlock.accessors {
            case .getter: return false
            case let .accessors(list):
                // willSet and didSet observe storage, so the property is still stored
                for accessor in list {
                    switch accessor.accessorSpecifier.tokenKind {
                        case .keyword(.get),
                             .keyword(.set),
                             .keyword(._read),
                             .keyword(._modify),
                             .keyword(.unsafeAddress),
                             .keyword(.unsafeMutableAddress): return false
                        default: continue
                    }
                }
                return true
        }
    }
}

/// Reports whether a body calls `deallocate()` , through a member access or on its own.
private final class DeallocateCallFinder: SyntaxVisitor {
    private(set) var found = false

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard !found else { return .skipChildren }

        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "deallocate"
        {
            found = true
        } else if let reference = node.calledExpression.as(DeclReferenceExprSyntax.self),
            reference.baseName.text == "deallocate" { found = true }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func useSpanForStoredPointer(pointer: String, span: String) -> Finding.Message {
        """
        a stored '\(pointer)' outlives nothing the compiler can see — store a '\(span)', mark the \
        type '~Escapable', and annotate 'init' with '@_lifetime(borrow source)'
        """
    }
}
