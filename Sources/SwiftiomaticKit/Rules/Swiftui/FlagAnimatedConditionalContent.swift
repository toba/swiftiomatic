import SwiftSyntax

/// Flag an `.animation(_:value:)` whose view holds an `if` or `switch` and no geometry group.
///
/// SwiftUI passes a change of position or size down the view tree, and each leaf view animates its
/// own frame. When the content of the animated view also changes, because a branch of an `if` or a
/// `switch` appears or goes away, its parts can animate as separate pieces. A component can then
/// come apart during the animation, for example a label whose text and background move apart.
///
/// When the parts must move as one unit, put `geometryGroup()` around the complete unit. The parent
/// then resolves the position and size of the group first, and the parts follow it:
///
/// ```swift
/// StatusLabel(isDone: isDone)
///     .geometryGroup()
///     .frame(maxWidth: .infinity, alignment: isDone ? .trailing : .leading)
/// ```
///
/// The place in the modifier chain matters, because it decides which views are inside the group.
/// `geometryGroup()` does not flatten the drawing, and it does not make the view faster. When the
/// parts may animate on their own, keep the code and suppress the finding. The finding asks for a
/// review, not a fixed change.
///
/// The rule looks at the view that the modifier chain before `.animation(_:value:)` builds,
/// including the closures of its modifiers, such as an `overlay` .
///
/// Lint: An `.animation(_:value:)` modifier follows a view that holds an `if` or `switch` and no
/// `geometryGroup()` .
final class FlagAnimatedConditionalContent: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let access = node.calledExpression.as(MemberAccessExprSyntax.self),
            access.declName.baseName.text == "animation",
            let base = access.base,
            node.arguments.contains(where: { $0.label?.text == "value" })
        else { return .visitChildren }
        let scan = ContentScanner(viewMode: .sourceAccurate)
        scan.walk(base)

        if scan.hasBranch, !scan.hasGeometryGroup { diagnose(.animatedBranch, on: access.declName) }
        return .visitChildren
    }

    /// Finds a branch and a `geometryGroup()` call in the animated view
    private final class ContentScanner: SyntaxVisitor {
        var hasBranch = false
        var hasGeometryGroup = false

        override func visit(_: IfExprSyntax) -> SyntaxVisitorContinueKind {
            hasBranch = true
            return .visitChildren
        }

        override func visit(_: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
            hasBranch = true
            return .visitChildren
        }

        override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
            if node.declName.baseName.text == "geometryGroup" { hasGeometryGroup = true }
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static let animatedBranch: Finding.Message = """
        '.animation(_:value:)' animates content that holds an 'if' or 'switch', so the changing \
        parts can animate as separate pieces. When the parts must move as one unit, add \
        'geometryGroup()' around them
        """
}
