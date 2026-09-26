import SwiftSyntax

/// Flag a `withAnimation` call directly inside the action closure of `.onChange(of:)` .
///
/// The action runs in the same update as the change that triggers it. Other state changes in that
/// update can carry a transaction without an animation. That transaction can override the animation
/// that `withAnimation` sets, so the view changes without animation.
///
/// The fix is `.animation(_:value:)` on the view that animates. The modifier ties the animation to
/// the value, and it applies only to that view.
///
/// The rule reports only a `withAnimation` call that is a statement of the action closure itself. A
/// call inside a nested closure, such as a `Task` , runs later in its own update.
///
/// Lint: A `withAnimation` call is a top-level statement of an `.onChange(of:)` action closure.
final class NoWithAnimationInOnChange: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onChange",
              node.arguments.contains(where: { $0.label?.text == "of" }),
              let action = node.actionClosure(labels: ["action"]) else { return .visitChildren }

        let note = Finding.Note(
            message: .onChangeClosure,
            location: Finding.Location(action.startLocation(
                converter: context.sourceLocationConverter)),
            role: .closure
        )

        for statement in action.statements {
            guard case let .expr(expression) = statement.item,
                  let call = expression.as(FunctionCallExprSyntax.self),
                  call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName
                      .text
                      == "withAnimation" else { continue }
            diagnose(.withAnimationInOnChange, on: call, notes: [note])
        }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static let withAnimationInOnChange: Finding.Message = """
        'withAnimation' inside '.onChange(of:)' can lose to a non-animated transaction in the same \
        update. Put '.animation(_:value:)' on the view that animates
        """

    static let onChangeClosure: Finding.Message = "the '.onChange(of:)' action closure starts here"
}
