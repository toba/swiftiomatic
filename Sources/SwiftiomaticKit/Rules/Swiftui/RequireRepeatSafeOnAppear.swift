import SwiftSyntax

/// Flag a write inside `.onAppear` that gives a different result each time it runs.
///
/// A view can appear many times: on each navigation back to it, each tab switch, and each time a
/// lazy container scrolls it into view again. A compound assignment such as `count += 1` , an
/// `append` , or `x = x + 1` accumulates across those appearances. Guard the write so that it runs
/// once, or move it to the owner of the state.
///
/// A call to a method of the view or to a closure it holds, such as `loadMore()` , runs again on
/// each appearance too. A row of a lazy list that asks for the next page when it appears asks again
/// each time it scrolls back into view. Make the call repeat-safe, or guard it with a flag the view
/// keeps in state, as in `guard !didLoad else { return }` followed by `didLoad = true` . A `@State`
/// flag means once for this view identity. When SwiftUI removes the view and inserts it again, the
/// flag starts fresh. The rule reports a call only when its name is a member that the view or a
/// same-file extension declares. A free function such as `max(a, b)` is not reported.
///
/// An assignment of a fixed value, such as `isFocused = true` , is repeat-safe and is not reported.
/// A call is not reported when an `if` or `guard` in the closure reads a property the view keeps in
/// state, such as `@State` or `@Binding` , because that check can make the call run once. The rule
/// reads these properties from the view and from its same-file extensions. A call inside a nested
/// closure, a call on another value, and a call to `print` or `withAnimation` are not reported.
/// `UseTaskModifierNotOnAppear` covers a `Task` that starts from `.onAppear` .
///
/// Lint: An `.onAppear` closure holds a compound assignment, a self-referential arithmetic
/// assignment, a call to a mutating collection method such as `append` , or a call to a method of
/// the view or a closure it holds that no state check guards.
final class RequireRepeatSafeOnAppear: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onAppear", let action = node.actionClosure(labels: ["perform"])
        else { return .visitChildren }
        let finder = WriteFinder(viewMode: .sourceAccurate)
        finder.walk(action.statements)

        for write in finder.writes { diagnose(.repeatedWrite(write.trimmedDescription), on: write) }
        guard let entry = context.typeMembers(around: node).enclosingType(of: node) else {
            return .visitChildren
        }
        let calls = finder.calls.filter { call in
            guard let name = call.calledExpression.selfMemberReference?.baseName.text else {
                return false
            }
            return entry.members[name]?.contains { !$0.isStatic } == true
        }
        if !calls.isEmpty, !checksState(action, names: Self.stateNames(of: entry)) {
            for call in calls { diagnose(.repeatedCall(call.trimmedDescription), on: call) }
        }
        return .visitChildren
    }

    /// The names of the properties of `entry` that keep state across appearances
    ///
    /// The entry merges the type and its same-file extensions, so an `.onAppear` in an extension
    /// sees the wrappers of the main declaration.
    private static func stateNames(of entry: TypeMemberIndex.TypeEntry) -> Set<String> {
        var names = Set<String>()

        for (name, overloads) in entry.members {
            let keepsState = overloads.contains { member in
                guard member.kind == .storedProperty,
                      let wrapper = member.declaration.as(VariableDeclSyntax.self)?.attributes
                          .firstAttributeName else { return false }
                return VariableDeclSyntax.installedStorageWrappers.contains(wrapper)
                    || VariableDeclSyntax.bindingWrappers.contains(wrapper)
            }
            if keepsState { names.insert(name) }
        }
        return names
    }

    /// Whether an `if` or `guard` condition in `action` reads one of `names`
    private func checksState(_ action: ClosureExprSyntax, names: Set<String>) -> Bool {
        guard !names.isEmpty else { return false }
        return action.statements.tokens(viewMode: .sourceAccurate).contains { token in
            guard names.contains(token.text) else { return false }
            var current = token.parent
            while let syntax = current, !syntax.is(ClosureExprSyntax.self) {
                if syntax.is(ConditionElementListSyntax.self) { return true }
                current = syntax.parent
            }
            return false
        }
    }

    private final class WriteFinder: SyntaxVisitor {
        /// Methods whose effect adds up when they run again
        static let accumulatingMethods: Set<String> = [
            "append", "insert", "prepend", "toggle", "removeFirst", "removeLast", "popLast",
            "formUnion", "formSymmetricDifference",
        ]

        /// Operators that combine the old value with another operand
        static let arithmeticOperators: Set<String> = [
            "+", "-", "*", "/", "%", "&+", "&-", "&*", "<<", ">>", "&", "|", "^",
        ]

        /// Functions whose repeat does no harm
        static let harmlessFunctions: Set<String> = [
            "print", "debugPrint", "dump", "assert", "assertionFailure", "precondition",
            "preconditionFailure", "fatalError", "withAnimation", "withTransaction",
        ]

        var writes: [ExprSyntax] = []

        /// Calls that spell `name(…)` or `self.name(…)` , outside nested closures
        var calls: [FunctionCallExprSyntax] = []

        private var closureDepth = 0

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            closureDepth += 1
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) { closureDepth -= 1 }

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            if node.operator.isCompoundAssignmentOperator || Self.isSelfReferential(node) {
                writes.append(ExprSyntax(node))
            }
            return .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
                member.base != nil,
                Self.accumulatingMethods.contains(member.declName.baseName.text)
            {
                writes.append(ExprSyntax(node))
            } else if closureDepth == 0,
               let name = node.calledExpression.selfMemberReference?.baseName.text,
               name.first?.isLowercase == true,
               !Self.harmlessFunctions.contains(name) { calls.append(node) }
            return .visitChildren
        }

        /// Whether `node` is `x = x + y` or another arithmetic update of the target
        private static func isSelfReferential(_ node: InfixOperatorExprSyntax) -> Bool {
            guard node.operator.is(AssignmentExprSyntax.self),
                let value = node.rightOperand.as(InfixOperatorExprSyntax.self),
                let op = value.operator.as(BinaryOperatorExprSyntax.self),
                arithmeticOperators.contains(op.operator.text) else { return false }
            return normalized(value.leftOperand) == normalized(node.leftOperand)
        }

        private static func normalized(_ expression: ExprSyntax) -> String {
            let text = expression.trimmedDescription
            return text.hasPrefix("self.") ? String(text.dropFirst(5)) : text
        }
    }
}

fileprivate extension Finding.Message {
    static func repeatedWrite(_ write: String) -> Finding.Message {
        """
        '.onAppear' runs each time the view appears, and '\(write)' does not give the same \
        result when it repeats. Guard it, or move it to the owner of the state
        """
    }

    static func repeatedCall(_ call: String) -> Finding.Message {
        """
        '.onAppear' runs each time the view appears, so '\(call)' runs again on each \
        appearance. Make sure the call is repeat-safe, or guard it with state so that it runs once
        """
    }
}
