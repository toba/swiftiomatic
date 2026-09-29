import SwiftSyntax

/// Remove `Self._printChanges()` and `Self._logChanges()` calls that no `#if DEBUG` guards.
///
/// These calls are debugging aids. They write to the console on each view update, and they are
/// underscored API that can change. They do not belong in shipping code.
///
/// The rule matches a statement that is the call, `let _ = <call>` or `_ = <call>` .
///
/// Lint: A call that no enclosing `#if DEBUG` clause wraps raises a warning.
///
/// Rewrite: The statement is removed. A call inside `#if DEBUG` stays.
final class NoPrintChangesInBody: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 647

    override class var group: ConfigurationGroup? { .swiftui }

    private static let debugMethods: Set<String> = ["_printChanges", "_logChanges"]

    static func transform(
        _ node: CodeBlockItemListSyntax,
        original: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        guard !isInsideDebugClause(original) else { return node }

        let items = Array(node)
        let originalItems = Array(original)
        var kept: [CodeBlockItemSyntax] = []
        var removedLeadingTrivia: Trivia?

        for (index, item) in items.enumerated() {
            guard let method = debugMethod(in: item) else {
                var item = item
                // The first kept item takes the trivia of a removed first statement, so the block
                // does not open with a blank line.
                if kept.isEmpty, let trivia = removedLeadingTrivia {
                    item.leadingTrivia = trivia
                    removedLeadingTrivia = nil
                }
                kept.append(item)
                continue
            }
            let anchor = originalItems.count == items.count ? originalItems[index] : item
            Self.diagnose(.removeDebugCall(method), on: anchor.item, context: context)

            if kept.isEmpty, removedLeadingTrivia == nil {
                removedLeadingTrivia = item.leadingTrivia
            }
        }

        guard kept.count != items.count else { return node }
        return CodeBlockItemListSyntax(kept)
    }

    /// The debug method name when `item` is a statement that only calls it.
    private static func debugMethod(in item: CodeBlockItemSyntax) -> String? {
        if let variable = item.item.as(VariableDeclSyntax.self) {
            guard variable.bindingSpecifier.tokenKind == .keyword(.let),
                  variable.attributes.isEmpty,
                  variable.modifiers.isEmpty,
                  let binding = variable.bindings.first,
                  variable.bindings.count == 1,
                  binding.pattern.is(WildcardPatternSyntax.self),
                  binding.typeAnnotation == nil,
                  let value = binding.initializer?.value else { return nil }
            return debugMethod(called: value)
        }
        if let expr = item.item.as(ExprSyntax.self) {
            if let infix = expr.as(InfixOperatorExprSyntax.self) {
                guard infix.leftOperand.is(DiscardAssignmentExprSyntax.self),
                    infix.operator.is(AssignmentExprSyntax.self) else { return nil }
                return debugMethod(called: infix.rightOperand)
            }
            if let sequence = expr.as(SequenceExprSyntax.self) {
                let elements = Array(sequence.elements)
                guard elements.count == 3,
                      elements[0].is(DiscardAssignmentExprSyntax.self),
                      elements[1].is(AssignmentExprSyntax.self) else { return nil }
                return debugMethod(called: elements[2])
            }
            return debugMethod(called: expr)
        }
        return nil
    }

    /// The debug method name when `expr` is `Self._printChanges()` or `Self._logChanges()` .
    private static func debugMethod(called expr: ExprSyntax) -> String? {
        guard let call = expr.as(FunctionCallExprSyntax.self),
              call.arguments.isEmpty,
              call.trailingClosure == nil,
              call.additionalTrailingClosures.isEmpty,
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              let base = member.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.tokenKind == .keyword(.Self),
              debugMethods.contains(member.declName.baseName.text) else { return nil }
        return member.declName.baseName.text
    }

    /// Whether an enclosing `#if` / `#elseif` clause tests `DEBUG` without negating it.
    private static func isInsideDebugClause(_ node: some SyntaxProtocol) -> Bool {
        var current = node.parent

        while let ancestor = current {
            if let clause = ancestor.as(IfConfigClauseSyntax.self),
               let condition = clause.condition,
               testsDebug(condition) { return true }
            current = ancestor.parent
        }
        return false
    }

    /// Whether `condition` names `DEBUG` outside a `!` prefix.
    private static func testsDebug(_ condition: ExprSyntax) -> Bool {
        condition.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.text == "DEBUG" else { return false }
            var current = token.parent
            while let ancestor = current, ancestor.id != condition.id {
                if ancestor.as(PrefixOperatorExprSyntax.self)?.operator.text == "!" { return false }
                current = ancestor.parent
            }
            return true
        }
    }
}

fileprivate extension Finding.Message {
    static func removeDebugCall(_ method: String) -> Finding.Message {
        "remove 'Self.\(method)()' from shipping code, or wrap it in '#if DEBUG'"
    }
}
