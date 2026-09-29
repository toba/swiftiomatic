import SwiftSyntax

/// Flag the `.onDrop(of:perform:)` view modifier.
///
/// `.onDrop(of:)` hands the drop an array of `NSItemProvider` values. Each provider carries an
/// untyped payload behind a type identifier string, and the view loads it asynchronously.
/// `.dropDestination(for:)` takes a type that conforms to `Transferable` , so the compiler checks
/// the payload.
///
/// The rule does not flag the `delegate:` form. A `DropDelegate` with `dropUpdated` has no
/// `.dropDestination` equivalent.
///
/// Lint: A modifier call `.onDrop(of:)` has a `perform:` argument or a trailing closure.
final class UseDropDestinationNotOnDrop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil,
              member.declName.baseName.text == "onDrop",
              node.arguments.first?.label?.text == "of",
              !node.arguments.contains(where: { $0.label?.text == "delegate" }),
              node.trailingClosure != nil
                  || node.arguments.contains(where: { $0.label?.text == "perform" })
        else { return .visitChildren }
        diagnose(.onDrop, on: member.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let onDrop: Finding.Message =
        "'.onDrop(of:)' hands the drop an untyped 'NSItemProvider'. Use '.dropDestination(for:)' with a 'Transferable' type"
}
