import SwiftSyntax

/// Warn on `ForEach(_, id: \.self)`. SwiftUI uses `id` to diff views across
/// updates; using `\.self` requires the element to be both `Hashable` and
/// stable (its hash must not change when other state changes). Prefer making
/// the element `Identifiable`.
final class WarnForEachIdSelf: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "ForEach"
        else {
            return .visitChildren
        }
        for arg in node.arguments where arg.label?.text == "id" {
            if isKeyPathSelf(arg.expression) {
                diagnose(.idSelfFragile, on: arg.expression)
            }
        }
        return .visitChildren
    }

    private func isKeyPathSelf(_ expr: ExprSyntax) -> Bool {
        guard let kp = expr.as(KeyPathExprSyntax.self),
              kp.components.count == 1,
              let only = kp.components.first
        else {
            return false
        }
        if let property = only.component.as(KeyPathPropertyComponentSyntax.self),
           property.declName.baseName.tokenKind == .keyword(.self)
        {
            return true
        }
        return false
    }
}

extension Finding.Message {
    fileprivate static let idSelfFragile: Finding.Message =
        "'id: \\.self' is fragile — make the element 'Identifiable' or supply a stable id key path"
}
