import SwiftSyntax

/// Flag a `_read` or `_modify` accessor that only exposes stored storage.
///
/// SE-0507 adds the `borrow` and `mutate` accessors in Swift 6.4. Both expose stored storage
/// without copying it, and neither runs as a coroutine, so neither pays the allocation and the
/// extra calls that `_read` and `_modify` pay. `borrow` also lets the exposed value outlive the
/// call, which a coroutine accessor cannot allow.
///
/// The rule fires only when the body is a single `yield` over a stored reference. A body that
/// builds a temporary, or that runs code after the `yield` , must stay on the coroutine form. The
/// same holds for the `read` and `modify` spellings.
///
/// Flag-only. The rewrite needs the accessor kind, the `&` on a `mutate` return, and a check that
/// the yielded storage really is stored, so it is left to the author.
///
/// Lint: A `_read` or `_modify` accessor whose body is one `yield` over a reference raises a
/// warning.
final class UseBorrowAccessorNotUnderscoreRead: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }

    override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
        let specifier = node.accessorSpecifier.text
        guard specifier == "_read" || specifier == "_modify" else { return .visitChildren }
        guard let body = node.body, body.yieldsStoredReference else { return .visitChildren }

        diagnose(
            specifier == "_read" ? .useBorrowAccessor : .useMutateAccessor,
            on: node.accessorSpecifier
        )
        return .visitChildren
    }
}

fileprivate extension CodeBlockSyntax {
    /// Whether the block is one `yield` of a single stored reference and nothing else.
    var yieldsStoredReference: Bool {
        guard let only = statements.firstAndOnly,
              case let .stmt(statement) = only.item,
              let yield = statement.as(YieldStmtSyntax.self),
              case let .single(expression) = yield.yieldedExpressions else { return false }

        // `yield &_x` on a `_modify` accessor wraps the reference in an inout expression.
        let target = expression.as(InOutExprSyntax.self)?.expression ?? expression
        return target.isStoredReference
    }
}

fileprivate extension ExprSyntax {
    /// Whether the expression names storage directly, rather than computing a value.
    ///
    /// A bare identifier qualifies. So does a member chain rooted at one, such as `self._x` or
    /// `_storage.element` . A call, a subscript or an operator does not, because the accessor may
    /// be exposing a temporary that only a coroutine can keep alive.
    var isStoredReference: Bool {
        if self.is(DeclReferenceExprSyntax.self) { return true }
        guard let member = self.as(MemberAccessExprSyntax.self), let base = member.base
        else { return false }
        return base.isStoredReference
    }
}

fileprivate extension Finding.Message {
    static let useBorrowAccessor: Finding.Message =
        "'_read' runs as a coroutine — a body that only yields stored storage can be a 'borrow' accessor instead (SE-0507)"
    static let useMutateAccessor: Finding.Message =
        "'_modify' runs as a coroutine — a body that only yields stored storage can be a 'mutate' accessor instead (SE-0507)"
}
