import SwiftSyntax

/// Flag a statement in an explicit `View` initializer that does more than store an input.
///
/// A parent creates its child views again each time it evaluates its own `body` . Work in the
/// child's initializer repeats on each of those evaluations, even when SwiftUI then skips the
/// child's `body` because its inputs did not change. Store the inputs as they arrive, and do the
/// work in `body` , where SwiftUI can skip it, or in a model that owns the result.
///
/// These statements are not work:
///
/// - an assignment of a name, a literal, a member access or `nil` to a property
/// - a property wrapper setup such as `_selection = selection` or
///   `_count = State(initialValue: start)`
/// - an assignment of the result of a `@ViewBuilder` or `@ContentBuilder` parameter call, such as
///   `self.popover = popover()`
/// - a delegation to `self.init(...)` or `super.init(...)`
///
/// Lint: An explicit initializer of a view type holds a statement other than those above.
final class NoWorkInViewInitializer: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let body = node.body, context.viewEntry(forMember: node) != nil else {
            return .skipChildren
        }
        let builders = Set(
            node.signature.parameterClause.parameters
                .filter(\.attributes.hasResultBuilder)
                .map { ($0.secondName ?? $0.firstName).text }
        )

        for statement in body.statements where !Self.isInputSetup(statement.item, builders) {
            diagnose(.workInInitializer, on: statement.item)
        }
        return .skipChildren
    }

    private static func isInputSetup(_ item: CodeBlockItemSyntax.Item, _ builders: Set<String>)
        -> Bool
    {
        guard case let .expr(expression) = item else { return false }

        if let call = expression.as(FunctionCallExprSyntax.self) { return isDelegation(call) }

        guard let assignment = expression.as(InfixOperatorExprSyntax.self),
              assignment.operator.is(AssignmentExprSyntax.self) else { return false }
        let value = assignment.rightOperand

        if isPlainValue(value) { return true }
        guard let call = value.as(FunctionCallExprSyntax.self) else { return false }

        if let callee = call.calledExpression.as(DeclReferenceExprSyntax.self),
           builders.contains(callee.baseName.text) { return true }
        // `_count = State(initialValue: start)` sets up the wrapper storage
        let target = assignment.leftOperand.assignmentRootName ?? ""
        return target.hasPrefix("_") && call.trailingClosure == nil
            && call.arguments.allSatisfy { isPlainValue($0.expression) }
    }

    /// Whether `call` is `self.init(...)` or `super.init(...)`
    private static func isDelegation(_ call: FunctionCallExprSyntax) -> Bool {
        guard let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.tokenKind == .keyword(.`init`),
              let base = member.base?.as(DeclReferenceExprSyntax.self) else { return false }
        return base.baseName.tokenKind == .keyword(.self)
            || base.baseName.tokenKind == .keyword(.super)
    }

    /// Whether reading `expression` costs nothing more than a load
    private static func isPlainValue(_ expression: ExprSyntax) -> Bool {
        if expression.is(DeclReferenceExprSyntax.self) || expression.is(NilLiteralExprSyntax.self)
            || expression.is(BooleanLiteralExprSyntax.self)
            || expression.is(IntegerLiteralExprSyntax.self)
            || expression.is(FloatLiteralExprSyntax.self)
        { return true }

        if let string = expression.as(StringLiteralExprSyntax.self) {
            return string.segments.allSatisfy { $0.is(StringSegmentSyntax.self) }
        }

        if let member = expression.as(MemberAccessExprSyntax.self) {
            return member.base.map(isPlainValue) ?? true
        }

        if let tuple = expression.as(TupleExprSyntax.self), let only = tuple.elements.first,
           tuple.elements.count == 1 { return isPlainValue(only.expression) }
        return false
    }
}

fileprivate extension Finding.Message {
    static let workInInitializer: Finding.Message = """
        This view initializer does work. A parent re-creates the view on each of its updates, so \
        the work repeats. Store the inputs and do the work in 'body' or in a model
        """
}
