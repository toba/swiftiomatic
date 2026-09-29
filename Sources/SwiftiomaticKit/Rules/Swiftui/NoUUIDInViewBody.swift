import SwiftSyntax

/// Flag a `UUID()` call that runs during `body` evaluation, or that builds the data or the `id` of
/// a `ForEach` .
///
/// SwiftUI evaluates `body` again whenever a dependency of the view changes. `UUID()` there makes
/// a new value on each evaluation. When the value is an identity, such as the argument of `.id(_:)`
/// or the `id` of a `ForEach` element, SwiftUI sees a new view each time. It then resets the state
/// of the view and restarts its animations. Store the identifier in the model, or in `@State` .
///
/// The rule checks `body` , and the same-file computed properties and called methods that `body`
/// reaches. Closures that run later, such as a `Button` action or a `.task` body, do not count.
/// The rule also checks the data argument and the `id:` argument of each `ForEach` call, in any
/// scope.
///
/// Lint: A `UUID()` call with no arguments runs during `body` evaluation of a `View` , or is inside
/// the data argument or the `id:` argument of a `ForEach` .
final class NoUUIDInViewBody: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    /// The calls this rule already reported, so a call in both scopes gives one finding
    private var reported: Set<SyntaxIdentifier> = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for call in context.callsDuringViewBody(of: node) where Self.isNewUUID(call) {
            report(call)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        for call in context.callsDuringViewBody(of: node) where Self.isNewUUID(call) {
            report(call)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.constructedTypeName == "ForEach" else { return .visitChildren }

        for (index, argument) in node.arguments.enumerated()
        where (index == 0 && argument.label == nil) || argument.label?.text == "id" {
            let finder = UUIDFinder()
            finder.walk(argument.expression)
            for call in finder.calls { report(call) }
        }
        return .visitChildren
    }

    private func report(_ call: FunctionCallExprSyntax) {
        guard reported.insert(call.id).inserted else { return }
        diagnose(.newIdentity, on: call)
    }

    /// Whether `call` is `UUID()` with no arguments and no trailing closure
    fileprivate static func isNewUUID(_ call: FunctionCallExprSyntax) -> Bool {
        call.constructedTypeName == "UUID" && call.arguments.isEmpty && call.trailingClosure == nil
    }

    private final class UUIDFinder: SyntaxVisitor {
        var calls: [FunctionCallExprSyntax] = []

        init() { super.init(viewMode: .sourceAccurate) }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if NoUUIDInViewBody.isNewUUID(node) { calls.append(node) }
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static let newIdentity: Finding.Message =
        "'UUID()' makes a new identity on each 'body' evaluation, which resets state and animations. Store the identifier in the model"
}
