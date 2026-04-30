import SwiftSyntax

/// Lint mutation of the loop subject inside a `for-in` loop. Mutating the
/// iterated collection while the iterator is live is undefined behavior in
/// Swift's `Sequence` model and a frequent source of crashes for `Array`.
///
/// Detection: the loop subject must be either a `DeclReferenceExprSyntax`
/// (e.g. `for x in items`) or a `MemberAccessExprSyntax` (e.g.
/// `for x in self.items`). Inside the body, any call of the form
/// `<subject>.<mutator>(...)` where `<mutator>` is a known Array/Dictionary/
/// Set mutating method is flagged.
final class NoMutationOfIteratedCollection: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    private static let mutatingMethods: Set<String> = [
        "append",
        "insert",
        "remove",
        "removeAll",
        "removeFirst",
        "removeLast",
        "removeSubrange",
        "popLast",
        "popFirst",
        "swapAt",
        "reverse",
        "sort",
        "shuffle",
        "replaceSubrange",
    ]

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        let subject = node.sequence
        let collector = MutationCollector(
            subject: subject.trimmedDescription,
            mutators: Self.mutatingMethods,
            viewMode: .sourceAccurate
        )
        collector.walk(node.body.statements)
        for hit in collector.matches {
            diagnose(.mutatingIteratedCollection(hit.method), on: hit.call)
        }
        return .visitChildren
    }
}

private final class MutationCollector: SyntaxVisitor {
    let subject: String
    let mutators: Set<String>
    var matches: [(call: FunctionCallExprSyntax, method: String)] = []

    init(subject: String, mutators: Set<String>, viewMode: SyntaxTreeViewMode) {
        self.subject = subject
        self.mutators = mutators
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              let base = member.base
        else {
            return .visitChildren
        }
        let name = member.declName.baseName.text
        if mutators.contains(name), base.trimmedDescription == subject {
            matches.append((node, name))
        }
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static func mutatingIteratedCollection(_ method: String) -> Finding.Message {
        "'\(method)' mutates the collection currently being iterated — undefined behavior"
    }
}
