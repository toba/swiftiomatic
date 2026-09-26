import SwiftSyntax

/// Check for a framework with `#if canImport(...)`, not with `#if os(...)`.
///
/// An `#if os(...)` block that holds only an `import` uses the platform as a stand-in for the
/// framework. `canImport` states the real question. It also keeps working when the framework comes
/// to a new platform, such as UIKit on visionOS or Mac Catalyst.
///
/// The rule fires only on a block with a single `#if` clause, a condition made only of `os(...)`
/// checks, and a body made only of `import` declarations. An `#else` or `#elseif` branch marks a
/// platform split, such as AppKit on macOS and UIKit elsewhere. There the file depends on platform
/// types, not only on one framework, so the rule stays silent.
///
/// Lint: An `#if os(...)` block that guards only framework imports raises a warning.
final class UseCanImportNotOSCheck: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let clause = node.clauses.firstAndOnly,
              let condition = clause.condition,
              isOSOnly(condition),
              case let .statements(items)? = clause.elements,
              !items.isEmpty,
              items.allSatisfy({ $0.item.is(ImportDeclSyntax.self) }) else { return .visitChildren }

        diagnose(.useCanImport, on: node)
        return .visitChildren
    }

    /// Reports whether the condition combines only `os(...)` checks with `!`, `&&`, `||` and
    /// parentheses.
    private func isOSOnly(_ expr: ExprSyntax) -> Bool {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "os"
        }

        if let prefix = expr.as(PrefixOperatorExprSyntax.self) {
            return prefix.operator.text == "!" && isOSOnly(prefix.expression)
        }

        if let tuple = expr.as(TupleExprSyntax.self), let only = tuple.elements.firstAndOnly {
            return isOSOnly(only.expression)
        }

        if let infix = expr.as(InfixOperatorExprSyntax.self) {
            return isLogical(infix.operator) && isOSOnly(infix.leftOperand)
                && isOSOnly(infix.rightOperand)
        }
        if let sequence = expr.as(SequenceExprSyntax.self) {
            return sequence.elements.enumerated().allSatisfy { index, element in
                index.isMultiple(of: 2) ? isOSOnly(element) : isLogical(element)
            }
        }
        return false
    }

    private func isLogical(_ expr: ExprSyntax) -> Bool {
        guard let op = expr.as(BinaryOperatorExprSyntax.self) else { return false }
        return op.operator.text == "&&" || op.operator.text == "||"
    }
}

fileprivate extension Finding.Message {
    static let useCanImport: Finding.Message =
        "this '#if os(...)' guards only an import; use '#if canImport(...)' to check for the framework"
}
