import SwiftSyntax

/// Run the passes of a loop at once in a task group when they do not depend on each other.
///
/// A loop in async code that awaits in its body waits for each pass to end before the next one
/// starts. When a pass does not use what an earlier pass produced, a task group can run every pass
/// at once and collect the results as they arrive.
///
/// A `for await` loop is exempt, because its passes come from the sequence one at a time. A loop
/// that assigns an awaited value to a variable is exempt, because the next pass can read that
/// value. A loop that returns, breaks or throws is exempt, because the order of its passes
/// decides where it stops. A `while` or `repeat` loop is exempt, because its body must change what
/// its condition reads, so each pass depends on the one before it.
///
/// Lint: A `for` loop in async code awaits in its body and passes nothing from one pass to the
/// next.
final class UseTaskGroupForIndependentIterations: LintSyntaxRule<LintOnlyValue>,
    @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .controlFlow }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.awaitKeyword == nil { check(node) }
        return .visitChildren
    }

    private func check(_ loop: ForStmtSyntax) {
        guard loop.body.statements.awaitsDirectly, loop.isInAsyncContext else { return }
        let scan = DependencyScanner(viewMode: .sourceAccurate)
        scan.walk(loop.body.statements)
        guard !scan.dependsOnOrder else { return }
        diagnose(.useTaskGroup, on: loop)
    }

    /// Finds an exit or an awaited assignment outside any nested closure or function
    private final class DependencyScanner: DirectScopeVisitor {
        var dependsOnOrder = false

        override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
            dependsOnOrder = true
            return .skipChildren
        }

        override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
            dependsOnOrder = true
            return .skipChildren
        }

        override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
            dependsOnOrder = true
            return .skipChildren
        }

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            if node.operator.is(AssignmentExprSyntax.self), node.rightOperand.awaitsDirectly {
                dependsOnOrder = true
            }
            return .visitChildren
        }

        override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
            // The linter can see an unfolded sequence.
            if node.elements.contains(where: { $0.is(AssignmentExprSyntax.self) }),
               node.awaitsDirectly {
                dependsOnOrder = true
            }
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static let useTaskGroup: Finding.Message = """
        each pass of this 'for' loop awaits work that does not depend on an earlier pass. \
        Run the passes at once in a task group
        """
}
