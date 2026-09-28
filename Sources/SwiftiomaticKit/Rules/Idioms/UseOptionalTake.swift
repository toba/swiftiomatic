import SwiftSyntax

/// Read an optional and clear its storage in one step with `take()`.
///
/// `Optional.take()` returns the current value and sets the storage to `nil`. Code that reads an
/// optional and then assigns `nil` to the same storage does the same work in two steps. `take()`
/// states that the value is consumed once. For example, change
/// `if let task = pendingTask { pendingTask = nil; task.cancel() }` to
/// `if let task = pendingTask.take() { task.cancel() }`.
///
/// Keep the two steps when `take()` changes the behavior. The toolchain must supply
/// `Optional.take()`. The storage must behave the same under one in-place access as under a read
/// and a write. A computed property or a property observer such as `didSet` can run different code
/// for each form. The storage must also become `nil` at the same time as before.
///
/// The rule matches three shapes. An `if let` with one condition whose body starts with the clear.
/// A `guard let` with one condition that the clear follows. A `let` declaration that the clear
/// follows. The rule stays silent when the `if` or `guard` has more than one condition, because
/// `take()` clears the storage even when a later condition fails. The storage must be a name or a
/// member access, not a call.
///
/// Lint: A read of optional storage that the next statement clears raises a warning.
final class UseOptionalTake: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        let items = Array(node)

        for (index, item) in items.enumerated() {
            let next = index + 1 < items.count ? items[index + 1] : nil

            if let ifExpr = Self.ifExpression(item),
               let (binding, storage) = Self.soleBinding(ifExpr.conditions),
               let first = ifExpr.body.statements.first,
               Self.clearedStorage(first) == storage
            {
                diagnose(.useTake(storage), on: binding)
            } else if let guardStmt = item.item.as(GuardStmtSyntax.self),
                let (binding, storage) = Self.soleBinding(guardStmt.conditions),
                let next,
                Self.clearedStorage(next) == storage
            {
                diagnose(.useTake(storage), on: binding)
            } else if let decl = item.item.as(VariableDeclSyntax.self),
                decl.bindingSpecifier.tokenKind == .keyword(.let)
                    || decl.bindingSpecifier.tokenKind == .keyword(.var),
                let patternBinding = decl.bindings.firstAndOnly,
                patternBinding.accessorBlock == nil,
                let value = patternBinding.initializer?.value,
                let storage = Self.storageName(value),
                let next,
                Self.clearedStorage(next) == storage
            {
                diagnose(.useTake(storage), on: decl)
            }
        }
        return .visitChildren
    }

    private static func ifExpression(_ item: CodeBlockItemSyntax) -> IfExprSyntax? {
        item.expression?.as(IfExprSyntax.self)
    }

    /// The optional binding and its storage name when the condition list holds exactly one optional
    /// binding.
    private static func soleBinding(
        _ conditions: ConditionElementListSyntax
    ) -> (OptionalBindingConditionSyntax, String)? {
        guard let condition = conditions.firstAndOnly,
              let binding = condition.condition.as(OptionalBindingConditionSyntax.self)
        else { return nil }

        if let value = binding.initializer?.value {
            guard let storage = storageName(value) else { return nil }
            return (binding, storage)
        }
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return nil
        }
        return (binding, name)
    }

    /// The storage name that `item` assigns `nil` to, if it is such an assignment.
    private static func clearedStorage(_ item: CodeBlockItemSyntax) -> String? {
        guard let expr = item.expression else { return nil }

        if let infix = expr.as(InfixOperatorExprSyntax.self),
           infix.operator.is(AssignmentExprSyntax.self),
           infix.rightOperand.is(NilLiteralExprSyntax.self) {
            return storageName(infix.leftOperand)
        }

        if let sequence = expr.as(SequenceExprSyntax.self) {
            let elements = Array(sequence.elements)
            guard elements.count == 3,
                  elements[1].is(AssignmentExprSyntax.self),
                  elements[2].is(NilLiteralExprSyntax.self) else { return nil }
            return storageName(elements[0])
        }
        return nil
    }

    /// A normalized name for a plain reference or member access chain, with any leading `self.`
    /// removed. Returns `nil` for any other expression.
    private static func storageName(_ expr: ExprSyntax) -> String? {
        var components: [String] = []
        var current: ExprSyntax? = expr

        while let node = current {
            if let reference = node.as(DeclReferenceExprSyntax.self) {
                components.append(reference.baseName.text)
                current = nil
            } else if let member = node.as(MemberAccessExprSyntax.self), let base = member.base {
                components.append(member.declName.baseName.text)
                current = base
            } else {
                return nil
            }
        }
        components.reverse()
        if components.count > 1, components.first == "self" { components.removeFirst() }
        return components.joined(separator: ".")
    }
}

fileprivate extension Finding.Message {
    static func useTake(_ storage: String) -> Finding.Message {
        "read '\(storage)' and clear it in one step with '\(storage).take()'"
    }
}
