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
/// The rule also reports the declaration of the source and the declaration of the target. The fix
/// often changes those declarations, for example when the target becomes a computed property.
/// Each declaration gets one finding, also when more than one write links it.
///
/// Lint: An `.onChange(of:)` of a `@State` property assigns a different stored property of the
/// same view type. The write, the source declaration, and the target declaration each get a
/// warning.
final class NoOnChangeDerivedStateWrite: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    /// The declarations that already have a finding in this file.
    private var reportedDeclarations: Set<SyntaxIdentifier> = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onChange",
              let source = node.arguments.first(where: { $0.label?.text == "of" })?.expression,
              let sourceName = source.selfMemberReference?.baseName.text,
              let entry = context.typeMembers(around: node).enclosingType(of: node),
              entry.isView,
              entry.isStateProperty(sourceName),
              !TypeMemberIndex.references(in: source, of: entry).isEmpty,
              let action = node.actionClosure(labels: ["action"]) else { return .visitChildren }

        let writes = InfixOperatorExprSyntax.assignments(
            in: action, compound: true, enteringClosures: true)

        for write in writes {
            let root = write.leftOperand.assignmentRoot
            guard let target = root.assignmentRootName,
                  target != sourceName,
                  entry.isStoredInstanceProperty(target),
                  !TypeMemberIndex.references(in: root, of: entry).isEmpty else { continue }
            diagnose(.derivedWrite(source: sourceName, target: target), on: write)
            diagnoseDeclaration(
                of: target, in: entry, near: node,
                message: .derivedTarget(source: sourceName, target: target))
            diagnoseDeclaration(
                of: sourceName, in: entry, near: node,
                message: .derivedSource(source: sourceName, target: target))
        }
        return .visitChildren
    }

    /// Reports the stored declaration of `name` once, when it is in the same file as `node`.
    private func diagnoseDeclaration(
        of name: String,
        in entry: TypeMemberIndex.TypeEntry,
        near node: some SyntaxProtocol,
        message: Finding.Message
    ) {
        guard let declaration = entry.members[name]?
            .first(where: { $0.kind == .storedProperty && !$0.isStatic })?.declaration,
              declaration.root.id == node.root.id,
              reportedDeclarations.insert(declaration.id).inserted else { return }
        diagnose(message, on: declaration)
    }
}

fileprivate extension Finding.Message {
    static func derivedWrite(source: String, target: String) -> Finding.Message {
        """
        '.onChange(of: \(source))' writes '\(target)', which makes a second update. Derive \
        '\(target)' from '\(source)' in the same mutation, or compute it where it is read
        """
    }

    static func derivedSource(source: String, target: String) -> Finding.Message {
        """
        '\(source)' drives a write to '\(target)' in '.onChange'. Update '\(target)' in the \
        code that changes '\(source)'
        """
    }

    static func derivedTarget(source: String, target: String) -> Finding.Message {
        """
        '\(target)' is set in '.onChange(of: \(source))'. Derive it from '\(source)', or set it \
        in the code that changes '\(source)'
        """
    }
}
