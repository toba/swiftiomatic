import SwiftSyntax

/// Flag a `_read` or `_modify` accessor that only exposes stored storage.
///
/// SE-0507 adds the `borrow` and `mutate` accessors in Swift 6.4. Both expose stored storage
/// without copying it, and neither runs as a coroutine, so neither pays the allocation and the
/// extra calls that `_read` and `_modify` pay. `borrow` also lets the exposed value outlive the
/// call, which a coroutine accessor cannot allow.
///
/// `borrow` and `mutate` replace `get` and `set` rather than joining them, and the compiler refuses
/// a property that declares both pairs. A property that also declares `get` or `set` has no
/// one-line conversion, so the rule leaves it alone.
///
/// The rule fires only when the body is a single `yield` over stored storage. A body that builds a
/// temporary, or that runs code after the `yield` , must stay on the coroutine form. Storage
/// reached through a property wrapper, a subscript, a computed property or a class member has no
/// address to expose, so it must stay on the coroutine form too. The same holds for the `read` and
/// `modify` spellings.
///
/// Flag-only. The rewrite needs the accessor kind and the `&` on a `mutate` return, so it is left
/// to the author.
///
/// Lint: A `_read` or `_modify` accessor whose body is one `yield` over stored storage raises a
/// warning.
final class UseBorrowAccessorNotUnderscoreRead: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        let specifier = node.accessorSpecifier.text
        guard specifier == "_read" || specifier == "_modify" else { return .visitChildren }
        guard let siblings = node.parent?.as(AccessorDeclListSyntax.self),
              !siblings.declaresGetterOrSetter else { return .visitChildren }
        guard let body = node.body,
              let yielded = body.onlyYieldedExpression,
              yielded.isStoredReference else { return .visitChildren }
        guard let scope = node.enclosingTypeScope,
              scope.canExposeStorage,
              scope.storesRoot(of: yielded) else { return .visitChildren }

        diagnose(
            specifier == "_read" ? .useBorrowAccessor : .useMutateAccessor,
            on: node.accessorSpecifier
        )
        return .visitChildren
    }
}

/// The member list a `_read` or `_modify` accessor sits in, and whether that list is a class body.
private struct TypeScope {
    let members: MemberBlockItemListSyntax
    /// A class or an actor holds its storage behind a reference, which a borrow accessor cannot
    /// expose.
    let isReferenceType: Bool

    var canExposeStorage: Bool { !isReferenceType }

    /// Whether the root of the yielded expression names a stored property of this type.
    ///
    /// A name the member list does not declare stays eligible. It may come from a superclass, an
    /// extension in another file or a generic constraint, and the rule prefers the false positive
    /// over the miss.
    func storesRoot(of expression: ExprSyntax) -> Bool {
        guard let name = expression.rootPropertyName else { return true }
        guard let declaration = members.variableDeclaring(name) else { return true }
        return declaration.isStoredProperty
    }
}

fileprivate extension AccessorDeclListSyntax {
    /// Whether the property declares a getter or a setter beside its coroutine accessors.
    var declaresGetterOrSetter: Bool {
        contains { $0.accessorSpecifier.text == "get" || $0.accessorSpecifier.text == "set" }
    }
}

fileprivate extension CodeBlockSyntax {
    /// The single expression the block yields, or nil when the block does anything else.
    var onlyYieldedExpression: ExprSyntax? {
        guard let only = statements.firstAndOnly,
              case let .stmt(statement) = only.item,
              let yield = statement.as(YieldStmtSyntax.self),
              case let .single(expression) = yield.yieldedExpressions else { return nil }

        // `yield &_x` on a `_modify` accessor wraps the reference in an inout expression
        return expression.as(InOutExprSyntax.self)?.expression ?? expression
    }
}

fileprivate extension ExprSyntax {
    /// Whether the expression names storage directly, rather than computing a value.
    ///
    /// A bare identifier qualifies. So does a member chain rooted at one, such as `self._x` or
    /// `_storage.element` . A call, a subscript or an operator does not, because the accessor may
    /// be exposing a temporary that only a coroutine can keep alive.
    var isStoredReference: Bool {
        if self.is(DeclReferenceExprSyntax.self) { return true }
        guard let member = self.as(MemberAccessExprSyntax.self), let base = member.base
        else { return false }
        return base.isStoredReference
    }

    /// The name of the property the chain starts from, looking through a leading `self`.
    ///
    /// `self._storage.value` and `_storage.value` both give `_storage` . A chain rooted at anything
    /// other than an identifier gives nil.
    var rootPropertyName: String? {
        if let reference = self.as(DeclReferenceExprSyntax.self) {
            let name = reference.baseName.text
            return name == "self" ? nil : name
        }
        guard let member = self.as(MemberAccessExprSyntax.self), let base = member.base
        else { return nil }
        if let reference = base.as(DeclReferenceExprSyntax.self), reference.baseName.text == "self"
        { return member.declName.baseName.text }
        return base.rootPropertyName
    }
}

fileprivate extension SyntaxProtocol {
    /// The member list of the nearest enclosing type declaration.
    var enclosingTypeScope: TypeScope? {
        var current = parent
        while let node = current {
            if let structure = node.as(StructDeclSyntax.self) {
                return TypeScope(members: structure.memberBlock.members, isReferenceType: false)
            }
            if let enumeration = node.as(EnumDeclSyntax.self) {
                return TypeScope(members: enumeration.memberBlock.members, isReferenceType: false)
            }
            if let extensionDecl = node.as(ExtensionDeclSyntax.self) {
                return TypeScope(members: extensionDecl.memberBlock.members, isReferenceType: false)
            }
            if let classDecl = node.as(ClassDeclSyntax.self) {
                return TypeScope(members: classDecl.memberBlock.members, isReferenceType: true)
            }
            if let actorDecl = node.as(ActorDeclSyntax.self) {
                return TypeScope(members: actorDecl.memberBlock.members, isReferenceType: true)
            }
            current = node.parent
        }
        return nil
    }
}

fileprivate extension MemberBlockItemListSyntax {
    /// The variable declaration that binds the given name, if this member list holds one.
    func variableDeclaring(_ name: String) -> VariableDeclSyntax? {
        for member in self {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            let binds = variable.bindings.contains {
                $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
            }
            if binds { return variable }
        }
        return nil
    }
}

fileprivate extension VariableDeclSyntax {
    /// Whether the declaration holds storage the enclosing type can hand out an address to.
    ///
    /// An attribute means a property wrapper, whose access runs the wrapper's own accessors. A
    /// getter, a setter or a coroutine accessor means a computed property. An observer leaves the
    /// storage in place, so `willSet` and `didSet` still count as stored.
    var isStoredProperty: Bool {
        guard attributes.isEmpty else { return false }
        for binding in bindings {
            switch binding.accessorBlock?.accessors {
                case .none: continue
                case .getter: return false
                case let .accessors(list):
                    let observersOnly = list.allSatisfy {
                        $0.accessorSpecifier.text == "willSet"
                            || $0.accessorSpecifier.text == "didSet"
                    }
                    if !observersOnly { return false }
            }
        }
        return true
    }
}

fileprivate extension Finding.Message {
    static let useBorrowAccessor: Finding.Message =
        "'_read' runs as a coroutine — a body that only yields stored storage can be a 'borrow' accessor instead (SE-0507)"
    static let useMutateAccessor: Finding.Message =
        "'_modify' runs as a coroutine — a body that only yields stored storage can be a 'mutate' accessor instead (SE-0507)"
}
