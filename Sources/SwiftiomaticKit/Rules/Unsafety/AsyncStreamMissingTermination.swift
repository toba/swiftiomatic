import SwiftSyntax

/// Lint `AsyncStream { continuation in ... }` (and `AsyncThrowingStream` ) initializer bodies that
/// call `continuation.yield(...)` but never call `continuation.finish(...)` and never set
/// `continuation.onTermination` .
///
/// Without termination handling the stream can leak when the consumer is cancelled — the producer
/// keeps holding resources for a continuation that will never be drained.
final class AsyncStreamMissingTermination: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
              ident.baseName.text == "AsyncStream" || ident.baseName.text == "AsyncThrowingStream"
        else { return .visitChildren }
        let closure: ClosureExprSyntax?

        if let trailing = node.trailingClosure {
            closure = trailing
        } else if let firstClosure = node.arguments.lazy.compactMap({
            $0.expression.as(ClosureExprSyntax.self)
        }).first {
            closure = firstClosure
        } else {
            closure = nil
        }
        guard let closure else { return .visitChildren }

        let scan = ContinuationUsageScanner(viewMode: .sourceAccurate)
        scan.walk(closure.statements)

        if scan.hasYield, !scan.hasFinish, !scan.hasOnTermination {
            diagnose(.missingTermination, on: node.calledExpression)
        }
        return .visitChildren
    }
}

private final class ContinuationUsageScanner: SyntaxVisitor {
    var hasYield = false
    var hasFinish = false
    var hasOnTermination = false

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
            switch member.declName.baseName.text {
                case "yield": hasYield = true
                case "finish": hasFinish = true
                default: break
            }
        }
        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if node.operator.is(AssignmentExprSyntax.self),
           let member = node.leftOperand.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == "onTermination"
        {
            hasOnTermination = true
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let missingTermination: Finding.Message =
        "'AsyncStream' yields without 'finish()' or 'onTermination' — consumer cancellation will leak the producer"
}
