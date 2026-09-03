import SwiftSyntax

/// The statements that run their body more than once
///
/// Three rules ask the same question of a node, in two forms. `LoopBodyVisitor` stops when it
/// reaches one, and `isLoopStatement` tests an ancestor for one. Both forms live in this file so
/// one edit reaches both.
let loopStatementKinds: Set<SyntaxKind> = [.forStmt, .repeatStmt, .whileStmt]

/// Whether a node is a statement that runs its body more than once
func isLoopStatement(_ node: some SyntaxProtocol) -> Bool { loopStatementKinds.contains(node.kind) }

/// A visitor that reads one loop body and stops where that body's own cost ends
///
/// A nested loop reports through its own visit, so descending into one would report it twice. A
/// closure body runs on its own terms, so the loop does not pay for it once per iteration.
///
/// The skip overrides cover `loopStatementKinds`. An override names one node type, so the set
/// cannot drive them. Change the two together.
class LoopBodyVisitor: SyntaxVisitor {
    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: RepeatStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}
