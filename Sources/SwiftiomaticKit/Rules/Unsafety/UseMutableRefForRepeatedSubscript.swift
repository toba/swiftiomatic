import SwiftSyntax

/// Flag a loop body that subscripts the same element repeatedly instead of binding it once.
///
/// Each `xs[i]` on a mutation path is a separate get, mutate and set on the collection, and each
/// one carries an exclusivity check. SE-0519 adds `MutableRef` , which binds the element once and
/// mutates it in place.
///
/// ```swift
/// for i in xs.indices {
///     var element = MutableRef(&xs[i])
///     element.value.a = 0
///     element.value.b = 0
/// }
/// ```
///
/// The rule stays quiet on a read-only loop, where no copy back happens and the repeated subscript
/// costs nothing beyond the bounds check.
///
/// Lint: A `for` body that subscripts one base with the loop variable three or more times, and
/// writes through at least one of them, raises a warning.
final class UseMutableRefForRepeatedSubscript: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    /// Below this count the bind costs more lines than the repeated subscript costs cycles.
    private static let threshold = 3

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        guard let variable = node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return .visitChildren
        }

        let collector = SubscriptCollector(loopVariable: variable)
        collector.walk(node.body)

        guard let (base, uses) = collector.hottestBase(atLeast: Self.threshold) else {
            return .visitChildren
        }

        diagnose(.useMutableRef(base: base, index: variable, count: uses), on: node.forKeyword)
        return .visitChildren
    }
}

/// Counts `<base>[<loopVariable>]` uses per base, and records which bases are written through.
private final class SubscriptCollector: SyntaxVisitor {
    private let loopVariable: String
    private var counts: [String: Int] = [:]
    private var written: Set<String> = []

    init(loopVariable: String) {
        self.loopVariable = loopVariable
        super.init(viewMode: .sourceAccurate)
    }

    /// The base with the most uses, or `nil` when none reaches `minimum` on a write path.
    func hottestBase(atLeast minimum: Int) -> (base: String, uses: Int)? {
        counts
            .filter { written.contains($0.key) && $0.value >= minimum }
            .max { $0.value < $1.value }
            .map { (base: $0.key, uses: $0.value) }
    }

    override func visit(_ node: SubscriptCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let base = simpleBaseName(of: node), indexesLoopVariable(node)
        else { return .visitChildren }

        counts[base, default: 0] += 1
        if isAssignmentTarget(node) { written.insert(base) }
        return .visitChildren
    }

    /// The base identifier, or `nil` when the base is an expression a bind cannot name cheaply.
    private func simpleBaseName(of node: SubscriptCallExprSyntax) -> String? {
        node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
    }

    /// Whether the sole argument is the bare loop variable. A literal or another index names a
    /// different element, so it is not part of the same bind.
    private func indexesLoopVariable(_ node: SubscriptCallExprSyntax) -> Bool {
        guard let only = node.arguments.firstAndOnly, only.label == nil else { return false }
        return only.expression.as(DeclReferenceExprSyntax.self)?.baseName.text == loopVariable
    }

    /// Whether the use sits on the left of an assignment, through any number of member accesses.
    private func isAssignmentTarget(_ node: SubscriptCallExprSyntax) -> Bool {
        var current = Syntax(node)
        // climb the member chain: `xs[i].key.detail` is still a write to `xs[i]`
        while let member = current.parent?.as(MemberAccessExprSyntax.self),
              member.base?.id == current.id
        { current = Syntax(member) }

        guard let infix = current.parent?.as(InfixOperatorExprSyntax.self),
              infix.leftOperand.id == current.id else { return false }

        return isAssignment(infix.operator)
    }

    /// `=` folds to `AssignmentExprSyntax` , while a compound form stays a binary operator token.
    private func isAssignment(_ operatorExpr: ExprSyntax) -> Bool {
        if operatorExpr.is(AssignmentExprSyntax.self) { return true }
        guard let binary = operatorExpr.as(BinaryOperatorExprSyntax.self) else { return false }
        return binary.operator.text.hasSuffix("=") && binary.operator.text != "=="
    }
}

fileprivate extension Finding.Message {
    static func useMutableRef(base: String, index: String, count: Int) -> Finding.Message {
        """
        '\(base)[\(index)]' is subscripted \(count) times in this loop body — bind it once with \
        'MutableRef(&\(base)[\(index)])' (SE-0519) so the element is mutated in place
        """
    }
}
