import SwiftSyntax

/// Flag a `ForEach` over integer indices whose rows hold state.
///
/// A `ForEach` over `items.indices` or `0..<count` keys each row by its position. After an insert
/// or a remove, the row at a position shows a different element, but SwiftUI keeps the state of the
/// old row at that position. A `@State` or `@FocusState` in the row, or focus bound to the index
/// with `.focused($focus, equals: index)` , then belongs to the wrong element.
///
/// `FlagForEachOverIndices` reports the stateless case, and a `// sm:ignore` directive can accept
/// it where the indices never change. This rule reports the stateful case under its own name, so a
/// directive that names only `flagForEachOverIndices` does not hide it. Only a directive that names
/// this rule, or a bare `// sm:ignore` , suppresses it.
///
/// The rule reads the row type when the same file declares it. For a row type declared in another
/// file, it sees only focus that the closure binds to the index.
///
/// Lint: A `ForEach` over integer indices whose row closure binds focus to the index, or builds a
/// same-file `View` that holds `@State` , `@FocusState` , `@StateObject` or
/// `@AccessibilityFocusState` .
final class FlagStatefulForEachOverIndices: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }
    override class var guidance: GuidanceLevel { .should }

    /// The state that a row keeps across updates
    struct RowState {
        /// The name of the row view
        let row: String
        /// The wrapper that holds the state, such as `@FocusState`
        let wrapper: String
    }

    private static let stateWrappers: Set<String> = [
        "State", "FocusState", "StateObject", "AccessibilityFocusState",
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let receiver = FlagForEachOverIndices.integerIndexedReceiver(of: node),
              let state = Self.rowState(of: node, context: context) else { return .visitChildren }
        diagnose(.statefulRows(state), on: receiver)
        return .visitChildren
    }

    /// The state the rows of `forEach` hold, or `nil` when the rule sees none
    static func rowState(of forEach: FunctionCallExprSyntax, context: Context) -> RowState? {
        guard let closure = forEach.rowContentClosure() else { return nil }
        let parameter = Self.parameterName(of: closure)
        let rowName = closure.statements.first.map { rowName(of: Syntax($0.item)) } ?? "the row"
        let types = context.typeMembers(around: forEach).types
        let finder = CallFinder(viewMode: .sourceAccurate)
        finder.walk(closure.statements)

        for call in finder.calls {
            if call.modifierName == "focused",
               let equals = call.arguments.first(where: { $0.label?.text == "equals" }),
               equals.expression.tokens(viewMode: .sourceAccurate).contains(where: {
                   $0.text == parameter
               }) { return RowState(row: rowName, wrapper: "@FocusState") }

            if let name = call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
               let entry = types[name],
               entry.isView,
               let wrapper = Self.stateWrapper(in: entry) {
                return RowState(row: name, wrapper: "@\(wrapper)")
            }
        }
        return nil
    }

    /// The first state wrapper that a stored property of the type carries
    private static func stateWrapper(in entry: TypeMemberIndex.TypeEntry) -> String? {
        for overloads in entry.members.values {
            for member in overloads where member.kind == .storedProperty {
                if let wrapper = member.declaration.as(VariableDeclSyntax.self)?.attributes
                    .firstAttributeName,
                   stateWrappers.contains(wrapper) { return wrapper }
            }
        }
        return nil
    }

    /// The name of the first closure parameter, or `$0` when the closure declares none
    private static func parameterName(of closure: ClosureExprSyntax) -> String {
        switch closure.signature?.parameterClause {
            case let .simpleInput(list): list.first?.name.text ?? "$0"
            case let .parameterClause(clause):
                clause.parameters.first.map { ($0.secondName ?? $0.firstName).text } ?? "$0"
            case nil: "$0"
        }
    }

    /// The name that starts the modifier chain of a row statement
    private static func rowName(of node: Syntax) -> String {
        var current = node

        while true {
            if let call = current.as(FunctionCallExprSyntax.self) {
                current = Syntax(call.calledExpression)
            } else if let member = current.as(MemberAccessExprSyntax.self), let base = member.base {
                current = Syntax(base)
            } else if let reference = current.as(DeclReferenceExprSyntax.self) {
                return reference.baseName.text
            } else {
                return "the row"
            }
        }
    }

    private final class CallFinder: SyntaxVisitor {
        var calls: [FunctionCallExprSyntax] = []

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            calls.append(node)
            return .visitChildren
        }
    }
}

fileprivate extension Finding.Message {
    static func statefulRows(_ state: FlagStatefulForEachOverIndices.RowState) -> Finding.Message {
        "'ForEach' over indices keys each row by position, and '\(state.row)' holds '\(state.wrapper)'. An insert or a remove moves that state to a different row. Key the rows by a stable 'id'"
    }
}
