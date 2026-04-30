import SwiftSyntax

/// Lint `dropFirst`/`dropLast`/`prefix`/`suffix` calls inside a loop body.
///
/// On value-typed collections like `Data` and `Array`, these methods copy the
/// underlying storage. Calling them inside a loop produces quadratic cost.
/// Prefer index-based iteration (`var idx = data.startIndex; while idx < end { ... }`)
/// or a single slice computed before the loop.
final class NoDataDropPrefixInLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    private static let copyingSliceMethods: Set<String> = [
        "dropFirst",
        "dropLast",
        "prefix",
        "suffix",
    ]

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        check(loopBody: node.body.statements)
        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        check(loopBody: node.body.statements)
        return .visitChildren
    }

    private func check(loopBody: CodeBlockItemListSyntax) {
        let collector = CopyingSliceCollector(methods: Self.copyingSliceMethods, viewMode: .sourceAccurate)
        collector.walk(loopBody)
        for hit in collector.matches {
            diagnose(.copyingSliceInLoop(hit.method), on: hit.call)
        }
    }
}

private final class CopyingSliceCollector: SyntaxVisitor {
    let methods: Set<String>
    var matches: [(call: FunctionCallExprSyntax, method: String)] = []

    init(methods: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.methods = methods
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           methods.contains(member.declName.baseName.text)
        {
            matches.append((node, member.declName.baseName.text))
        }
        return .visitChildren
    }

    // Don't descend into nested closures or nested loops — the latter are
    // their own scope and reported by their own visit().
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}

extension Finding.Message {
    fileprivate static func copyingSliceInLoop(_ method: String) -> Finding.Message {
        "'.\(method)' inside a loop copies the collection on every iteration — use index advancement or a single slice"
    }
}
