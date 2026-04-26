import SwiftSyntax

/// `catch let error` (or any plain identifier-pattern catch) declares a binding of inferred type
/// `any Error`, throwing away whatever concrete type `try` could have produced. Either omit the
/// binding (the implicit `error` constant is the same thing) or pattern-match a concrete error
/// type with `catch let e as MyError`.
///
/// Lint: A warning is raised on `catch` clauses whose only catch item is a bare identifier
/// pattern (`let error`, `var x`, `(let error)`) without a type cast or `where` clause. The
/// implicit `catch {}` form is fine.
final class TypedCatchError: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        guard let item = node.catchItems.only, item.isPlainIdentifierPattern else {
            return .visitChildren
        }
        diagnose(.typedCatchError, on: node.catchKeyword)
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static let typedCatchError: Finding.Message =
        "drop the binding ('catch {}') or pattern-match a concrete error type ('catch let e as MyError')"
}

extension CatchItemListSyntax {
    fileprivate var only: CatchItemSyntax? {
        var iterator = makeIterator()
        guard let first = iterator.next(), iterator.next() == nil else { return nil }
        return first
    }
}

extension CatchItemSyntax {
    fileprivate var isPlainIdentifierPattern: Bool {
        guard whereClause == nil else { return false }
        if let valueBinding = pattern?.as(ValueBindingPatternSyntax.self) {
            return valueBinding.pattern.is(IdentifierPatternSyntax.self)
        }
        if let exprPattern = pattern?.as(ExpressionPatternSyntax.self),
            let tuple = exprPattern.expression.as(TupleExprSyntax.self),
            tuple.elements.count == 1,
            let element = tuple.elements.first,
            let inner = element.expression.as(PatternExprSyntax.self),
            let valueBinding = inner.pattern.as(ValueBindingPatternSyntax.self)
        {
            return valueBinding.pattern.is(IdentifierPatternSyntax.self)
        }
        return false
    }
}
