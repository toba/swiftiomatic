import SwiftSyntax

/// Flag an `.onAppear` and an `.onChange(of:)` in one modifier chain that run the same action.
///
/// The pair runs the action once when the view appears and again each time the value changes.
/// `.onChange(of: value, initial: true)` does the same with one modifier, and the reader sees at
/// once that the action tracks the value. Two copies of the action can also drift apart when one of
/// them is edited.
///
/// The actions match when their source text is the same after whitespace is removed. An `.onChange`
/// action that names its old or new value does not match, because `.onAppear` has no such values.
/// An `.onChange` that already passes `initial:` is not reported.
///
/// Lint: An `.onAppear` and an `.onChange(of:)` without `initial:` in the same modifier chain run
/// the same closure or function.
final class UseOnChangeInitialNotOnAppear: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifierName == "onChange",
              let value = node.arguments.first(where: { $0.label?.text == "of" })?.expression,
              !node.arguments.contains(where: { $0.label?.text == "initial" }),
              let action = Self.action(
                  of: node, labels: ["action", "perform"], allowsParameters: true)
        else { return .visitChildren }

        for call in Self.chain(around: node) where call.modifierName == "onAppear" {
            guard let appearAction = Self.action(
                of: call, labels: ["perform"], allowsParameters: false),
                  appearAction == action,
                  let name = call.calledExpression.as(MemberAccessExprSyntax.self)?.declName
            else { continue }
            diagnose(.useInitial(value.trimmedDescription), on: name)
        }
        return .visitChildren
    }

    /// The other modifier calls of the chain that holds `node`
    private static func chain(around node: FunctionCallExprSyntax) -> [FunctionCallExprSyntax] {
        var calls: [FunctionCallExprSyntax] = []
        var current = node

        // down: the receiver of each modifier
        while let base = current.calledExpression.as(MemberAccessExprSyntax.self)?.base,
              let call = base.as(FunctionCallExprSyntax.self)
        {
            calls.append(call)
            current = call
        }
        current = node

        // up: the modifiers applied to the result
        while let member = current.parent?.as(MemberAccessExprSyntax.self),
              member.base?.id == current.id,
              let call = member.parent?.as(FunctionCallExprSyntax.self),
              call.calledExpression.id == member.id
        {
            calls.append(call)
            current = call
        }
        return calls
    }

    /// The action text of a modifier with its whitespace removed, or `nil` when the action reads a
    /// closure parameter
    private static func action(
        of call: FunctionCallExprSyntax,
        labels: Set<String>,
        allowsParameters: Bool
    ) -> String? {
        if let closure = call.actionClosure(labels: labels) {
            if let signature = closure.signature {
                guard allowsParameters, signature.ignoresParameters else { return nil }
            }
            return closure.statements.tokens(viewMode: .sourceAccurate).map(\.text).joined()
        }
        // a function reference such as `perform: reload`
        let argument = call.arguments.first { labels.contains($0.label?.text ?? "") }
            ?? call.arguments.last.flatMap { $0.label == nil ? $0 : nil }
        guard let reference = argument?.expression,
              reference.is(DeclReferenceExprSyntax.self)
                  || reference.is(MemberAccessExprSyntax.self) else { return nil }
        return reference.tokens(viewMode: .sourceAccurate).map(\.text).joined() + "()"
    }
}

private extension ClosureSignatureSyntax {
    /// Whether every closure parameter is `_`
    var ignoresParameters: Bool {
        switch parameterClause {
            case let .simpleInput(list): list.allSatisfy { $0.name.tokenKind == .wildcard }
            case let .parameterClause(clause):
                clause.parameters.allSatisfy {
                    ($0.secondName ?? $0.firstName).tokenKind == .wildcard
                }
            case nil: true
        }
    }
}

fileprivate extension Finding.Message {
    static func useInitial(_ value: String) -> Finding.Message {
        "'.onAppear' and '.onChange(of: \(value))' run the same action. Use '.onChange(of: \(value), initial: true)' and remove '.onAppear'"
    }
}
