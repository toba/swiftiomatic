import SwiftSyntax

/// Flag a stored property that holds an `Unsafe*Pointer` into memory the type does not own.
///
/// A pointer in a parameter lives for the call. A pointer in a property lives for the whole
/// instance, so the type can outlive the memory it points at and nothing in the signature says
/// otherwise. `Span` and `RawSpan` carry that dependency in the type system: store a span, mark the
/// type `~Escapable`, and annotate `init` with `@_lifetime(borrow source)`, and the compiler
/// rejects the escape it cannot see today.
///
/// The message follows the declaration. A buffer pointer carries its own count, so one span
/// replaces it. A bare pointer carries none, so the message says to pair it with the count beside
/// it. The mutable spans are named only when a member writes through the property, because a
/// pointer that a C API hands back is often mutable in type and read-only in use.
///
/// The rule stays quiet on a type that owns its memory, which it reads as a `deinit` that calls
/// `deallocate()`. It stays quiet on a type whose inheritance clause names a protocol or a
/// superclass, because such a type cannot be `~Escapable`. It also stays quiet on a computed
/// property, a parameter and a local variable, because none of them outlives the call that made the
/// pointer.
///
/// Lint: A stored property whose type is one of the eight `Unsafe*Pointer` types raises a warning,
/// unless the enclosing type deallocates in `deinit` or inherits an escapable type.
final class UseSpanForStoredPointer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    /// The safe replacement for each unsafe pointer type.
    private static let replacements: [String: Replacement] = [
        "UnsafePointer": Replacement(mutable: "Span", readOnly: "Span", carriesCount: false),
        "UnsafeBufferPointer": Replacement(mutable: "Span", readOnly: "Span", carriesCount: true),
        "UnsafeMutablePointer": Replacement(
            mutable: "MutableSpan", readOnly: "Span", carriesCount: false
        ),
        "UnsafeMutableBufferPointer": Replacement(
            mutable: "MutableSpan", readOnly: "Span", carriesCount: true
        ),
        "UnsafeRawPointer": Replacement(
            mutable: "RawSpan", readOnly: "RawSpan", carriesCount: false
        ),
        "UnsafeRawBufferPointer": Replacement(
            mutable: "RawSpan", readOnly: "RawSpan", carriesCount: true
        ),
        "UnsafeMutableRawPointer": Replacement(
            mutable: "MutableRawSpan", readOnly: "RawSpan", carriesCount: false
        ),
        "UnsafeMutableRawBufferPointer": Replacement(
            mutable: "MutableRawSpan", readOnly: "RawSpan", carriesCount: true
        ),
    ]

    /// The span that stands in for one unsafe pointer type, and whether the pointer brings the
    /// count a span needs.
    private struct Replacement {
        let mutable: String
        let readOnly: String
        let carriesCount: Bool
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let members = enclosingMemberBlock(of: node) else { return .visitChildren }
        guard !inheritsEscapableType(members) else { return .visitChildren }
        guard !deallocatesInDeinit(members) else { return .visitChildren }

        for binding in node.bindings where isStoredBinding(binding) {
            guard let annotation = binding.typeAnnotation else { continue }
            let type = unwrap(annotation.type)
            guard let name = type.as(IdentifierTypeSyntax.self)?.name.text,
                  let replacement = Self.replacements[name] else { continue }

            // a tuple or wildcard pattern names no property to trace, so assume the write
            let property = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            let writes = property.map { writesThrough($0, in: members) } ?? true
            let span = writes ? replacement.mutable : replacement.readOnly

            if replacement.carriesCount {
                diagnose(.useSpanForStoredPointer(pointer: name, span: span), on: type)
            } else {
                diagnose(.useSpanForStoredBarePointer(pointer: name, span: span), on: type)
            }
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

    /// Whether the enclosing type names a protocol or a superclass it inherits.
    ///
    /// A protocol requirement carries an implicit Escapable constraint, so a conforming type cannot
    /// be ~Escapable, and one file cannot say whether the protocol suppresses it. The advice this
    /// rule gives is unreachable there. A suppressed conformance such as ~Copyable is not an
    /// inherited type, so it leaves the rule active.
    private func inheritsEscapableType(_ members: MemberBlockSyntax) -> Bool {
        guard let clause = members.parent?.asProtocol(DeclGroupSyntax.self)?.inheritanceClause
        else { return false }

        return clause.inheritedTypes.contains { !$0.type.is(SuppressedTypeSyntax.self) }
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

    /// Whether any member stores into the memory the property addresses.
    private func writesThrough(_ property: String, in members: MemberBlockSyntax) -> Bool {
        let finder = PointerWriteFinder(property: property)
        finder.walk(members)
        return finder.found
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

/// Reports whether a type writes through one stored pointer property, rather than only reading it.
///
/// A write is an assignment into memory behind the property, a mutating pointer call on it, or an
/// `inout` argument taken from behind it. An assignment to the property itself replaces the pointer
/// and reaches no memory, so it does not count.
private final class PointerWriteFinder: SyntaxVisitor {
    /// Pointer members that store into the memory the pointer addresses.
    private static let mutatingMembers: Set<String> = [
        "assign", "copyMemory", "deinitialize", "deinitializeElement", "initialize",
        "initializeElement", "initializeMemory", "moveAssign", "moveInitialize",
        "moveInitializeMemory", "moveUpdate", "reverse", "shuffle", "sort", "storeBytes", "swapAt",
        "update", "updateElement",
    ]

    /// Operators that end in an equals sign and store nothing.
    private static let comparisons: Set<String> = ["==", "!=", "<=", ">=", "~=", "===", "!=="]

    private let property: String
    private(set) var found = false

    init(property: String) {
        self.property = property
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard !found, isAssignment(node.operator) else { return .visitChildren }

        if let depth = indirection(of: node.leftOperand), depth > 0 { found = true }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard !found,
              let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              Self.mutatingMembers.contains(member.declName.baseName.text),
              let base = member.base,
              indirection(of: base) != nil else { return .visitChildren }

        found = true
        return .visitChildren
    }

    override func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
        guard !found else { return .visitChildren }

        if let depth = indirection(of: node.expression), depth > 0 { found = true }
        return .visitChildren
    }

    /// The count of member accesses and subscripts between the expression and the stored property
    /// it reaches, or `nil` when it reaches something else. Zero names the property, and a larger
    /// count names memory behind it.
    private func indirection(of expression: ExprSyntax) -> Int? {
        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text == property ? 0 : nil
        }
        if let member = expression.as(MemberAccessExprSyntax.self) {
            guard let base = member.base else { return nil }
            guard base.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
            else {
                return indirection(of: base).map { $0 + 1 }
            }
            return member.declName.baseName.text == property ? 0 : nil
        }
        if let call = expression.as(SubscriptCallExprSyntax.self) {
            return indirection(of: call.calledExpression).map { $0 + 1 }
        }
        if let optional = expression.as(OptionalChainingExprSyntax.self) {
            return indirection(of: optional.expression)
        }
        if let forced = expression.as(ForceUnwrapExprSyntax.self) {
            return indirection(of: forced.expression)
        }
        if let tuple = expression.as(TupleExprSyntax.self),
           tuple.elements.count == 1,
           let only = tuple.elements.first { return indirection(of: only.expression) }
        return nil
    }

    /// Whether the operator stores into its left operand. A plain equals sign is its own node, and
    /// a compound assignment such as `+=` is a binary operator whose text ends with one.
    private func isAssignment(_ operatorExpr: ExprSyntax) -> Bool {
        if operatorExpr.is(AssignmentExprSyntax.self) { return true }
        guard let binary = operatorExpr.as(BinaryOperatorExprSyntax.self) else { return false }

        let text = binary.operator.text
        return text.hasSuffix("=") && !Self.comparisons.contains(text)
    }
}

fileprivate extension Finding.Message {
    static func useSpanForStoredPointer(pointer: String, span: String) -> Finding.Message {
        """
        a stored '\(pointer)' outlives nothing the compiler can see — store a '\(span)', mark the \
        type '~Escapable', and annotate 'init' with '@_lifetime(borrow source)'
        """
    }

    static func useSpanForStoredBarePointer(pointer: String, span: String) -> Finding.Message {
        """
        a stored '\(pointer)' outlives nothing the compiler can see, and it carries no count — \
        pair it with its count in one '\(span)', mark the type '~Escapable', and annotate 'init' \
        with '@_lifetime(borrow source)'
        """
    }
}
