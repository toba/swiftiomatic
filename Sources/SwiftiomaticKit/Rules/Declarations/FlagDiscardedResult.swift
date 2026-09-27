import SwiftSyntax

/// Flag a call site that discards a function result with `_ =`, when the function may need
/// `@discardableResult`.
///
/// A function whose result callers often ignore reads better with `@discardableResult`. The
/// attribute states that the result is optional, and the call sites lose the `_ =` noise. A
/// `mutating` reader such as `nextCharacter()` or `readCommand()` is the common case.
///
/// The rule sees one file at a time, so it reports a discard only with evidence from that file:
///
/// - The file declares the function with a non-`Void` result and without `@discardableResult`.
/// - The call is `self.name(...)`, so the function is a member of the author's own type.
/// - The file discards the result of the bare call `name(...)` two or more times.
///
/// A call on another receiver, a type initializer, and a function that already has
/// `@discardableResult` do not count.
///
/// Lint: A discarded call result that matches one of the shapes above raises a warning.
final class FlagDiscardedResult: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .declarations }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let collector = DiscardCollector(viewMode: .sourceAccurate)
        collector.walk(node)

        let bareCounts = collector.discards.filter { !$0.isSelfCall }
            .reduce(into: [String: Int]()) { $0[$1.name, default: 0] += 1 }

        for discard in collector.discards {
            let report: Bool

            if let declared = collector.declarations[discard.name] {
                report = declared
            } else {
                report = discard.isSelfCall || bareCounts[discard.name, default: 0] >= 2
            }
            if report { diagnose(.flagDiscardedResult(discard.name), on: discard.node) }
        }
        return .skipChildren
    }
}

/// Collects the function declarations and the `_ = name(...)` discards in one file.
private final class DiscardCollector: SyntaxVisitor {
    struct Discard {
        let name: String
        let isSelfCall: Bool
        let node: InfixOperatorExprSyntax
    }

    /// Maps a function name to `true` when every declaration of that name returns a value
    /// without `@discardableResult`.
    var declarations: [String: Bool] = [:]
    var discards: [Discard] = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let candidate = node.returnsValue
            && node.attributes.attribute(named: "discardableResult") == nil
        declarations[name] = (declarations[name] ?? true) && candidate
        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.isAssignmentOperator,
              node.leftOperand.is(DiscardAssignmentExprSyntax.self),
              let call = node.rightOperand.unwrappingTryAwait.as(FunctionCallExprSyntax.self)
        else { return .visitChildren }

        if let reference = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = reference.baseName.text
            guard name.first?.isLowercase == true else { return .visitChildren }
            discards.append(Discard(name: name, isSelfCall: false, node: node))
        } else if let member = call.calledExpression.as(MemberAccessExprSyntax.self),
                  member.base?.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind
                      == .keyword(.self)
        {
            discards.append(
                Discard(name: member.declName.baseName.text, isSelfCall: true, node: node))
        }
        return .visitChildren
    }
}

fileprivate extension ExprSyntax {
    /// The expression without any `try` or `await` layers around it.
    var unwrappingTryAwait: ExprSyntax {
        if let tryExpr = self.as(TryExprSyntax.self) { return tryExpr.expression.unwrappingTryAwait }
        if let awaitExpr = self.as(AwaitExprSyntax.self) {
            return awaitExpr.expression.unwrappingTryAwait
        }
        return self
    }
}

fileprivate extension FunctionDeclSyntax {
    /// Whether the function declares a result type other than `Void` or `()`.
    var returnsValue: Bool {
        guard let type = signature.returnClause?.type else { return false }
        let text = type.trimmedDescription
        return text != "Void" && text != "()" && text != "Never"
    }
}

fileprivate extension Finding.Message {
    static func flagDiscardedResult(_ name: String) -> Finding.Message {
        "the result of '\(name)()' is discarded; mark the function '@discardableResult' if callers often ignore its result"
    }
}
