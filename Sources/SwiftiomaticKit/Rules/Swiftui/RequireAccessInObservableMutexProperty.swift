import SwiftSyntax

/// Flag a computed property of an `@Observable` class that reads or writes a `Mutex` with no
/// observation call.
///
/// The `@Observable` macro tracks stored properties only. A computed property that reads its
/// value through `Mutex.withLock` gives Observation nothing to track, so a view that reads the
/// property does not update when the value changes. The getter must call `access(keyPath:)`, and
/// the setter must wrap the change in `withMutation(keyPath:)`.
///
/// The rule reads each instance computed property of an `@Observable` class, and of an extension
/// of an `@Observable` class in the same file. It reports a getter that calls `withLock` with no
/// `access` call, and a setter that calls `withLock` with no `withMutation` call.
///
/// Lint: A computed property of an `@Observable` class calls `withLock` with no
/// `access(keyPath:)` or `withMutation(keyPath:)` call.
final class RequireAccessInObservableMutexProperty: LintSyntaxRule<LintOnlyValue>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .must }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !node.modifiers.contains(where: {
                  $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
              }),
              isInObservableClass(node) else { return .visitChildren }

        for binding in node.bindings {
            guard let accessorBlock = binding.accessorBlock,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else { continue }

            switch accessorBlock.accessors {
                case let .getter(body):
                    if Self.calls("withLock", in: body), !Self.calls("access", in: body) {
                        diagnose(.getterNeedsAccess(name), on: binding.pattern)
                    }
                case let .accessors(accessors):
                    for accessor in accessors {
                        guard let body = accessor.body, Self.calls("withLock", in: body) else {
                            continue
                        }
                        switch accessor.accessorSpecifier.tokenKind {
                            case .keyword(.get) where !Self.calls("access", in: body):
                                diagnose(.getterNeedsAccess(name), on: accessor)
                            case .keyword(.set) where !Self.calls("withMutation", in: body):
                                diagnose(.setterNeedsMutation(name), on: accessor)
                            default:
                                break
                        }
                    }
            }
        }
        return .visitChildren
    }

    /// Whether `node` is a member of an `@Observable` class, or of an extension of one
    private func isInObservableClass(_ node: VariableDeclSyntax) -> Bool {
        guard node.parent?.is(MemberBlockItemSyntax.self) == true,
              let entry = context.typeMembers(around: node).enclosingType(of: node) else {
            return false
        }
        return entry.kind == .class && entry.isObservable
    }

    /// Whether `syntax` holds a call to a function or method named `name`
    private static func calls(_ name: String, in syntax: some SyntaxProtocol) -> Bool {
        syntax.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.tokenKind == .identifier(name),
                  let reference = token.parent?.as(DeclReferenceExprSyntax.self) else {
                return false
            }
            var callee = Syntax(reference)
            if let member = reference.parent?.as(MemberAccessExprSyntax.self) {
                guard member.declName.id == reference.id else { return false }
                callee = Syntax(member)
            }
            return callee.parent?.as(FunctionCallExprSyntax.self)?.calledExpression.id == callee.id
        }
    }
}

fileprivate extension Finding.Message {
    static func getterNeedsAccess(_ name: String) -> Finding.Message {
        "call 'access(keyPath:)' in the getter of '\(name)'. Observation does not track the state that 'withLock' reads"
    }

    static func setterNeedsMutation(_ name: String) -> Finding.Message {
        "call 'withMutation(keyPath:)' in the setter of '\(name)'. Observation does not see the change that 'withLock' makes"
    }
}
