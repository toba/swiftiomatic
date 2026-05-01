import SwiftSyntax

/// Prefer `reduce(into:_:)` over `reduce(_:_:)` when the accumulator is a copy-on-write value type
/// (Array, Dictionary, Set, String).
///
/// `reduce(_:_:)` makes a fresh copy of the accumulator on every step; `reduce(into:_:)` mutates
/// the seed in place.
///
/// Lint: warns when `reduce` 's first argument is unlabeled (so it would otherwise be `into:` ) and
/// the seed expression names a CoW type.
final class UseReduceInto: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .collections }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let nameToken = node.reduceNameToken,
              nameToken.text == "reduce",
              // Either two positional arguments, or one + a trailing closure.
              node.arguments.count == 2
                  || (node.arguments.count == 1 && node.trailingClosure != nil),
              let firstArgument = node.arguments.first,
              firstArgument.label == nil,
              firstArgument.expression.isCopyOnWriteSeed else { return .visitChildren }
        diagnose(.useReduceInto, on: nameToken)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let useReduceInto: Finding.Message =
        "prefer 'reduce(into:_:)' over 'reduce(_:_:)' for copy-on-write seeds"
}

fileprivate extension FunctionCallExprSyntax {
    var reduceNameToken: TokenSyntax? {
        if let member = calledExpression.as(MemberAccessExprSyntax.self) {
            return member.declName.baseName
        }
        if let ref = calledExpression.as(DeclReferenceExprSyntax.self) { return ref.baseName }
        return nil
    }
}

fileprivate extension ExprSyntax {
    var isCopyOnWriteSeed: Bool {
        if self.is(StringLiteralExprSyntax.self)
            || self.is(DictionaryExprSyntax.self)
            || self.is(ArrayExprSyntax.self)
        {
            return true
        }
        if let call = self.as(FunctionCallExprSyntax.self) {
            if let identifier = call.calledExpression.cowIdentifierExpr {
                return identifier.isCopyOnWriteTypeName
            }
            if let member = call.calledExpression.as(MemberAccessExprSyntax.self),
               member.declName.baseName.text == "init",
               let identifier = member.base?.cowIdentifierExpr
            {
                return identifier.isCopyOnWriteTypeName
            }
            if call.calledExpression.isCopyOnWriteSeed { return true }
        }
        return false
    }

    var cowIdentifierExpr: DeclReferenceExprSyntax? {
        if let ref = self.as(DeclReferenceExprSyntax.self) { return ref }
        if let specialize = self.as(GenericSpecializationExprSyntax.self) {
            return specialize.expression.cowIdentifierExpr
        }
        return nil
    }
}

fileprivate extension DeclReferenceExprSyntax {
    static let copyOnWriteTypeNames: Set<String> = ["Array", "Dictionary", "Set"]

    var isCopyOnWriteTypeName: Bool { Self.copyOnWriteTypeNames.contains(baseName.text) }
}
