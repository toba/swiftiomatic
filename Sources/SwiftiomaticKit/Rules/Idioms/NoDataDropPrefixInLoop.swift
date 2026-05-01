import SwiftSyntax

/// Lint `dropFirst` / `dropLast` / `prefix` / `suffix` calls inside a loop body, when the receiver
/// is plausibly the iterated value or a value being shrunk across iterations.
///
/// On value-typed collections like `Data` and `Array` , these methods copy the underlying storage.
/// Calling them inside a loop on the iterated collection (or on a variable that is being whittled
/// down each iteration) produces quadratic cost. Prefer index-based iteration (
/// `var idx = data.startIndex; while idx < end { ... }` ) or a single slice computed before the
/// loop.
///
/// To avoid false positives on unrelated short String / Array slicing inside loops, the rule only
/// fires when the receiver of the slice method is one of:
///
/// - an identifier from the `for-in` sequence expression
/// - a binding introduced by the `for-in` pattern
/// - an identifier from a `while` loop's conditions
/// - an identifier assigned to inside the loop body (typical shrink-in-place pattern)
final class NoDataDropPrefixInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let copyingSliceMethods: Set<String> = [
        "dropFirst",
        "dropLast",
        "prefix",
        "suffix",
    ]

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        var tracked: Set<String> = []
        collectIdentifiers(in: Syntax(node.sequence), into: &tracked)
        collectBindingNames(in: Syntax(node.pattern), into: &tracked)
        collectAssignedIdentifiers(in: node.body.statements, into: &tracked)
        check(loopBody: node.body.statements, tracked: tracked)
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        var tracked: Set<String> = []
        for condition in node.conditions {
            collectIdentifiers(in: Syntax(condition), into: &tracked)
        }
        collectAssignedIdentifiers(in: node.body.statements, into: &tracked)
        check(loopBody: node.body.statements, tracked: tracked)
        return .visitChildren
    }

    private func check(loopBody: CodeBlockItemListSyntax, tracked: Set<String>) {
        guard !tracked.isEmpty else { return }
        let collector = CopyingSliceCollector(
            methods: Self.copyingSliceMethods,
            tracked: tracked,
            viewMode: .sourceAccurate
        )
        collector.walk(loopBody)
        for hit in collector.matches { diagnose(.copyingSliceInLoop(hit.method), on: hit.call) }
    }

    /// Walks `node` collecting every leaf identifier reference (e.g. `arr` from
    /// `arr.dropFirst()` , `data` from `!data.isEmpty` ).
    private func collectIdentifiers(in node: Syntax, into names: inout Set<String>) {
        if let ref = node.as(DeclReferenceExprSyntax.self) {
            names.insert(ref.baseName.text)
        }
        for child in node.children(viewMode: .sourceAccurate) {
            collectIdentifiers(in: child, into: &names)
        }
    }

    /// Collects identifier names introduced by a `for-in` pattern (handles tuple-destructured
    /// bindings like `for (k, v) in pairs` ).
    private func collectBindingNames(in node: Syntax, into names: inout Set<String>) {
        if let identPattern = node.as(IdentifierPatternSyntax.self) {
            names.insert(identPattern.identifier.text)
        }
        for child in node.children(viewMode: .sourceAccurate) {
            collectBindingNames(in: child, into: &names)
        }
    }

    /// Collects identifier names that appear on the left-hand side of a top-level assignment in the
    /// loop body (e.g. `data = data.dropFirst()` adds `data` ).
    private func collectAssignedIdentifiers(
        in statements: CodeBlockItemListSyntax,
        into names: inout Set<String>
    ) {
        let collector = AssignedIdentifierCollector(viewMode: .sourceAccurate)
        collector.walk(statements)
        names.formUnion(collector.names)
    }
}

private final class CopyingSliceCollector: SyntaxVisitor {
    let methods: Set<String>
    let tracked: Set<String>
    var matches: [(call: FunctionCallExprSyntax, method: String)] = []

    init(methods: Set<String>, tracked: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.methods = methods
        self.tracked = tracked
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           methods.contains(member.declName.baseName.text),
           let receiver = leftmostIdentifier(of: member.base),
           tracked.contains(receiver)
        {
            matches.append((node, member.declName.baseName.text))
        }
        return .visitChildren
    }

    /// Returns the leftmost identifier in a chained expression — e.g. `data` from
    /// `data.suffix(8).reversed()` , or `nil` for `self.foo` / function-call bases / nil receivers.
    private func leftmostIdentifier(of expr: ExprSyntax?) -> String? {
        guard let expr else { return nil }
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text }
        if let member = expr.as(MemberAccessExprSyntax.self) {
            return leftmostIdentifier(of: member.base)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return leftmostIdentifier(of: call.calledExpression)
        }
        return nil
    }

    // Don't descend into nested closures or nested loops — the latter are their own scope and
    // reported by their own visit().
    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

/// Collects identifier names that appear as the LHS of a top-level assignment ( `x = ...` ,
/// `x.y = ...` ) inside the visited body. Used to recognise the shrink-in-place pattern
/// ( `data = data.dropFirst()` ) where the iterated value is mutated in the loop body.
private final class AssignedIdentifierCollector: SyntaxVisitor {
    var names: Set<String> = []

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if let op = node.operator.as(AssignmentExprSyntax.self) {
            _ = op
            collectLeftmost(of: node.leftOperand)
        }
        return .visitChildren
    }

    private func collectLeftmost(of expr: ExprSyntax) {
        if let ref = expr.as(DeclReferenceExprSyntax.self) {
            names.insert(ref.baseName.text)
        } else if let member = expr.as(MemberAccessExprSyntax.self), let base = member.base {
            collectLeftmost(of: base)
        }
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension Finding.Message {
    static func copyingSliceInLoop(_ method: String) -> Finding.Message {
        "'.\(method)' inside a loop copies the collection on every iteration — use index advancement or a single slice"
    }
}
