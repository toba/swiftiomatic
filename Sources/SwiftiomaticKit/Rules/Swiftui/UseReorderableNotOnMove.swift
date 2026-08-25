import SwiftSyntax

/// Flag `onMove(perform:)` outside a `List` or a `Form` .
///
/// Before OS 27, `onMove` only worked inside those two containers, so reordering anywhere else
/// meant hand-rolling it on `draggable` and `dropDestination` with index arithmetic. OS 27 adds
/// `ForEach.reorderable()` paired with `View.reorderContainer(for:move:)` , which works in any
/// container and hands back a `ReorderDifference` to apply.
///
/// Inside a `List` or a `Form` , `onMove` is still the right call. The rule walks up the ancestors
/// and stays quiet when it finds one.
///
/// Lint: An `onMove` call with no `List` or `Form` ancestor raises a warning.
final class UseReorderableNotOnMove: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// Containers that already handle `onMove` .
    private static let reorderingContainers: Set<String> = ["List", "Form"]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.base != nil,
            member.declName.baseName.text == "onMove",
            !node.hasReorderingContainerAncestor(named: Self.reorderingContainers)
        else { return .visitChildren }

        diagnose(.useReorderable, on: member.declName)
        return .visitChildren
    }
}

fileprivate extension FunctionCallExprSyntax {
    /// Whether any enclosing call names one of `names` .
    ///
    /// Matches `List { … }` and `List(selection:) { … }` alike, because both put the container name
    /// in the called expression.
    func hasReorderingContainerAncestor(named names: Set<String>) -> Bool {
        var current = Syntax(self).parent

        while let node = current {
            if let call = node.as(FunctionCallExprSyntax.self),
               let name = call.containerName,
               names.contains(name) { return true }
            current = node.parent
        }
        return false
    }

    /// The name of the called expression.
    ///
    /// Reads a member access too, so a module-qualified `SwiftUI.List` matches the bare `List` .
    var containerName: String? {
        if let reference = calledExpression.as(DeclReferenceExprSyntax.self) {
            return reference.baseName.text
        }
        return calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }
}

fileprivate extension Finding.Message {
    static let useReorderable: Finding.Message =
        "'onMove' only reorders inside a 'List' or a 'Form' — use '.reorderable()' with '.reorderContainer(for:move:)', which works in any container"
}
