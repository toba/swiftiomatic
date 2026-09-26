import SwiftSyntax

/// Flag an `.onChange(of:)` whose source is a `@State` of the view and whose action assigns
/// another stored property of the same view.
///
/// The write lands one update after the change it follows. SwiftUI evaluates `body` once with the
/// new source and the old derived value, then again after the action runs. When the view owns both
/// values, it can derive the second one in the same mutation, for example in a `didSet` of a model
/// value, or compute it where it is read.
///
/// The rule only reports a source that the view owns as `@State` . An environment value or a
/// `Binding` from a parent changes outside the view, so `onChange` is the correct reaction to it.
///
/// Lint: An `.onChange(of:)` of a `@State` property assigns a different stored property of the
/// same view type.
final class NoOnChangeDerivedStateWrite: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onChange",
              let source = node.arguments.first(where: { $0.label?.text == "of" })?.expression,
              let sourceName = source.assignmentRootName,
              source.assignmentRoot.id == source.id,
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView,
              entry.isStateProperty(sourceName),
              !TypeMemberIndex.references(in: source, of: entry).isEmpty,
              let action = node.actionClosure(labels: ["action"]) else { return .visitChildren }

        for write in Self.assignments(in: action) {
            let root = write.leftOperand.assignmentRoot
            guard let target = root.assignmentRootName,
                  target != sourceName,
                  entry.isStoredInstanceProperty(target),
                  !TypeMemberIndex.references(in: root, of: entry).isEmpty else { continue }
            diagnose(.derivedWrite(source: sourceName, target: target), on: write)
        }
        return .visitChildren
    }

    private static func assignments(in closure: ClosureExprSyntax) -> [InfixOperatorExprSyntax] {
        let finder = AssignmentFinder(viewMode: .sourceAccurate)
        finder.walk(closure.statements)
        return finder.assignments
    }

    private final class AssignmentFinder: SyntaxVisitor {
        var assignments: [InfixOperatorExprSyntax] = []

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            if node.operator.isAssignmentOperator { assignments.append(node) }
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func derivedWrite(source: String, target: String) -> Finding.Message {
        """
        '.onChange(of: \(source))' writes '\(target)', which makes a second update. Derive \
        '\(target)' from '\(source)' in the same mutation, or compute it where it is read
        """
    }
}
