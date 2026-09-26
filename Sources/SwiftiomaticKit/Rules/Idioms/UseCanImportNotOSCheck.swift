import SwiftSyntax

/// Check for a framework with `#if canImport(...)`, not with `#if os(...)`.
///
/// An `#if os(...)` block that holds only an `import` uses the platform as a stand-in for the
/// framework. `canImport` states the real question. It also keeps working when the framework comes
/// to a new platform, such as UIKit on visionOS or Mac Catalyst.
///
/// The rule fires on a block whose conditions are made only of `os(...)` checks and whose branches
/// hold only `import` declarations. An `#else` or `#elseif` branch marks a platform split, such as
/// AppKit on macOS and UIKit elsewhere. When the file names an `NS` or `UI` type outside any `#if`
/// block, the file depends on a type both frameworks spell, so the split stays and the rule is
/// silent. When every such type sits inside its own `#if` , `#if canImport(AppKit)` with
/// `#elseif canImport(UIKit)` states the need.
///
/// Lint: An `#if os(...)` block that guards only framework imports raises a warning.
final class UseCanImportNotOSCheck: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let first = node.clauses.first, first.condition != nil,
              node.clauses.allSatisfy(isOSImportClause) else { return .visitChildren }

        if node.clauses.count > 1, namesPlatformTypeOutsideConditions(node.root) {
            return .visitChildren
        }
        diagnose(.useCanImport, on: node)
        return .visitChildren
    }

    /// Whether the clause has an `os(...)` -only condition, or none for `#else` , and a body made
    /// only of `import` declarations
    private func isOSImportClause(_ clause: IfConfigClauseSyntax) -> Bool {
        if let condition = clause.condition, !isOSOnly(condition) { return false }
        guard case let .statements(items)? = clause.elements, !items.isEmpty else { return false }
        return items.allSatisfy { $0.item.is(ImportDeclSyntax.self) }
    }

    /// Whether the file names an `NS` or `UI` type outside every `#if` block
    private func namesPlatformTypeOutsideConditions(_ root: Syntax) -> Bool {
        root.tokens(viewMode: .sourceAccurate).contains { token in
            guard case .identifier = token.tokenKind, Self.isPlatformTypeName(token.text)
            else { return false }
            return token.ancestorOrSelf(mapping: { $0.as(IfConfigDeclSyntax.self) }) == nil
        }
    }

    private static func isPlatformTypeName(_ name: String) -> Bool {
        guard name.hasPrefix("NS") || name.hasPrefix("UI") else { return false }
        return name.dropFirst(2).first?.isUppercase == true
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
