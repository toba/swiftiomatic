import SwiftSyntax

// Alignment offsets for wrapped condition lists. Each equals the keyword plus its trailing space,
// so a continuation lines up under the first character of the first condition.
let ifConditionAlignment = 3  // "if " (2 + 1)
let whileConditionAlignment = 6  // "while " (5 + 1)
let guardConditionAlignment = 6  // "guard " (5 + 1)

/// How the layout indents a condition list that wraps
///
/// The token stream turns `breakKind` into the break it emits between conditions.
/// `LayoutSingleLineBodies` reads `isUniform` to decide whether a body folded onto the last
/// condition would read as part of the condition list. Both answer from this one value, so a rule
/// that runs before the layout predicts the column the layout will pick instead of reading the
/// column the source happened to carry.
struct ConditionWrapping {
    /// The break the layout gives each condition it wraps
    let breakKind: OpenBreakKind

    /// Whether every condition line starts at the same column once the list wraps
    let isUniform: Bool
}

/// How the layout wraps an `if` statement's condition list
///
/// The first condition stays on the `if` line, so the list is uniform only when the continuations
/// align under it. A first condition that is a member-access chain breaks at continuation indent of
/// its own, and mixing that with the alignment column reads worse than one indent for every line.
///
/// - Parameters:
///   - conditions: the condition list of the statement
///   - config: the configuration that drives the choice
func ifConditionWrapping(
    _ conditions: ConditionElementListSyntax,
    config: Configuration
) -> ConditionWrapping {
    conditionWrapping(conditions, alignment: ifConditionAlignment, config: config)
}

/// How the layout wraps a `while` statement's condition list
///
/// - Parameters:
///   - conditions: the condition list of the statement
///   - config: the configuration that drives the choice
func whileConditionWrapping(
    _ conditions: ConditionElementListSyntax,
    config: Configuration
) -> ConditionWrapping {
    conditionWrapping(conditions, alignment: whileConditionAlignment, config: config)
}

/// How the layout wraps a `guard` statement's condition list
///
/// With `BreakBeforeGuardConditions` on, every condition drops below the keyword at continuation
/// indent, the first one included, so the wrapped list is uniform whatever the alignment setting
/// says. A compound first condition is the exception: break precedence keeps it on the `guard` line
/// so its own operator breaks fire first. With the setting off the first condition always stays on
/// that line, and the list is uniform only when the continuations align under it.
///
/// The uniform answer is conservative. A first condition that carries a comment or a multiline
/// string literal does drop below the keyword, and this reports it as staying, which refuses a fold
/// the layout would have accepted.
///
/// - Parameters:
///   - conditions: the condition list of the statement
///   - config: the configuration that drives the choice
func guardConditionWrapping(
    _ conditions: ConditionElementListSyntax,
    config: Configuration
) -> ConditionWrapping {
    guard !config[BreakBeforeGuardConditions.self] else {
        return ConditionWrapping(
            breakKind: .continuation,
            isUniform: !firstConditionKeepsKeywordLine(conditions)
        )
    }
    return conditionWrapping(conditions, alignment: guardConditionAlignment, config: config)
}

/// Whether break precedence holds a `guard` statement's first condition on the keyword line
private func firstConditionKeepsKeywordLine(_ conditions: ConditionElementListSyntax) -> Bool {
    guard case let .expression(expr) = conditions.first?.condition else { return false }
    return isCompoundExpression(expr)
}

private func conditionWrapping(
    _ conditions: ConditionElementListSyntax,
    alignment: Int,
    config: Configuration
) -> ConditionWrapping {
    let aligns = config[AlignWrappedConditions.self]
        && !(conditions.first.map { conditionContainsMemberChain($0) } ?? false)
    return .init(
        breakKind: aligns ? .alignment(spaces: alignment) : .continuation,
        isUniform: aligns
    )
}

// MARK: - Expression shape predicates

/// Returns whether the given expression consists of multiple subexpressions. Certain expressions
/// that are known to wrap an expression, e.g. try expressions, are handled by checking the
/// expression that they contain.
func isCompoundExpression(_ expr: ExprSyntax) -> Bool {
    if let modifiedExpr = expr.asProtocol(KeywordModifiedExprSyntax.self) {
        return isCompoundExpression(modifiedExpr.expression)
    }
    switch Syntax(expr).as(SyntaxEnum.self) {
        case .infixOperatorExpr, .ternaryExpr, .isExpr, .asExpr: return true
        case let .tupleExpr(tupleExpr) where tupleExpr.elements.count == 1:
            return isCompoundExpression(tupleExpr.elements.first!.expression)
        default: return false
    }
}

/// Returns whether the given expression is or begins with a member access chain (e.g.
/// `foo.bar(...)` , `foo.bar(...).baz(...)` ). Used to detect method-chaining RHS expressions in
/// assignments so the formatter prefers breaking at dots rather than after `=` .
func isMemberAccessChain(_ expr: ExprSyntax) -> Bool {
    if let modifiedExpr = expr.asProtocol(KeywordModifiedExprSyntax.self) {
        return isMemberAccessChain(modifiedExpr.expression)
    }
    if let callingExpr = expr.asProtocol(CallingExprSyntax.self) {
        return callingExpr.calledExpression.is(MemberAccessExprSyntax.self)
            || isMemberAccessChain(callingExpr.calledExpression)
    }
    return expr.is(MemberAccessExprSyntax.self)
}

/// Returns whether an expression is a multi-step chain that includes at least one function or
/// subscript call — e.g. `obj.method().prop`, `Type.where({}).fetchOne()`. Pure property chains
/// like `a.b.c` return false because they rarely wrap and don't cause alignment inconsistency.
func isMultiStepCallChain(_ expr: ExprSyntax) -> Bool {
    if let mod = expr.asProtocol(KeywordModifiedExprSyntax.self) {
        return isMultiStepCallChain(mod.expression)
    }
    if let calling = expr.asProtocol(CallingExprSyntax.self) {
        // This node IS a call — count it if the member base is itself a chain.
        if let member = calling.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base { return isMemberAccessChain(base) }
        return isMultiStepCallChain(calling.calledExpression)
    }
    if let member = expr.as(MemberAccessExprSyntax.self), let base = member.base {
        // Pure property access: only qualifies if the base itself is a call chain.
        return isMultiStepCallChain(base)
    }
    return false
}

/// Returns whether a condition element's value expression is a multi-step call chain (2+ steps with
/// at least one function/subscript call). Handles both plain expressions and optional-binding
/// initializers (e.g. `let x = obj.first().second()`).
func conditionContainsMemberChain(_ condition: ConditionElementSyntax) -> Bool {
    switch condition.condition {
        case let .expression(expr): return isMultiStepCallChain(expr)
        case let .optionalBinding(binding):
            if let value = binding.initializer?.value { return isMultiStepCallChain(value) }
            return false
        default: return false
    }
}
