import SwiftSyntax

/// Flag a write inside `.onAppear` that gives a different result each time it runs.
///
/// A view can appear many times: on each navigation back to it, each tab switch, and each time a
/// lazy container scrolls it into view again. A compound assignment such as `count += 1` , an
/// `append` , or `x = x + 1` accumulates across those appearances. Guard the write so that it runs
/// once, or move it to the owner of the state.
///
/// An assignment of a fixed value, such as `isFocused = true` , is repeat-safe and is not reported.
/// `UseTaskModifierNotOnAppear` covers a `Task` that starts from `.onAppear` .
///
/// Lint: An `.onAppear` closure holds a compound assignment, a self-referential arithmetic
/// assignment, or a call to a mutating collection method such as `append` .
final class RequireRepeatSafeOnAppear: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onAppear", let action = node.actionClosure(labels: ["perform"])
        else { return .visitChildren }
        let finder = WriteFinder(viewMode: .sourceAccurate)
        finder.walk(action.statements)

        for write in finder.writes {
            diagnose(.repeatedWrite(write.trimmedDescription), on: write)
        }
        return .visitChildren
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

        var writes: [ExprSyntax] = []

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            if node.operator.isCompoundAssignmentOperator || Self.isSelfReferential(node) {
                writes.append(ExprSyntax(node))
            }
            return .visitChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
               member.base != nil,
               Self.accumulatingMethods.contains(member.declName.baseName.text) {
                writes.append(ExprSyntax(node))
            }
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
}
