import SwiftSyntax

/// Flag an `.onAppear` that assigns a `@State` property a value derived from another property of
/// the view.
///
/// `.onAppear` runs when the view appears, not when its inputs change. A parent can pass a new
/// value, or a binding can change, while the view stays on screen. The state then keeps the value
/// from the last appearance and goes stale. Compute the value where it is read, for example in a
/// computed property, or keep it current with `.onChange(of: source, initial: true)` .
///
/// `RequireRepeatSafeOnAppear` covers writes that accumulate, such as `count += 1` . This rule does
/// not report an assignment whose value reads only the target itself, or reads no property of the
/// view, such as `isFocused = true` .
///
/// The value can reach the assignment through a local `if let` , `guard let` or `let` binding in the
/// closure, or through a computed property of the view that reads a stored property.
///
/// Lint: An assignment in an `.onAppear` closure targets a `@State` property of the view, and its
/// value reads a different stored property of the same view.
final class NoOnAppearDerivedState: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onAppear",
              let action = node.actionClosure(labels: ["perform"]),
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView else { return .visitChildren }
        let writes = InfixOperatorExprSyntax.assignments(
            in: action, compound: false, enteringClosures: false)

        for write in writes {
            let root = write.leftOperand.assignmentRoot
            guard root.id == write.leftOperand.id,
                  let target = root.assignmentRootName,
                  entry.isStateProperty(target),
                  !TypeMemberIndex.references(in: root, of: entry).isEmpty,
                  let source = Self.memberNames(
                      reaching: write.rightOperand, within: action, of: entry
                  ).first(where: { Self.isInput($0, of: entry, excluding: target) })
            else { continue }
            diagnose(.staleDerivedState(target: target, source: source), on: write)
        }
        return .visitChildren
    }

    /// Whether the member named `name` is a stored instance property other than `target` , or a
    /// computed property whose getter reads one
    private static func isInput(
        _ name: String,
        of entry: TypeMemberIndex.TypeEntry,
        excluding target: String
    ) -> Bool {
        guard name != target else { return false }
        if entry.isStoredInstanceProperty(name) { return true }
        return entry.members(named: name)?.contains { member in
            guard member.kind == .computedProperty, !member.isStatic,
                  let body = member.body else { return false }
            return TypeMemberIndex.references(in: body, of: entry).contains {
                $0.name != target && $0.name != name && entry.isStoredInstanceProperty($0.name)
            }
        } == true
    }

    /// The names of the members of `entry` whose values reach `expression` , in source order
    ///
    /// A local name that an `if let` , `guard let` or `let` binding inside `action` declares
    /// contributes the members its bound value reads. A shorthand `if let name` contributes the
    /// member `name` .
    private static func memberNames(
        reaching expression: ExprSyntax,
        within action: ClosureExprSyntax,
        of entry: TypeMemberIndex.TypeEntry
    ) -> [String] {
        var names: [String] = []
        var pending = [expression]
        var visited: Set<SyntaxIdentifier> = []

        while let current = pending.popLast() {
            guard visited.insert(current.id).inserted else { continue }
            names += TypeMemberIndex.references(in: current, of: entry).map(\.name)

            for reference in current.bareReferences {
                switch localBinding(of: reference.baseName.text, at: reference, within: action) {
                    case let .value(value)?: pending.append(value)
                    case .shorthand?:
                        if entry.members(named: reference.baseName.text) != nil {
                            names.append(reference.baseName.text)
                        }
                    case nil: break
                }
            }
        }
        return names
    }

    fileprivate enum LocalBinding {
        /// The binding reads this value
        case value(ExprSyntax)
        /// `if let name` rebinds the outer `name`
        case shorthand
    }

    /// The binding inside `action` that declares `name` for `node`
    private static func localBinding(
        of name: String,
        at node: some SyntaxProtocol,
        within action: ClosureExprSyntax
    ) -> LocalBinding? {
        var child = Syntax(node)
        var current = node.parent

        while let cur = current, cur.id != action.id {
            if let ifExpr = cur.as(IfExprSyntax.self), child.id == ifExpr.body.id,
               let binding = ifExpr.conditions.binding(of: name) { return binding }

            if let list = cur.as(CodeBlockItemListSyntax.self) {
                for item in list.reversed() where item.endPosition <= child.position {
                    if let guardStmt = item.item.as(GuardStmtSyntax.self),
                       let binding = guardStmt.conditions.binding(of: name) { return binding }

                    if let variable = item.item.as(VariableDeclSyntax.self),
                       let binding = variable.bindings.first(where: {
                           $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
                       }) {
                        return binding.initializer.map { .value($0.value) }
                    }
                }
            }
            child = cur
            current = cur.parent
        }
        return nil
    }
}

private extension ConditionElementListSyntax {
    /// The optional binding in the list that declares `name`
    func binding(of name: String) -> NoOnAppearDerivedState.LocalBinding? {
        for element in self {
            guard case let .optionalBinding(binding) = element.condition,
                  binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
            else { continue }
            return binding.initializer.map { .value($0.value) } ?? .shorthand
        }
        return nil
    }
}

private extension SyntaxProtocol {
    /// The bare names this node reads, such as `value` , but not the `value` of `base.value`
    var bareReferences: [DeclReferenceExprSyntax] {
        if let reference = Syntax(self).as(DeclReferenceExprSyntax.self) {
            let isMemberName = reference.parent?.as(MemberAccessExprSyntax.self)?.declName.id
                == reference.id
            return isMemberName ? [] : [reference]
        }
        return children(viewMode: .sourceAccurate).flatMap(\.bareReferences)
    }
}

fileprivate extension Finding.Message {
    static func staleDerivedState(target: String, source: String) -> Finding.Message {
        """
        '.onAppear' derives '\(target)' from '\(source)' once, so '\(target)' goes stale when \
        '\(source)' changes. Compute '\(target)' where it is read, or use \
        '.onChange(of: \(source), initial: true)'
        """
    }
}
