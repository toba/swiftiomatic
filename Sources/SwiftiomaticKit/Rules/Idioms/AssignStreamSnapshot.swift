import SwiftSyntax

/// Flag code that appends a `streamResponse` snapshot instead of assigning it.
///
/// `LanguageModelSession.streamResponse(to:)` yields snapshots. Each snapshot holds the whole
/// response so far, not only the new part. A loop that appends each snapshot to the previous
/// text repeats the response many times. Assign the snapshot to the output on each iteration.
///
/// The rule reads the body of `for try await s in <x>.streamResponse(...)`. It reports a `+=`
/// whose right side reads `s`, and an `append` call whose arguments read `s`. A read of a member
/// that has the same name as `s`, such as `state.s`, does not count.
///
/// Lint: A `streamResponse` loop appends its snapshot to an accumulated value.
final class AssignStreamSnapshot: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .mustNot }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.operator.as(BinaryOperatorExprSyntax.self)?.operator.text == "+=",
              let snapshot = Self.snapshotName(readBy: node.rightOperand, around: node)
        else { return .visitChildren }
        diagnose(.assignSnapshot(snapshot), on: node)
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let name: String? =
            if let member = node.calledExpression.as(MemberAccessExprSyntax.self) {
                member.declName.baseName.text
            } else {
                node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
            }
        guard name == "append",
              let snapshot = Self.snapshotName(readBy: node.arguments, around: node)
        else { return .visitChildren }
        diagnose(.assignSnapshot(snapshot), on: node)
        return .visitChildren
    }

    /// The name of the snapshot of an enclosing `streamResponse` loop that `operand` reads, or
    /// `nil` when `node` is in no such loop or `operand` reads no snapshot
    private static func snapshotName(
        readBy operand: some SyntaxProtocol,
        around node: some SyntaxProtocol
    ) -> String? {
        var child = Syntax(node)
        var current = node.parent

        while let ancestor = current {
            if let loop = ancestor.as(ForStmtSyntax.self), loop.body.id == child.id,
               let name = streamSnapshotName(of: loop), reads(name, in: operand)
            {
                return name
            }
            if ancestor.is(FunctionDeclSyntax.self) || ancestor.is(InitializerDeclSyntax.self)
                || ancestor.is(AccessorDeclSyntax.self) || ancestor.is(MemberBlockSyntax.self)
            {
                return nil
            }
            child = ancestor
            current = ancestor.parent
        }
        return nil
    }

    /// The name that `loop` binds, when `loop` is `for try await s in <x>.streamResponse(...)`
    private static func streamSnapshotName(of loop: ForStmtSyntax) -> String? {
        guard loop.awaitKeyword != nil,
              let pattern = loop.pattern.as(IdentifierPatternSyntax.self),
              let call = loop.sequence.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.declName.baseName.text == "streamResponse" else { return nil }
        return pattern.identifier.text
    }

    /// Whether `syntax` reads the local `name`, not a member of the same name
    private static func reads(_ name: String, in syntax: some SyntaxProtocol) -> Bool {
        syntax.tokens(viewMode: .sourceAccurate).contains { token in
            guard token.tokenKind == .identifier(name),
                  let reference = token.parent?.as(DeclReferenceExprSyntax.self) else {
                return false
            }
            guard let member = reference.parent?.as(MemberAccessExprSyntax.self) else {
                return true
            }
            return member.declName.id != reference.id
        }
    }
}

fileprivate extension Finding.Message {
    static func assignSnapshot(_ name: String) -> Finding.Message {
        "'streamResponse' yields cumulative snapshots; assign '\(name)' instead of appending it"
    }
}
