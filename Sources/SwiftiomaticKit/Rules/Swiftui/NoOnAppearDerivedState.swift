import SwiftSyntax

/// Flag an `.onAppear` that assigns a `@State` property a value derived from another property of
/// the view.
///
/// `.onAppear` runs when the view appears, not when its inputs change. A parent can pass a new
/// value, or a binding can change, while the view stays on screen. The state then keeps the value
/// from the last appearance and goes stale. Compute the value where it is read, for example in a
/// computed property, or keep it current with `.onChange(of: source, initial: true)` .
///
/// `RequireRepeatSafeOnAppear` covers writes that accumulate, such as `count += 1` . This rule does
/// not report an assignment whose value reads only the target itself, or reads no property of the
/// view, such as `isFocused = true` .
///
/// Lint: An assignment in an `.onAppear` closure targets a `@State` property of the view, and its
/// value reads a different stored property of the same view.
final class NoOnAppearDerivedState: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onAppear",
              let action = node.actionClosure(labels: ["perform"]),
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView else { return .visitChildren }
        let finder = AssignmentFinder(viewMode: .sourceAccurate)
        finder.walk(action.statements)

        for write in finder.assignments {
            let root = write.leftOperand.assignmentRoot
            guard root.id == write.leftOperand.id,
                  let target = root.assignmentRootName,
                  entry.isStateProperty(target),
                  !TypeMemberIndex.references(in: root, of: entry).isEmpty,
                  let source = TypeMemberIndex.references(in: write.rightOperand, of: entry)
                      .first(where: { $0.name != target && entry.isStoredInstanceProperty($0.name) }
                      ) else { continue }
            diagnose(.staleDerivedState(target: target, source: source.name), on: write)
        }
        return .visitChildren
    }

    /// The plain `=` assignments of a closure, outside nested closures
    private final class AssignmentFinder: SyntaxVisitor {
        var assignments: [InfixOperatorExprSyntax] = []

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            if node.operator.is(AssignmentExprSyntax.self) { assignments.append(node) }
            return .visitChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    }
}

fileprivate extension Finding.Message {
    static func staleDerivedState(target: String, source: String) -> Finding.Message {
        """
        '.onAppear' derives '\(target)' from '\(source)' once, so '\(target)' goes stale when \
        '\(source)' changes. Compute '\(target)' where it is read, or use \
        '.onChange(of: \(source), initial: true)'
        """
    }
}
